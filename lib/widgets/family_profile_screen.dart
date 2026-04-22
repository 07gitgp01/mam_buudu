import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/family_connect_theme.dart';

/// Écran de profil familial moderne avec statistiques
class FamilyProfileScreen extends StatefulWidget {
  const FamilyProfileScreen({super.key});

  @override
  State<FamilyProfileScreen> createState() => _FamilyProfileScreenState();
}

class _FamilyProfileScreenState extends State<FamilyProfileScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _statsController;
  late AnimationController _fadeController;
  late Animation<double> _statsAnimation;
  late Animation<double> _fadeAnimation;
  
  // Statistiques familiales
  final Map<String, int> _familyStats = {
    'Total personnes': 156,
    'Générations': 5,
    'Unions': 42,
    'Photos': 89,
    'Documents': 23,
  };
  
  @override
  void initState() {
    super.initState();
    
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: FamilyConnectTheme.normalDuration,
      vsync: this,
    );
    
    _statsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statsController,
      curve: FamilyConnectTheme.sharpCurve,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: FamilyConnectTheme.defaultCurve,
    ));
    
    // Démarrer les animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _statsController.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _statsController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildFamilyOverview(),
              const SizedBox(height: 24),
              _buildStatsGrid(),
              const SizedBox(height: 24),
              _buildRecentActivity(),
              const SizedBox(height: 24),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: FamilyConnectTheme.primaryGradient,
          borderRadius: FamilyConnectTheme.radiusLg,
          boxShadow: FamilyConnectTheme.shadowLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: FamilyConnectTheme.radiusFull,
                  ),
                  child: const Icon(
                    Icons.family_restroom,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Famille Dupont',
                        style: FamilyConnectTheme.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Arbre généalogique complet',
                        style: FamilyConnectTheme.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // Menu options
                  },
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFamilyOverview() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: FamilyConnectTheme.radiusLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aperçu de la famille',
              style: FamilyConnectTheme.h4.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewItem(
                    icon: Icons.person,
                    label: 'Membres',
                    value: '${_familyStats['Total personnes']}',
                    color: FamilyConnectTheme.primaryGradient,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOverviewItem(
                    icon: Icons.layers,
                    label: 'Générations',
                    value: '${_familyStats['Générations']}',
                    color: FamilyConnectTheme.secondaryGradient,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOverviewItem(
                    icon: Icons.favorite,
                    label: 'Unions',
                    value: '${_familyStats['Unions']}',
                    color: FamilyConnectTheme.accentGradient,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOverviewItem({
    required IconData icon,
    required String label,
    required String value,
    required LinearGradient color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: FamilyConnectTheme.radiusMd,
        boxShadow: FamilyConnectTheme.shadowXs,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: color,
              borderRadius: FamilyConnectTheme.radiusSm,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: FamilyConnectTheme.h3.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: FamilyConnectTheme.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiques détaillées',
          style: FamilyConnectTheme.h4.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: _familyStats.entries.map((entry) {
            return _buildStatCard(entry.key, entry.value);
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String label, int value) {
    return AnimatedBuilder(
      animation: _statsAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _statsAnimation.value,
          child: FadeTransition(
            opacity: _statsAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: FamilyConnectTheme.radiusLg,
                boxShadow: FamilyConnectTheme.shadowSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(value * _statsAnimation.value).round()}',
                    style: FamilyConnectTheme.h2.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: FamilyConnectTheme.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activité récente',
              style: FamilyConnectTheme.h4.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                // Voir toute l'activité
              },
              child: Text(
                'Voir tout',
                style: FamilyConnectTheme.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...[
          _buildActivityItem(
            icon: Icons.person_add,
            title: 'Nouvelle personne ajoutée',
            subtitle: 'Marie Durand - Il y a 2 heures',
            color: FamilyConnectTheme.successColor,
          ),
          _buildActivityItem(
            icon: Icons.photo,
            title: 'Photo ajoutée',
            subtitle: 'Jean Martin - Il y a 5 heures',
            color: FamilyConnectTheme.primaryColor,
          ),
          _buildActivityItem(
            icon: Icons.edit,
            title: 'Profil mis à jour',
            subtitle: 'Sophie Bernard - Hier',
            color: FamilyConnectTheme.warningColor,
          ),
        ],
      ],
    );
  }
  
  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          // Voir les détails
        },
        borderRadius: FamilyConnectTheme.radiusSm,
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: FamilyConnectTheme.radiusSm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: FamilyConnectTheme.radiusSm,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: FamilyConnectTheme.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: FamilyConnectTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: FamilyConnectTheme.h4.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.share,
                label: 'Partager',
                color: FamilyConnectTheme.primaryGradient,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  // Partager l'arbre
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.download,
                label: 'Exporter',
                color: FamilyConnectTheme.secondaryGradient,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  // Exporter les données
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.settings,
                label: 'Paramètres',
                color: FamilyConnectTheme.accentGradient,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  // Paramètres de la famille
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required LinearGradient color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: FamilyConnectTheme.radiusMd,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: color,
            borderRadius: FamilyConnectTheme.radiusMd,
            boxShadow: FamilyConnectTheme.shadowSm,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: FamilyConnectTheme.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
