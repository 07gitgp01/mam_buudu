import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../theme/family_connect_theme.dart';
import '../models/family_game.dart';
import '../services/family_game_service.dart';
import '../widgets/family_game_widgets.dart';

/// Écran principal des jeux familiaux
class FamilyGamesScreen extends StatefulWidget {
  const FamilyGamesScreen({super.key});

  @override
  State<FamilyGamesScreen> createState() => _FamilyGamesScreenState();
}

class _FamilyGamesScreenState extends State<FamilyGamesScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  late AnimationController _filterController;
  late Animation<double> _filterAnimation;
  
  final FamilyGameService _gameService = FamilyGameService();
  List<FamilyGame> _availableGames = [];
  List<FamilyGame> _myGames = [];
  List<GameInvitation> _myInvitations = [];
  List<FamilyGame> _filteredGames = [];
  
  bool _isLoading = true;
  bool _showCreateGame = false;
  FamilyGameType? _selectedType;
  GameDifficulty? _selectedDifficulty;
  String _searchQuery = '';
  
  // Controllers pour la création de jeu
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxParticipantsController = TextEditingController(text: '4');
  final _timeLimitController = TextEditingController(text: '300');
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeGames();
  }

  void _initializeAnimations() {
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeOut),
    );
    
    _filterController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _filterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _filterController, curve: Curves.easeOut),
    );
    
    _fabController.forward();
  }

  Future<void> _initializeGames() async {
    try {
      await _gameService.initialize();
      
      // Écouter les streams
      _gameService.gamesStream.listen((games) {
        if (mounted) {
          setState(() {
            _availableGames = _gameService.getAvailableGames();
            _myGames = _gameService.getUserGames('temp_user_123');
            _filteredGames = _applyFilters(_availableGames);
          });
        }
      });
      
      _gameService.invitationsStream.listen((invitations) {
        if (mounted) {
          setState(() {
            _myInvitations = _gameService.getUserInvitations('temp_user_123');
          });
        }
      });
      
      // Charger les données initiales
      setState(() {
        _availableGames = _gameService.getAvailableGames();
        _myGames = _gameService.getUserGames('temp_user_123');
        _myInvitations = _gameService.getUserInvitations('temp_user_123');
        _filteredGames = _applyFilters(_availableGames);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur initialisation games: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<FamilyGame> _applyFilters(List<FamilyGame> games) {
    var filtered = games;
    
    // Filtrer par type
    if (_selectedType != null) {
      filtered = filtered.where((game) => game.type == _selectedType).toList();
    }
    
    // Filtrer par difficulté
    if (_selectedDifficulty != null) {
      filtered = filtered.where((game) => game.difficulty == _selectedDifficulty).toList();
    }
    
    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((game) =>
          game.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          game.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Contenu principal
            Expanded(
              child: _isLoading 
                  ? const GameLoadingIndicator()
                  : _buildContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Titre et badges
          Row(
            children: [
              Icon(
                Icons.sports_esports,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Jeux Familiaux',
                  style: FamilyConnectTheme.h3.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (_myInvitations.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_myInvitations.length}',
                    style: FamilyConnectTheme.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Barre de recherche et filtres
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: TextEditingController(text: _searchQuery),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _filteredGames = _applyFilters(_availableGames);
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher un jeu...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Filtres
              GestureDetector(
                onTap: _toggleFilters,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.filter_list,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          
          // Filtres actifs
          if (_selectedType != null || _selectedDifficulty != null) ...[
            const SizedBox(height: 12),
            _buildActiveFilters(),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (_selectedType != null)
          _buildFilterChip(
            label: _getTypeLabel(_selectedType!),
            onTap: () => setState(() {
              _selectedType = null;
              _filteredGames = _applyFilters(_availableGames);
            }),
          ),
        if (_selectedDifficulty != null)
          _buildFilterChip(
            label: _getDifficultyLabel(_selectedDifficulty!),
            onTap: () => setState(() {
              _selectedDifficulty = null;
              _filteredGames = _applyFilters(_availableGames);
            }),
          ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: FamilyConnectTheme.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onTap,
            child: Icon(
              Icons.close,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Tabs
          TabBar(
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.public, size: 16),
                    const SizedBox(width: 4),
                    Text('Disponibles'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, size: 16),
                    const SizedBox(width: 4),
                    Text('Mes jeux'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mail, size: 16),
                    const SizedBox(width: 4),
                    Text('Invitations'),
                  ],
                ),
              ),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              children: [
                _buildGamesList(_filteredGames, isAvailable: true),
                _buildGamesList(_myGames, isAvailable: false),
                _buildInvitationsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesList(List<FamilyGame> games, {required bool isAvailable}) {
    if (games.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAvailable ? Icons.sports_esports_outlined : Icons.games_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isAvailable 
                  ? 'Aucun jeu disponible'
                  : 'Aucun jeu créé',
              style: FamilyConnectTheme.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (isAvailable) ...[
              const SizedBox(height: 8),
              Text(
                'Créez votre premier jeu !',
                style: FamilyConnectTheme.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshGames,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return FamilyGameCard(
            game: game,
            onTap: () => _viewGameDetails(game),
            onJoin: isAvailable && game.canJoin('temp_user_123') 
                ? () => _joinGame(game)
                : null,
            onStart: !isAvailable && game.creatorId == 'temp_user_123' && game.canStart
                ? () => _startGame(game)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildInvitationsList() {
    if (_myInvitations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune invitation',
              style: FamilyConnectTheme.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _myInvitations.length,
      itemBuilder: (context, index) {
        final invitation = _myInvitations[index];
        return _buildInvitationCard(invitation);
      },
    );
  }

  Widget _buildInvitationCard(GameInvitation invitation) {
    final game = _gameService.games.firstWhere((g) => g.id == invitation.gameId);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: game.defaultColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getGameIcon(game.type),
                  color: game.defaultColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: FamilyConnectTheme.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Invitation de ${invitation.senderId.substring(0, 8)}...',
                      style: FamilyConnectTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Message
          Text(
            invitation.message,
            style: FamilyConnectTheme.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _respondToInvitation(invitation, false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Décliner'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _respondToInvitation(invitation, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: game.defaultColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Accepter'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: _showCreateGameDialog,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Créer'),
          ),
        );
      },
    );
  }

  void _toggleFilters() {
    if (_filterController.isCompleted) {
      _filterController.reverse();
    } else {
      _filterController.forward();
    }
    _showFilterBottomSheet();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                      const Expanded(
                        child: Text(
                          'Filtres',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                
                // Filtres
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Type de jeu
                      Text(
                        'Type de jeu',
                        style: FamilyConnectTheme.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: FamilyGameType.values.map((type) {
                          final isSelected = _selectedType == type;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                _selectedType = isSelected ? null : type;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getTypeLabel(type),
                                style: FamilyConnectTheme.bodySmall.copyWith(
                                  color: isSelected 
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Difficulté
                      Text(
                        'Difficulté',
                        style: FamilyConnectTheme.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: GameDifficulty.values.map((difficulty) {
                          final isSelected = _selectedDifficulty == difficulty;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                _selectedDifficulty = isSelected ? null : difficulty;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getDifficultyLabel(difficulty),
                                style: FamilyConnectTheme.bodySmall.copyWith(
                                  color: isSelected 
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                
                // Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedType = null;
                              _selectedDifficulty = null;
                            });
                          },
                          child: const Text('Réinitialiser'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _filteredGames = _applyFilters(_availableGames);
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Appliquer'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCreateGameDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                      const Expanded(
                        child: Text(
                          'Créer un jeu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                
                // Formulaire
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Titre
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Titre du jeu',
                          hintText: 'Ex: Quiz familial',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Description
                      TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Décrivez votre jeu...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Type de jeu
                      Text(
                        'Type de jeu',
                        style: FamilyConnectTheme.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<FamilyGameType>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: FamilyGameType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getTypeLabel(type)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() {
                            _selectedType = value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Difficulté
                      Text(
                        'Difficulté',
                        style: FamilyConnectTheme.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<GameDifficulty>(
                        value: _selectedDifficulty,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: GameDifficulty.values.map((difficulty) {
                          return DropdownMenuItem(
                            value: difficulty,
                            child: Text(_getDifficultyLabel(difficulty)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() {
                            _selectedDifficulty = value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Participants max
                      TextField(
                        controller: _maxParticipantsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Participants maximum',
                          hintText: '4',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Temps limite
                      TextField(
                        controller: _timeLimitController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Temps limite (secondes)',
                          hintText: '300',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: _createGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Créer le jeu'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _createGame() async {
    if (_titleController.text.isEmpty || 
        _descriptionController.text.isEmpty || 
        _selectedType == null || 
        _selectedDifficulty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    try {
      final game = await _gameService.createGame(
        title: _titleController.text,
        description: _descriptionController.text,
        type: _selectedType!,
        difficulty: _selectedDifficulty!,
        maxParticipants: int.tryParse(_maxParticipantsController.text) ?? 4,
        timeLimit: int.tryParse(_timeLimitController.text) ?? 300,
      );

      if (game != null) {
        Navigator.pop(context);
        _titleController.clear();
        _descriptionController.clear();
        _maxParticipantsController.text = '4';
        _timeLimitController.text = '300';
        _selectedType = null;
        _selectedDifficulty = null;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jeu créé avec succès !')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la création du jeu')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _joinGame(FamilyGame game) async {
    try {
      final success = await _gameService.joinGame(game.id, 'temp_user_123');
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous avez rejoint le jeu !')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de rejoindre ce jeu')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _startGame(FamilyGame game) async {
    try {
      final success = await _gameService.startGame(game.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le jeu a démarré !')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de démarrer ce jeu')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _respondToInvitation(GameInvitation invitation, bool accept) async {
    try {
      final success = await _gameService.respondToInvitation(invitation.id, accept);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accept ? 'Invitation acceptée !' : 'Invitation déclinée')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de répondre à cette invitation')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _refreshGames() async {
    // Simuler un rafraîchissement
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _availableGames = _gameService.getAvailableGames();
      _myGames = _gameService.getUserGames('temp_user_123');
      _filteredGames = _applyFilters(_availableGames);
    });
  }

  void _viewGameDetails(FamilyGame game) {
    // TODO: Naviguer vers les détails du jeu
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Détails du jeu: ${game.title}')),
    );
  }

  String _getTypeLabel(FamilyGameType type) {
    switch (type) {
      case FamilyGameType.quiz:
        return 'Quiz';
      case FamilyGameType.memory:
        return 'Memory';
      case FamilyGameType.timeline:
        return 'Timeline';
      case FamilyGameType.challenge:
        return 'Défi';
      case FamilyGameType.creative:
        return 'Créatif';
      case FamilyGameType.collaborative:
        return 'Collaboratif';
      case FamilyGameType.tournament:
        return 'Tournoi';
      case FamilyGameType.scavenger:
        return 'Chasse au trésor';
    }
  }

  String _getDifficultyLabel(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return 'Facile';
      case GameDifficulty.medium:
        return 'Moyen';
      case GameDifficulty.hard:
        return 'Difficile';
      case GameDifficulty.expert:
        return 'Expert';
    }
  }

  IconData _getGameIcon(FamilyGameType type) {
    switch (type) {
      case FamilyGameType.quiz:
        return Icons.quiz;
      case FamilyGameType.memory:
        return Icons.memory;
      case FamilyGameType.timeline:
        return Icons.timeline;
      case FamilyGameType.challenge:
        return Icons.emoji_events;
      case FamilyGameType.creative:
        return Icons.brush;
      case FamilyGameType.collaborative:
        return Icons.groups;
      case FamilyGameType.tournament:
        return Icons.military_tech;
      case FamilyGameType.scavenger:
        return Icons.search;
    }
  }

  @override
  void dispose() {
    _fabController.dispose();
    _filterController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _maxParticipantsController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }
}
