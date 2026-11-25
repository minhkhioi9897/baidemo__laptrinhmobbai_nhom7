import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journal_model.dart';
import 'auth_service.dart';

class JournalService {
  static final JournalService _instance = JournalService._internal();
  factory JournalService() => _instance;
  JournalService._internal();

  static const String _journalBaseKey = 'user_journals';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  SharedPreferences? _prefs;
  final List<JournalModel> _journals = [];

  StreamSubscription? _journalCloudSubscription;

  List<JournalModel> get journals => List.unmodifiable(_journals);

  String get _currentEmail {
    final email = AuthService().currentUserEmail;
    return (email != null && email.isNotEmpty) ? email.toLowerCase().trim() : 'guest';
  }

  String get _userJournalKey => '${_journalBaseKey}_$_currentEmail';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await loadUserJournals();
  }

  /// Reload journals specifically for the currently logged-in user email
  Future<void> loadUserJournals() async {
    _journalCloudSubscription?.cancel();
    _journals.clear();

    final String? jsonStr = _prefs?.getString(_userJournalKey);

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        for (final item in decoded) {
          _journals
              .add(JournalModel.fromJson(Map<String, dynamic>.from(item)));
        }
      } catch (_) {}
    }

    _syncWithFirebase();
  }

  void _syncWithFirebase() {
    final normalizedEmail = _currentEmail;
    if (normalizedEmail == 'guest') return;

    _journalCloudSubscription?.cancel();
    try {
      _journalCloudSubscription = _firestore
          .collection('users')
          .doc(normalizedEmail)
          .collection('journals')
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final List<JournalModel> cloudJournals = [];
          for (final doc in snapshot.docs) {
            try {
              cloudJournals.add(JournalModel.fromJson(doc.data()));
            } catch (_) {}
          }
          if (cloudJournals.isNotEmpty) {
            _mergeCloudJournals(cloudJournals);
          }
        }
      });
    } catch (e) {
      debugPrint('Lỗi kết nối đồng bộ Nhật ký Firebase: $e');
    }
  }

  void _mergeCloudJournals(List<JournalModel> cloudJournals) {
    bool hasChanges = false;
    for (final cj in cloudJournals) {
      final index = _journals.indexWhere((j) => j.id == cj.id);
      if (index == -1) {
        _journals.add(cj);
        hasChanges = true;
      } else {
        if (_journals[index].createdAt.isBefore(cj.createdAt)) {
          _journals[index] = cj;
          hasChanges = true;
        }
      }
    }
    if (hasChanges) {
      _journals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _saveJournals();
    }
  }

  Future<void> _pushToFirebase(JournalModel journal) async {
    final normalizedEmail = _currentEmail;
    if (normalizedEmail == 'guest') return;

    final sanitizedEmailKey = normalizedEmail.replaceAll('.', '_').replaceAll('@', '_at_');

    // 1. Sync to Realtime Database
    try {
      unawaited(_rtdb.ref('users/$sanitizedEmailKey/journals/${journal.id}').set(journal.toJson()).timeout(const Duration(seconds: 4), onTimeout: () {}));
    } catch (_) {}

    // 2. Sync to Firestore
    try {
      unawaited(_firestore
          .collection('users')
          .doc(normalizedEmail)
          .collection('journals')
          .doc(journal.id)
          .set(journal.toJson(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 4), onTimeout: () {}));
    } catch (_) {}
  }

  Future<void> _deleteFromFirebase(String journalId) async {
    final normalizedEmail = _currentEmail;
    if (normalizedEmail == 'guest') return;

    final sanitizedEmailKey = normalizedEmail.replaceAll('.', '_').replaceAll('@', '_at_');

    try {
      unawaited(_rtdb.ref('users/$sanitizedEmailKey/journals/$journalId').remove().timeout(const Duration(seconds: 3), onTimeout: () {}));
      unawaited(_firestore.collection('users').doc(normalizedEmail).collection('journals').doc(journalId).delete().timeout(const Duration(seconds: 3), onTimeout: () {}));
    } catch (_) {}
  }

  Future<void> addJournal(JournalModel journal) async {
    _journals.insert(0, journal);
    await _saveJournals();
    _pushToFirebase(journal);
  }

  Future<void> updateJournal(JournalModel journal) async {
    final index = _journals.indexWhere((j) => j.id == journal.id);
    if (index != -1) {
      _journals[index] = journal;
      final updated = _journals.removeAt(index);
      _journals.insert(0, updated);
      await _saveJournals();
      _pushToFirebase(updated);
    }
  }

  Future<void> deleteJournal(String id) async {
    _journals.removeWhere((j) => j.id == id);
    await _saveJournals();
    _deleteFromFirebase(id);
  }

  Future<void> clearAllJournals() async {
    _journals.clear();
    await _prefs?.remove(_userJournalKey);
  }

  Future<void> _saveJournals() async {
    final jsonList = _journals.map((j) => j.toJson()).toList();
    await _prefs?.setString(_userJournalKey, jsonEncode(jsonList));
  }
}
