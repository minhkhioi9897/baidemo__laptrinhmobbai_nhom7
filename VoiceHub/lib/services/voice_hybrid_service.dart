import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:just_audio/just_audio.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum VoiceMode { recording, calculator, note, journal }

class VoiceHybridResult {
  final String transcript;
  final String title;
  final String expression;
  final String result;
  final List<String> bullets;
  final String mood;
  final String emoji;
  final String audioPath;
  final bool isOnline;

  VoiceHybridResult({
    this.transcript = '',
    this.title = '',
    this.expression = '',
    this.result = '',
    this.bullets = const [],
    this.mood = 'Bình thường',
    this.emoji = '😊',
    this.audioPath = '',
    this.isOnline = false,
  });
}

class VoiceHybridService {
  static final VoiceHybridService _instance = VoiceHybridService._internal();
  factory VoiceHybridService() => _instance;
  VoiceHybridService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final stt.SpeechToText _speech = stt.SpeechToText();

  GenerativeModel? _geminiModel;

  bool _isRecordingReal = false;
  bool _isSpeechListening = false;
  String _currentAudioPath = '';

  // Thêm Gemini API Key khi sử dụng Online
  void initGemini(String apiKey) {
    if (apiKey.isNotEmpty) {
      _geminiModel = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    }
  }

  /// 1. KIỂM TRA KẾT NỐI MẠNG (ONLINE / OFFLINE)
  Future<bool> checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  /// 2. TẮT TẤT CẢ PHIÊN LÀM VIỆC CỦA MICRO TRÁNH XUNG ĐỘT PHẦN CỨNG
  Future<void> releaseMicrophone() async {
    if (_isSpeechListening) {
      await _speech.stop();
      _isSpeechListening = false;
    }
    if (_isRecordingReal) {
      await _recorder.stop();
      _isRecordingReal = false;
    }
  }

