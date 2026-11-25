import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/notes_service.dart';
import 'services/recordings_service.dart';
import 'services/journal_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  await AuthService().init();
  await NotesService().init();
  await RecordingsService().init();
  await JournalService().init();
  runApp(const VoiceHubApp());
}

class VoiceHubApp extends StatelessWidget {
  const VoiceHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (_, mode, child) => MaterialApp(
        title: 'VoiceHub',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: authService.isLoggedIn
            ? HomeScreen(userName: authService.currentUserName)
            : const LoginScreen(),
      ),
    );
  }
}
