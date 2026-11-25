import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechRecorderService {
  static final SpeechRecorderService _instance = SpeechRecorderService._internal();
  factory SpeechRecorderService() => _instance;
  SpeechRecorderService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;

  Future<void> init() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (val) => debugPrint('Speech recorder error: $val'),
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            _isListening = false;
          }
        },
      );
    } catch (e) {
      debugPrint('Speech recorder init failed: $e');
      _isAvailable = false;
    }
  }

  Future<void> startListening({
    required Function(String text) onResult,
    required VoidCallback onDone,
  }) async {
    if (!_isAvailable) {
      await init();
    }

    if (_isAvailable) {
      _isListening = true;
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
          if (result.finalResult) {
            _isListening = false;
            onDone();
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: 'vi_VN',
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } else {
      _isListening = false;
      onDone();
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
    _isListening = false;
  }
}
