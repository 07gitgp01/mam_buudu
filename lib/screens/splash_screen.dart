import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'wizard_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    print('🚀 Début du splash screen...');
    
    // Attendre un peu pour l'effet de splash
    await Future.delayed(const Duration(seconds: 2));
    
    print('⏰ Délai terminé, vérification SharedPreferences...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final wizardCompleted = prefs.getBool('wizard_completed') ?? false;
      
      print('📊 Wizard completed: $wizardCompleted');
      
      if (!mounted) {
        print('❌ Widget n est plus mounted');
        return;
      }
      
      if (wizardCompleted) {
        print('🏠 Navigation vers HomeScreen...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        print('🧙‍♂️ Navigation vers WizardScreen...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WizardScreen()),
        );
      }
    } catch (e) {
      print('❌ Erreur: $e');
      // En cas d'erreur, aller vers HomeScreen par défaut
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône de l'application
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.family_restroom,
                size: 60,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 40),
            
            // Nom de l'application
            const Text(
              'Mam Buudu',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            
            const Text(
              'Votre arbre généalogique familial',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 60),
            
            // Indicateur de chargement
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Chargement...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
