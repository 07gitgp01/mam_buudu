import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/family_connect_theme.dart';
import '../database/personne_repository.dart';
import '../database/union_repository.dart';
import '../models/personne.dart';
import '../screens/person_detail_screen.dart';

/// Écran de profil familial moderne avec statistiques
class FamilyProfileScreen extends StatefulWidget {
  const FamilyProfileScreen({super.key});

  @override
  State<FamilyProfileScreen> createState() => _FamilyProfileScreenState();
}

class _FamilyProfileScreenState extends State<FamilyProfileScreen>
    with TickerProviderStateMixin {

  final PersonneRepository _personneRepo = PersonneRepository();
  final UnionRepository _unionRepo = UnionRepository();

  late AnimationController _statsController;
  late AnimationController _fadeController;
  late Animation<double> _statsAnimation;
  late Animation<double> _fadeAnimation;

  int _totalPersonnes = 0;
  int _totalUnions = 0;
  int _totalPhotos = 0;
  List<Personne> _recentPersonnes = [];
  bool _statsLoaded = false;
  String _familleName = '';
  String _familleCode = '';

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

    _fadeController.forward();
    _loadStats();
    _loadFamilleInfo();
  }

  Future<void> _loadFamilleInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _familleName = prefs.getString('api_famille_nom') ?? '';
        _familleCode = prefs.getString('api_famille_code') ?? '';
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait([
        _personneRepo.getCount(),
        _unionRepo.getCount(),
        _personneRepo.getWithPhoto(),
        _personneRepo.getRecentlyAdded(limit: 3),
      ]);
      if (mounted) {
        setState(() {
          _totalPersonnes = results[0] as int;
          _totalUnions = results[1] as int;
          _totalPhotos = (results[2] as List<Personne>).length;
          _recentPersonnes = results[3] as List<Personne>;
          _statsLoaded = true;
        });
        _statsController.forward();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _statsLoaded = true);
        _statsController.forward();
      }
    }
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
                        _familleName.isNotEmpty ? 'Famille $_familleName' : 'Ma famille',
                        style: FamilyConnectTheme.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _familleCode.isNotEmpty ? 'Code : $_familleCode' : 'Arbre généalogique',
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                    value: '$_totalPersonnes',
                    color: FamilyConnectTheme.primaryGradient,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOverviewItem(
                    icon: Icons.photo_library,
                    label: 'Photos',
                    value: '$_totalPhotos',
                    color: FamilyConnectTheme.secondaryGradient,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOverviewItem(
                    icon: Icons.favorite,
                    label: 'Unions',
                    value: '$_totalUnions',
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
    final stats = [
      ('Personnes', _totalPersonnes, Icons.people),
      ('Unions', _totalUnions, Icons.favorite),
      ('Photos', _totalPhotos, Icons.photo_library),
    ];

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
        if (!_statsLoaded)
          const Center(child: CircularProgressIndicator())
        else
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: stats.map((s) => _buildStatCard(s.$1, s.$2)).toList(),
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
    if (_recentPersonnes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ajouts récents',
          style: FamilyConnectTheme.h4.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ..._recentPersonnes.map((p) => _buildPersonActivityItem(p)),
      ],
    );
  }

  Widget _buildPersonActivityItem(Personne personne) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PersonDetailScreen(personneId: personne.id),
            ),
          );
        },
        borderRadius: FamilyConnectTheme.radiusSm,
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: FamilyConnectTheme.radiusSm,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: FamilyConnectTheme.primaryColor.withValues(alpha: 0.15),
                child: Text(
                  personne.nomComplet.isNotEmpty ? personne.nomComplet[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: FamilyConnectTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      personne.nomComplet,
                      style: FamilyConnectTheme.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (personne.dateNaissance != null)
                      Text(
                        'Né(e) ${personne.dateNaissance!.toString()}',
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
