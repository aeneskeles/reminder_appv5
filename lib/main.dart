import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase'i başlat
  try {
    await SupabaseService.instance.initialize();
  } catch (e) {
    debugPrint('Supabase başlatılamadı: $e');
    debugPrint(
      'Lütfen lib/services/supabase_service.dart dosyasında Supabase URL ve key bilgilerinizi güncelleyin!',
    );
  }

  // Bildirim servisini sadece web dışı platformlarda başlat
  if (!kIsWeb) {
    try {
      await NotificationService.instance.initialize();
    } catch (e) {
      debugPrint('Bildirim servisi başlatılamadı: $e');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService.instance;

    return MaterialApp(
      title: 'Hatırlatıcı',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
      locale: const Locale('tr', 'TR'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      routes: {'/home': (context) => const HomeScreen()},
      home: StreamBuilder(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          // Auth state değişikliklerini dinle
          final isLoggedIn = authService.isLoggedIn;

          if (isLoggedIn) {
            return const HomeScreen();
          } else {
            return const AuthScreen();
          }
        },
      ),
    );
  }
}
