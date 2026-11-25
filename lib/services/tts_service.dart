import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> init() async {}

  Future<void> speak(String text) async {
    debugPrint('Native Speech Playback: $text');
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }
}
