import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'database/database_helper.dart';
import 'models/union.dart';
import 'screens/landing_screen.dart';
import 'screens/wizard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/person_detail_screen.dart';
import 'screens/union_form_screen.dart';
import 'screens/tree_screen.dart';
import 'screens/livret_screen.dart';
import 'screens/auth/auth_splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'services/notification_service.dart';

void main() async {
  print('=== MAIN START ===');
  WidgetsFlutterBinding.ensureInitialized();
  print('Flutter binding initialized');
  
  // Initialisation de la base de données
  print('Initializing database...');
  await DatabaseHelper.instance.database;
  print('Database initialization completed');
  
  print('Starting app...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'Mam Buudu - Arbre Généalogique',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
        brightness: Brightness.light,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.copyWith(
            headlineLarge: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
            headlineMedium: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A237E),
            ),
            bodyLarge: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
            ),
            bodyMedium: const TextStyle(
              fontSize: 16,
              color: Color(0xFF424242),
            ),
            bodySmall: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF8F9FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
          labelStyle: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      initialRoute: '/auth_splash',
      routes: {
        '/auth_splash': (context) => const AuthSplashScreen(),
        '/landing': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/wizard': (context) => const WizardScreen(),
        '/home': (context) => const HomeScreen(),
        '/tree': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is String) {
            return TreeScreen(racineId: args);
          }
          return const TreeScreen(racineId: 'default');
        },
        '/person/detail': (context) {
          final personneId = ModalRoute.of(context)?.settings.arguments as String;
          return PersonDetailScreen(personneId: personneId);
        },
        '/union/form': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            final personneIdInitiale = args['personneIdInitiale'] as String?;
            final union = args['union'] as Union?;
            return UnionFormScreen(
              personneIdInitiale: personneIdInitiale,
              union: union,
            );
          }
          return const UnionFormScreen();
        },
        '/livret': (context) => const LivretScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