  /// 3. BẮT ĐẦU GHI ÂM GIỌNG THẬT RA FILE .M4A (Bằng record)
  Future<bool> startRealRecording() async {
    await releaseMicrophone();

    if (await _recorder.hasPermission()) {
      final Directory dir = await getApplicationDocumentsDirectory();
      _currentAudioPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: _currentAudioPath,
      );
      _isRecordingReal = true;
      return true;
    }
    return false;
  }

  /// DỪNG GHI ÂM GIỌNG THẬT (Trả về đường dẫn file .m4a)
  Future<String> stopRealRecording() async {
    if (_isRecordingReal) {
      final path = await _recorder.stop();
      _isRecordingReal = false;
      if (path != null && path.isNotEmpty) {
        _currentAudioPath = path;
      }
    }
    return _currentAudioPath;
  }

  /// 4. PHÁT LẠI ÂM THANH GIỌNG THẬT GỐC (.m4a) BẰNG JUST_AUDIO (Không nén/TTS)
  Future<void> playAudioPath(String path) async {
    if (path.isEmpty || !File(path).existsSync()) return;
    try {
      await _player.stop();
      await _player.setFilePath(path);
      await _player.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> stopAudioPlayback() async {
    await _player.stop();
  }

  /// 5. BẮT ĐẦU NHẬN DIỆN CHỮ OFFLINE (Bằng speech_to_text trên máy)
  Future<bool> startSpeechToTextOffline({
    required Function(String text) onResult,
  }) async {
    await releaseMicrophone();

    final bool available = await _speech.initialize(
      onError: (e) => debugPrint('STT Error: $e'),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isSpeechListening = false;
        }
      },
    );

    if (available) {
      _isSpeechListening = true;
      await _speech.listen(
        onResult: (val) {
          if (val.recognizedWords.isNotEmpty) {
            onResult(val.recognizedWords);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: 'vi_VN',
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
      return true;
    }
    return false;
  }

  Future<void> stopSpeechToTextOffline() async {
    if (_isSpeechListening) {
      await _speech.stop();
      _isSpeechListening = false;
    }
  }

  /// 6. XỬ LÝ GEMINI ONLINE (Gửi file âm thanh + Prompt ➔ Trả về JSON)
  Future<VoiceHybridResult?> processOnlineGemini({
    required String audioPath,
    required VoiceMode mode,
  }) async {
    if (_geminiModel == null || audioPath.isEmpty || !File(audioPath).existsSync()) {
      return null;
    }

    try {
      final audioBytes = await File(audioPath).readAsBytes();
      final audioPart = DataPart('audio/m4a', audioBytes);

      String prompt = '';
      switch (mode) {
        case VoiceMode.recording:
          prompt = 'Hãy chép lời âm thanh này sang tiếng Việt chuẩn đầy đủ dấu câu. Trả về đúng định dạng JSON: {"transcript": "nội dung chép lời"}';
          break;
        case VoiceMode.calculator:
          prompt = 'Hãy phân tích phép tính toán học trong âm thanh. Trả về đúng định dạng JSON: {"expression": "5 * 5", "result": "25"}';
          break;
        case VoiceMode.note:
          prompt = 'Hãy tóm tắt nội dung chính âm thanh này. Trả về đúng định dạng JSON: {"title": "Tiêu đề ghi chú", "bullets": ["ý 1", "ý 2"]}';
          break;
        case VoiceMode.journal:
          prompt = 'Hãy phân tích cả nội dung và ngữ điệu âm thanh để nhận diện cảm xúc. Trả về đúng định dạng JSON: {"transcript": "nội dung", "mood": "Vui vẻ", "emoji": "😊"}';
          break;
      }

      final response = await _geminiModel!.generateContent([
        Content.multi([TextPart(prompt), audioPart])
      ]);

      final text = response.text ?? '';
      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = text.substring(jsonStart, jsonEnd + 1);
        final data = jsonDecode(jsonStr);

        return VoiceHybridResult(
          transcript: data['transcript'] ?? '',
          title: data['title'] ?? '',
          expression: data['expression'] ?? '',
          result: data['result'] ?? '',
          bullets: List<String>.from(data['bullets'] ?? []),
          mood: data['mood'] ?? 'Bình thường',
          emoji: data['emoji'] ?? '😊',
          audioPath: audioPath,
          isOnline: true,
        );
      }
    } catch (e) {
      debugPrint('Gemini processing error: $e');
    }
    return null;
  }

  /// 7. TÍNH TOÁN MATH_EXPRESSIONS OFFLINE
  String evaluateMathExpressionOffline(String input) {
    try {
      String expStr = input
          .toLowerCase()
          .replaceAll('cộng', '+')
          .replaceAll('trừ', '-')
          .replaceAll('nhân', '*')
          .replaceAll('x', '*')
          .replaceAll('chia', '/')
          .replaceAll('bằng', '')
          .replaceAll('không', '0')
          .replaceAll('một', '1')
          .replaceAll('hai', '2')
          .replaceAll('ba', '3')
          .replaceAll('bốn', '4')
          .replaceAll('năm', '5')
          .replaceAll('sáu', '6')
          .replaceAll('bảy', '7')
          .replaceAll('tám', '8')
          .replaceAll('chín', '9');

      expStr = expStr.replaceAll(RegExp(r'[^0-9+\-*/.]'), '');

      final GrammarParser p = GrammarParser();
      final Expression exp = p.parse(expStr);
      final ContextModel cm = ContextModel();
      final double eval = exp.evaluate(EvaluationType.REAL, cm);

      if (eval == eval.roundToDouble()) {
        return eval.toInt().toString();
      }
      return eval.toStringAsFixed(2);
    } catch (_) {
      return 'Lỗi';
    }
  }

  /// 8. NHẬN DIỆN CẢM XÚC TỪ KHÓA OFFLINE
  Map<String, String> detectMoodFromTextOffline(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('vui') || lower.contains('tuyệt') || lower.contains('thích') || lower.contains('hạnh phúc')) {
      return {'mood': 'Vui vẻ', 'emoji': '😊'};
    } else if (lower.contains('buồn') || lower.contains('khóc') || lower.contains('tệ') || lower.contains('chán')) {
      return {'mood': 'Buồn rầu', 'emoji': '😢'};
    } else if (lower.contains('giận') || lower.contains('tức') || lower.contains('bực')) {
      return {'mood': 'Tức giận', 'emoji': '😡'};
    } else if (lower.contains('sợ') || lower.contains('lo')) {
      return {'mood': 'Lo lắng', 'emoji': '😰'};
    }
    return {'mood': 'Bình thường', 'emoji': '😐'};
  }
}
