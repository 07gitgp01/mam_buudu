import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/family_connect_theme.dart';
import '../models/personne.dart';
import '../database/personne_repository.dart';
import '../screens/person_form_screen.dart';
import '../screens/person_detail_screen.dart';
import '../widgets/instagram_person_card.dart';
import '../widgets/loading_animations.dart';
import '../widgets/gamification_widgets.dart';
import '../services/gamification_service.dart';
import '../models/gamification.dart';
import '../screens/tree_screen.dart';

/// Écran d'accueil moderne avec switch liste/card
class ModernHomeScreen extends StatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen>
    with TickerProviderStateMixin {
  
  final PersonneRepository _personneRepo = PersonneRepository();
  final GamificationService _gamificationService = GamificationService();
  List<Personne> _personnes = [];
  List<Personne> _filteredPersonnes = [];
  bool _isLoading = true;
  bool _isCardView = true; // Switch entre liste et card
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _switchController;
  late Animation<double> _switchAnimation;
  GameProfile? _gameProfile;

  @override
  void initState() {
    super.initState();
    _loadPersonnes();
    _initializeGamification();
    
    _switchController = AnimationController(
      duration: FamilyConnectTheme.fastDuration,
      vsync: this,
    );
    
    _switchAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _switchController,
      curve: FamilyConnectTheme.defaultCurve,
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _switchController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonnes() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final personnes = await _personneRepo.getAll();
      setState(() {
        _personnes = personnes;
        _filteredPersonnes = personnes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: FamilyConnectTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _refresh() async {
    await _loadPersonnes();
  }

  Future<void> _initializeGamification() async {
    try {
      // Vérifier d'abord si un utilisateur est connecté
      final isConnected = await _gamificationService.isUserConnected();
      if (isConnected) {
        _gameProfile = await _gamificationService.initializeProfile();
      } else {
        debugPrint('Aucun utilisateur connecté - gamification non initialisée');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation de la gamification: $e');
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.toLowerCase();
      _filteredPersonnes = _personnes.where((personne) {
        return personne.nomComplet.toLowerCase().contains(_searchQuery) ||
               (personne.lieuNaissance?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    });
  }

  void _toggleView() {
    HapticFeedback.lightImpact();
    setState(() {
      _isCardView = !_isCardView;
    });
    _switchController.forward().then((_) {
      _switchController.reverse();
    });
  }

  void _navigateToAddPersonne() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PersonFormScreen(),
      ),
    );
    
    if (result == true) {
      await _refresh();
      
      // Ajouter des points de gamification seulement si un utilisateur est connecté
      final isConnected = await _gamificationService.isUserConnected();
      if (isConnected) {
        await _gamificationService.addPoints(
          action: ActionType.addPerson,
          description: 'Nouvelle personne ajoutée',
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Personne ajoutée avec succès !${isConnected ? ' +10 points' : ''}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _navigateToTree() {
    if (_personnes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez d\'abord des membres à votre famille.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TreeScreen(racineId: _personnes.first.id),
      ),
    );
  }

  void _navigateToPersonneDetail(Personne personne) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonDetailScreen(personneId: personne.id),
      ),
    );
    
    if (result == true) {
      await _refresh();
    }
  }

  void _sharePerson(Personne personne) async {
    // Ajouter des points de gamification pour le partage seulement si connecté
    final isConnected = await _gamificationService.isUserConnected();
    if (isConnected) {
      await _gamificationService.addPoints(
        action: ActionType.shareProfile,
        targetId: personne.id,
        description: 'Partage de ${personne.nomComplet}',
      );
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partage de ${personne.nomComplet} !${isConnected ? ' +3 points' : ''}'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header avec niveau et switch
            _buildHeader(),
            
            // Contenu principal
            Expanded(
              child: _isLoading
                  ? LoadingAnimations.fullPageLoading(
                      message: 'Chargement des personnes...',
                    )
                  : _filteredPersonnes.isEmpty
                      ? LoadingAnimations.emptyState(
                          icon: Icons.people_outline,
                          title: _searchQuery.isNotEmpty 
                              ? 'Aucune personne trouvée pour "$_searchQuery"'
                              : 'Aucune personne dans l\'arbre',
                          subtitle: _searchQuery.isEmpty 
                              ? 'Commencez par ajouter votre premier membre de famille'
                              : 'Essayez avec d\'autres termes de recherche',
                          actions: _searchQuery.isEmpty ? [
                            LoadingButton(
                              onPressed: _navigateToAddPersonne,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_add, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ajouter une personne',
                                    style: FamilyConnectTheme.bodySmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] : null,
                        )
                      : _buildPersonList(),
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _navigateToAddPersonne,
      //   backgroundColor: FamilyConnectTheme.primaryColor,
      //   child: const Icon(Icons.person_add, color: Colors.white),
      // ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Niveau et titre
          if (_gameProfile != null) ...[
            LevelIndicator(
              profile: _gameProfile!,
              showDetails: false,
            ),
            const SizedBox(height: 16),
          ],
          
          // Switch et titre
          Row(
            children: [
              Expanded(
                child: Text(
                  'Membres de la famille',
                  style: FamilyConnectTheme.h3.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Switch liste/card
              AnimatedBuilder(
                animation: _switchAnimation,
                builder: (context, child) {
                  return GestureDetector(
                    onTap: _toggleView,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: FamilyConnectTheme.primaryGradient,
                        borderRadius: FamilyConnectTheme.radiusFull,
                        boxShadow: FamilyConnectTheme.shadowSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isCardView ? Icons.view_list : Icons.grid_view,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isCardView ? 'Liste' : 'Cards',
                            style: FamilyConnectTheme.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bouton Arbre généalogique (pleine largeur)
          GestureDetector(
            onTap: _navigateToTree,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: FamilyConnectTheme.secondaryGradient,
                borderRadius: FamilyConnectTheme.radiusMd,
                boxShadow: FamilyConnectTheme.shadowSm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_tree, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Voir l\'arbre généalogique',
                    style: FamilyConnectTheme.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Barre de recherche
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher une personne...',
              hintStyle: FamilyConnectTheme.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: FamilyConnectTheme.radiusLg,
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: FamilyConnectTheme.radiusLg,
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: FamilyConnectTheme.radiusLg,
                borderSide: BorderSide(
                  color: FamilyConnectTheme.primaryColor,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: FamilyConnectTheme.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonList() {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: FamilyConnectTheme.primaryColor,
      child: _isCardView ? _buildCardView() : _buildListView(),
    );
  }

  Widget _buildCardView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredPersonnes.length,
      itemBuilder: (context, index) {
        final personne = _filteredPersonnes[index];
        return InstagramPersonCard(
          personne: personne,
          onTap: () => _navigateToPersonneDetail(personne),
          onEdit: () => _navigateToPersonneDetail(personne),
          onShare: () => _sharePerson(personne),
          enableSwipe: true,
          showActions: true,
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredPersonnes.length,
      itemBuilder: (context, index) {
        final personne = _filteredPersonnes[index];
        return _buildListItem(personne);
      },
    );
  }

  Widget _buildListItem(Personne personne) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHighest,
            Theme.of(context).colorScheme.surface,
          ],
        ),
        borderRadius: FamilyConnectTheme.radiusLg,
        boxShadow: FamilyConnectTheme.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToPersonneDetail(personne),
          borderRadius: FamilyConnectTheme.radiusLg,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar (photo ou initiales)
                _buildPersonAvatar(personne, size: 50),
                
                const SizedBox(width: 16),
                
                // Informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        personne.nomComplet,
                        style: FamilyConnectTheme.bodyLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (personne.datesAffichage.isNotEmpty)
                        Text(
                          personne.datesAffichage,
                          style: FamilyConnectTheme.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Flèche
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonAvatar(Personne personne, {double size = 50}) {
    final hasPhoto = personne.photoPath != null && personne.photoPath!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: FamilyConnectTheme.primaryGradient,
        borderRadius: FamilyConnectTheme.radiusFull,
        boxShadow: FamilyConnectTheme.shadowSm,
      ),
      child: ClipRRect(
        borderRadius: FamilyConnectTheme.radiusFull,
        child: hasPhoto
            ? Image.file(
                File(personne.photoPath!),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _avatarInitiales(personne, size),
              )
            : _avatarInitiales(personne, size),
      ),
    );
  }

  Widget _avatarInitiales(Personne personne, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(gradient: FamilyConnectTheme.primaryGradient),
      child: Center(
        child: Text(
          _getInitials(personne.nomComplet),
          style: FamilyConnectTheme.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.28,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    return '??';
  }
}
