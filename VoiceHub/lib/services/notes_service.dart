import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';
import 'auth_service.dart';

class NotesService {
  static final NotesService _instance = NotesService._internal();
  factory NotesService() => _instance;
  NotesService._internal();

  static const String _notesBaseKey = 'user_notes';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  SharedPreferences? _prefs;
  final List<NoteModel> _notes = [];

  StreamSubscription? _notesCloudSubscription;

  List<NoteModel> get notes => List.unmodifiable(_notes);

  String get _currentEmail {
    final email = AuthService().currentUserEmail;
    return (email != null && email.isNotEmpty) ? email.toLowerCase().trim() : 'guest';
  }

  String get _userNotesKey => '${_notesBaseKey}_$_currentEmail';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await loadUserNotes();
  }

  /// Reload notes specifically for the currently logged-in user email
  Future<void> loadUserNotes() async {
    _notesCloudSubscription?.cancel();
    _notes.clear();

    final String? notesJson = _prefs?.getString(_userNotesKey);

    if (notesJson != null && notesJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(notesJson);
        for (final item in decoded) {
          _notes.add(NoteModel.fromJson(Map<String, dynamic>.from(item)));
        }
      } catch (_) {}
    }

    // Automatically remove initial seed sample notes if present
    final initialCount = _notes.length;
    _notes.removeWhere((n) => n.id == '1' || n.id == '2' || n.id == '3');
    if (_notes.length != initialCount) {
      await _saveNotes();
    }

    // Connect real-time synchronization with Firebase for this user
    _syncWithFirebase();
  }

  void _syncWithFirebase() {
    final normalizedEmail = _currentEmail;
    if (normalizedEmail == 'guest') return;

    _notesCloudSubscription?.cancel();
    try {
      _notesCloudSubscription = _firestore
          .collection('users')
          .doc(normalizedEmail)
          .collection('notes')
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final List<NoteModel> cloudNotes = [];
          for (final doc in snapshot.docs) {
            try {
              cloudNotes.add(NoteModel.fromJson(doc.data()));
            } catch (_) {}
          }
          if (cloudNotes.isNotEmpty) {
            _mergeCloudNotes(cloudNotes);
          }
        }
      });
    } catch (e) {
      debugPrint('Lỗi kết nối đồng bộ Ghi chú Firebase: $e');
    }
  }

  void _mergeCloudNotes(List<NoteModel> cloudNotes) {
    bool hasChanges = false;
    for (final cn in cloudNotes) {
      final index = _notes.indexWhere((n) => n.id == cn.id);
      if (index == -1) {
        _notes.add(cn);
        hasChanges = true;
      } else {
        if (_notes[index].updatedAt.isBefore(cn.updatedAt)) {
          _notes[index] = cn;
          hasChanges = true;
        }
      }
    }
    if (hasChanges) {
      _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _saveNotes();
    }
  }

  Future<void> _pushToFirebase(NoteModel note) async {
    final normalizedEmail = _currentEmail;
    if (normalizedEmail == 'guest') return;

    final sanitizedEmailKey = normalizedEmail.replaceAll('.', '_').replaceAll('@', '_at_');

    // 1. Sync to Firebase Realtime Database
    try {
      unawaited(_rtdb.ref('users/$sanitizedEmailKey/notes/${note.id}').set(note.toJson()).timeout(const Duration(seconds: 4), onTimeout: () {}));
    } catch (_) {}

    // 2. Sync to Firestore
    try {
      unawaited(_firestore
          .collection('users')
          .doc(normalizedEmail)
          .collection('notes')
          .doc(note.id)
          .set(note.toJson(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 4), onTimeout: () {}));
    } catch (_) {}
  }

  Future<void> _deleteFromFirebase(String noteId) async {
    final normalizedEmail = _currentEmail;
    if (normalizedEmail == 'guest') return;

    final sanitizedEmailKey = normalizedEmail.replaceAll('.', '_').replaceAll('@', '_at_');

    try {
      unawaited(_rtdb.ref('users/$sanitizedEmailKey/notes/$noteId').remove().timeout(const Duration(seconds: 3), onTimeout: () {}));
      unawaited(_firestore.collection('users').doc(normalizedEmail).collection('notes').doc(noteId).delete().timeout(const Duration(seconds: 3), onTimeout: () {}));
    } catch (_) {}
  }

  Future<void> clearAllNotes() async {
    _notes.clear();
    await _prefs?.remove(_userNotesKey);
  }

  Future<void> addNote(NoteModel note) async {
    _notes.insert(0, note);
    await _saveNotes();
    _pushToFirebase(note);
  }

  Future<void> updateNote(NoteModel note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
      final updated = _notes.removeAt(index);
      _notes.insert(0, updated);
      await _saveNotes();
      _pushToFirebase(updated);
    }
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _saveNotes();
    _deleteFromFirebase(id);
  }

  Future<void> _saveNotes() async {
    final jsonList = _notes.map((n) => n.toJson()).toList();
    await _prefs?.setString(_userNotesKey, jsonEncode(jsonList));
  }
}
