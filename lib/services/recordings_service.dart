import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recording_model.dart';

class RecordingsService {
  static final RecordingsService _instance = RecordingsService._internal();
  factory RecordingsService() => _instance;
  RecordingsService._internal();

  static const String _recordingsKey = 'user_recordings';
  SharedPreferences? _prefs;
  final List<RecordingModel> _recordings = [];

  List<RecordingModel> get recordings => List.unmodifiable(_recordings);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final String? jsonStr = _prefs?.getString(_recordingsKey);

    _recordings.clear();
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        for (final item in decoded) {
          _recordings
              .add(RecordingModel.fromJson(Map<String, dynamic>.from(item)));
        }
      } catch (_) {}
    }
  }

  Future<void> addRecording(RecordingModel recording) async {
    _recordings.insert(0, recording);
    await _saveRecordings();
  }

  Future<void> deleteRecording(String id) async {
    _recordings.removeWhere((r) => r.id == id);
    await _saveRecordings();
  }

  Future<void> clearAllRecordings() async {
    _recordings.clear();
    await _prefs?.remove(_recordingsKey);
  }

  Future<void> _saveRecordings() async {
    final jsonList = _recordings.map((r) => r.toJson()).toList();
    await _prefs?.setString(_recordingsKey, jsonEncode(jsonList));
  }
}
