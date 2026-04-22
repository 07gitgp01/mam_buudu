import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'database/database_helper.dart';
// import 'services/notification_local_service.dart';
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
// import 'screens/notifications_screen.dart';
import 'services/notification_service.dart';
import 'theme/family_connect_theme.dart';
import 'navigation/family_navigation.dart';
import 'widgets/modern_search_screen.dart';
import 'widgets/family_profile_screen.dart';

void main() async {
  print('=== MAIN START ===');
  WidgetsFlutterBinding.ensureInitialized();
  print('Flutter binding initialized');
  
  // Initialisation de la base de données
  print('Initializing database...');
  await DatabaseHelper.instance.database;
  print('Database initialization completed');
  
  // Initialisation du service de notifications
  // print('Initializing notifications...');
  // await NotificationLocalService().initialize(userId: 'default_user');
  // print('Notifications initialized');
  
  // Vérifier les notifications à envoyer
  // await NotificationLocalService().checkAndSendNotifications();
  
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
      theme: FamilyConnectTheme.lightTheme,
      darkTheme: FamilyConnectTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/auth_splash',
      routes: {
        '/auth_splash': (context) => const AuthSplashScreen(),
        '/landing': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/wizard': (context) => const WizardScreen(),
        '/home': (context) => const FamilyNavigation(),
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
        '/search': (context) => const ModernSearchScreen(),
        '/family': (context) => const FamilyProfileScreen(),
        // '/notifications': (context) => const NotificationsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
