import 'package:flutter/material.dart';
import '../utils/calculator_parser.dart';
import 'notes_service.dart';
import 'journal_service.dart';
import 'tts_service.dart';
import '../screens/notes_screen.dart';
import '../screens/note_editor_screen.dart';
import '../screens/calculator_screen.dart';
import '../screens/recording_list_screen.dart';
import '../screens/journal_screen.dart';
import '../screens/journal_editor_screen.dart';

class AssistantResult {
  final String responseText;
  final VoidCallback? navigationAction;

  AssistantResult({
    required this.responseText,
    this.navigationAction,
  });
}

class AssistantService {
  static final AssistantService _instance = AssistantService._internal();
  factory AssistantService() => _instance;
  AssistantService._internal();

  final TtsService _ttsService = TtsService();

  Future<AssistantResult> processCommand(
    String query, {
    required BuildContext context,
  }) async {
    final lowerQuery = query.toLowerCase().trim();

    if (lowerQuery.isEmpty) {
      const msg = 'Tôi chưa nghe rõ. Bạn vui lòng nói lại nhé!';
      await _ttsService.speak(msg);
      return AssistantResult(responseText: msg);
    }

    // 1. Máy tính / Tính toán (Check calculator intent or math expression)
    if (lowerQuery.contains('máy tính') ||
        lowerQuery.contains('tính toán') ||
        lowerQuery.contains('tính')) {
      final parsedExp = CalculatorParser.parseVietnameseSpeech(lowerQuery);
      final evaluated = CalculatorParser.evaluateExpression(parsedExp);

      if (evaluated != null && (lowerQuery.contains('cộng') || lowerQuery.contains('trừ') || lowerQuery.contains('nhân') || lowerQuery.contains('chia'))) {
        final resultStr = CalculatorParser.formatResult(evaluated);
        final response = 'Kết quả phép tính là: $resultStr';
        await _ttsService.speak(response);

        return AssistantResult(
          responseText: response,
          navigationAction: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CalculatorScreen()),
            );
          },
        );
      } else {
        const response = 'Đang mở màn hình máy tính cho bạn.';
        await _ttsService.speak(response);

        return AssistantResult(
          responseText: response,
          navigationAction: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CalculatorScreen()),
            );
          },
        );
      }
    }

    // 2. Ghi chú (Notes intent)
    if (lowerQuery.contains('ghi chú') || lowerQuery.contains('note')) {
      if (lowerQuery.contains('tạo') ||
          lowerQuery.contains('thêm') ||
          lowerQuery.contains('mới') ||
          lowerQuery.contains('viết')) {
        const response = 'Đang mở màn hình tạo ghi chú mới.';
        await _ttsService.speak(response);

        return AssistantResult(
          responseText: response,
          navigationAction: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NoteEditorScreen()),
            );
          },
        );
      }

      if (lowerQuery.contains('đọc') || lowerQuery.contains('nghe')) {
        final notes = NotesService().notes;
        if (notes.isEmpty) {
          const response = 'Bạn chưa có ghi chú nào.';
          await _ttsService.speak(response);
          return AssistantResult(responseText: response);
        } else {
          final firstNote = notes.first;
          final response = 'Ghi chú mới nhất có tiêu đề: ${firstNote.title}. Nội dung: ${firstNote.content}';
          await _ttsService.speak(response);
          return AssistantResult(
            responseText: response,
            navigationAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotesScreen()),
              );
            },
          );
        }
      }

      const response = 'Đang mở danh sách ghi chú.';
      await _ttsService.speak(response);
      return AssistantResult(
        responseText: response,
        navigationAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotesScreen()),
          );
        },
      );
    }

    // 3. Nhật ký (Journal intent)
    if (lowerQuery.contains('nhật ký') || lowerQuery.contains('journal')) {
      if (lowerQuery.contains('tạo') ||
          lowerQuery.contains('thêm') ||
          lowerQuery.contains('mới') ||
          lowerQuery.contains('viết')) {
        const response = 'Đang mở màn hình viết nhật ký mới.';
        await _ttsService.speak(response);

        return AssistantResult(
          responseText: response,
          navigationAction: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JournalEditorScreen()),
            );
          },
        );
      }

      if (lowerQuery.contains('đọc') || lowerQuery.contains('nghe')) {
        final journals = JournalService().journals;
        if (journals.isEmpty) {
          const response = 'Bạn chưa có trang nhật ký nào.';
          await _ttsService.speak(response);
          return AssistantResult(responseText: response);
        } else {
          final firstJournal = journals.first;
          final response = 'Nhật ký gần nhất tâm trạng: ${firstJournal.moodText}. Nội dung: ${firstJournal.content}';
          await _ttsService.speak(response);
          return AssistantResult(
            responseText: response,
            navigationAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JournalScreen()),
              );
            },
          );
        }
      }

      const response = 'Đang mở trang nhật ký của bạn.';
      await _ttsService.speak(response);
      return AssistantResult(
        responseText: response,
        navigationAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JournalScreen()),
          );
        },
      );
    }

    // 4. Ghi âm (Recording intent)
    if (lowerQuery.contains('ghi âm') ||
        lowerQuery.contains('thu âm') ||
        lowerQuery.contains('record')) {
      const response = 'Đang mở màn hình ghi âm giọng nói.';
      await _ttsService.speak(response);

      return AssistantResult(
        responseText: response,
        navigationAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RecordingListScreen()),
          );
        },
      );
    }

    // 5. Trợ giúp / Giới thiệu
    if (lowerQuery.contains('trợ giúp') ||
        lowerQuery.contains('hướng dẫn') ||
        lowerQuery.contains('làm gì')) {
      const response = 'Tôi có thể giúp bạn mở ghi chú, tính toán bằng giọng nói, thu âm, hoặc viết nhật ký. Bạn hãy nói lệnh nhé!';
      await _ttsService.speak(response);
      return AssistantResult(responseText: response);
    }

    // Unrecognized command fallback
    final response = 'Đã nhận câu lệnh: "$query". Đang xử lý yêu cầu của bạn.';
    await _ttsService.speak(response);
    return AssistantResult(responseText: response);
  }
}
