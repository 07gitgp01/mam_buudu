import 'package:flutter/material.dart';
import '../theme/family_connect_theme.dart';
import '../services/gamification_service.dart';
import '../widgets/gamification_widgets.dart';

/// Écran de gamification simplifié
class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  final GamificationService _gamificationService = GamificationService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Gamification'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        elevation: 0,
      ),
      body: FutureBuilder(
        future: _gamificationService.isUserConnected(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || !snapshot.data!) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.login_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Connectez-vous pour accéder à la gamification',
                    style: FamilyConnectTheme.h4.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gagnez des points, débloquez des badges et suivez votre progression',
                    style: FamilyConnectTheme.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          
          return const _GamificationContent();
        },
      ),
    );
  }
}

class _GamificationContent extends StatelessWidget {
  const _GamificationContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Pour l'instant, affichons un contenu simple
    // Le profil sera chargé dynamiquement plus tard
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: FamilyConnectTheme.primaryGradient,
              borderRadius: FamilyConnectTheme.radiusLg,
              boxShadow: FamilyConnectTheme.shadowLg,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: FamilyConnectTheme.radiusFull,
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gamification',
                            style: FamilyConnectTheme.h3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Progression et achievements',
                            style: FamilyConnectTheme.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Contenu temporaire
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: FamilyConnectTheme.radiusLg,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.construction,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Fonctionnalités bientôt disponibles',
                  style: FamilyConnectTheme.h4.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Points et niveaux\n'
                  '• Badges à débloquer\n'
                  '• Série de connexions\n'
                  '• Statistiques détaillées',
                  style: FamilyConnectTheme.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fonctionnalités en développement !'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: FamilyConnectTheme.radiusLg,
                    ),
                  ),
                  child: Text(
                    'Revenir plus tard',
                    style: FamilyConnectTheme.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
