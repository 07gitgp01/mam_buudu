import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/biometric_service.dart';
import '../landing_screen.dart';

class AuthSplashScreen extends StatefulWidget {
  const AuthSplashScreen({super.key});

  @override
  State<AuthSplashScreen> createState() => _AuthSplashScreenState();
}

class _AuthSplashScreenState extends State<AuthSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _textOpacity;

  String _statusText = 'Vérification de votre session...';

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _textController.forward();
    });

    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    // Attendre la fin des animations
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    // 1. Session encore valide ?
    final sessionValid = await ApiService.isSessionValid();

    if (!sessionValid) {
      // Token absent ou expiré → login obligatoire
      _goToLanding();
      return;
    }

    // 2. Profil non complété → demander la question secrète
    final profileComplete = await ApiService.hasCompletedProfile();
    if (!profileComplete) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/complete_profile', (_) => false);
      }
      return;
    }

    // 3. Session valide : biométrie activée sur cet appareil ?
    final biometricEnabled = await BiometricService.isEnabled();

    if (!biometricEnabled) {
      // Pas de biométrie configurée → accès direct
      _goHome();
      return;
    }

    // 3. Biométrie activée → demander l'empreinte
    if (mounted) {
      setState(() => _statusText = 'Posez votre doigt pour déverrouiller');
    }

    final authenticated = await BiometricService.authenticate(
      reason: 'Déverrouillez Mam Buudu avec votre empreinte digitale',
    );

    if (!mounted) return;

    if (authenticated) {
      _goHome();
    } else {
      // Échec biométrie → on propose le login classique
      setState(() => _statusText = 'Authentification échouée');
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) _goToLanding();
    }
  }

  void _goHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }

  void _goToLanding() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
              Colors.blue.shade100,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _logoScale,
                  builder: (_, child) =>
                      Transform.scale(scale: _logoScale.value, child: child),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.family_restroom,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                AnimatedBuilder(
                  animation: _textOpacity,
                  builder: (_, child) =>
                      Opacity(opacity: _textOpacity.value, child: child),
                  child: Column(
                    children: [
                      Text(
                        'Mam Buudu',
                        style: GoogleFonts.poppins(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Votre histoire familiale, préservée',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                AnimatedBuilder(
                  animation: _textOpacity,
                  builder: (_, child) =>
                      Opacity(opacity: _textOpacity.value, child: child),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          color: Colors.blue.shade600,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _statusText,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
