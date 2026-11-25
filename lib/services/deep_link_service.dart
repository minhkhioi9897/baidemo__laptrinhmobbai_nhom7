import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../screens/notes_screen.dart';
import '../screens/note_editor_screen.dart';
import '../screens/calculator_screen.dart';
import '../screens/recording_list_screen.dart';
import '../screens/journal_screen.dart';
import '../screens/journal_editor_screen.dart';
import 'assistant_service.dart';
import 'tts_service.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> init() async {
    try {
      // Handle link when app is opened from terminated state
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }

      // Handle link when app is in background/foreground
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) {
          _handleUri(uri);
        },
        onError: (err) {
          debugPrint('DeepLink error: $err');
        },
      );
    } catch (e) {
      debugPrint('DeepLink init failed: $e');
    }
  }

  void _handleUri(Uri uri) {
    debugPrint('Received DeepLink URI: $uri');
    final host = uri.host.isNotEmpty ? uri.host : uri.pathSegments.firstOrNull ?? '';
    final pathSegments = uri.pathSegments;

    // Schedule navigation after current frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      switch (host) {
        case 'notes':
          if (pathSegments.contains('new')) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NoteEditorScreen()),
            );
            TtsService().speak('Đã mở màn hình tạo ghi chú mới');
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotesScreen()),
            );
            TtsService().speak('Đã mở danh sách ghi chú');
          }
          break;

        case 'calculator':
          final exp = uri.queryParameters['exp'];
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CalculatorScreen()),
          );
          if (exp != null && exp.isNotEmpty) {
            TtsService().speak('Đã mở máy tính thực hiện phép tính $exp');
          } else {
            TtsService().speak('Đã mở máy tính giọng nói');
          }
          break;

        case 'recording':
        case 'record':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RecordingListScreen()),
          );
          TtsService().speak('Đã mở màn hình ghi âm');
          break;

        case 'journal':
          if (pathSegments.contains('new')) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JournalEditorScreen()),
            );
            TtsService().speak('Đã mở màn hình tạo nhật ký mới');
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JournalScreen()),
            );
            TtsService().speak('Đã mở trang nhật ký');
          }
          break;

        case 'assistant':
        case 'command':
          final query = uri.queryParameters['query'] ?? uri.queryParameters['text'] ?? '';
          if (query.isNotEmpty) {
            final result = await AssistantService().processCommand(query, context: context);
            if (result.navigationAction != null) {
              result.navigationAction!();
            }
          }
          break;

        default:
          debugPrint('Unknown deep link host: $host');
          break;
      }
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
