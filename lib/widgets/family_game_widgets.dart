import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/family_connect_theme.dart';
import '../models/family_game.dart';
import '../services/family_game_service.dart';

/// Carte de jeu pour la liste des jeux
class FamilyGameCard extends StatefulWidget {
  final FamilyGame game;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onStart;
  final bool showActions;

  const FamilyGameCard({
    super.key,
    required this.game,
    this.onTap,
    this.onJoin,
    this.onStart,
    this.showActions = true,
  });

  @override
  State<FamilyGameCard> createState() => _FamilyGameCardState();
}

class _FamilyGameCardState extends State<FamilyGameCard>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    _slideController.forward();
    _scaleController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _slideAnimation.value)),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  // Header avec type et statut
                  _buildHeader(),
                  
                  // Contenu principal
                  _buildContent(),
                  
                  // Participants et actions
                  _buildFooter(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.game.defaultColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Icône du jeu
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.game.defaultColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getGameIcon(widget.game.type),
              color: Colors.white,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.game.title,
                  style: FamilyConnectTheme.h4.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _getDifficultyIcon(widget.game.difficulty),
                      size: 14,
                      color: _getDifficultyColor(widget.game.difficulty),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getDifficultyLabel(widget.game.difficulty),
                      style: FamilyConnectTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      _getStatusIcon(widget.game.status),
                      size: 14,
                      color: _getStatusColor(widget.game.status),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getStatusLabel(widget.game.status),
                      style: FamilyConnectTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Badge de statut
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String badgeText;
    
    switch (widget.game.status) {
      case GameStatus.waiting:
        badgeColor = Colors.orange;
        badgeText = 'En attente';
        break;
      case GameStatus.playing:
        badgeColor = Colors.green;
        badgeText = 'En cours';
        break;
      case GameStatus.finished:
        badgeColor = Colors.blue;
        badgeText = 'Terminé';
        break;
      case GameStatus.paused:
        badgeColor = Colors.grey;
        badgeText = 'En pause';
        break;
      case GameStatus.cancelled:
        badgeColor = Colors.red;
        badgeText = 'Annulé';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        badgeText,
        style: FamilyConnectTheme.bodySmall.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            widget.game.description,
            style: FamilyConnectTheme.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Informations supplémentaires
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.game.timeLimit ~/ 60} min',
                style: FamilyConnectTheme.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.help_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.game.questions.length} questions',
                style: FamilyConnectTheme.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          
          if (widget.game.rewards.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Récompenses',
              style: FamilyConnectTheme.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.game.rewards.take(3).map((reward) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.game.defaultColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reward.title,
                    style: FamilyConnectTheme.bodySmall.copyWith(
                      color: widget.game.defaultColor,
                      fontSize: 10,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
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
          // Participants
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.game.participantIds.length}/${widget.game.maxParticipants}',
                  style: FamilyConnectTheme.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (widget.game.allowSpectators) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.visibility,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Spectateurs',
                      style: FamilyConnectTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Actions
          if (widget.showActions) ...[
            if (widget.game.status == GameStatus.waiting && widget.onJoin != null)
              ElevatedButton(
                onPressed: widget.onJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.game.defaultColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Rejoindre'),
              ),
            
            if (widget.game.status == GameStatus.waiting && widget.game.creatorId == 'temp_user_123' && widget.onStart != null)
              ElevatedButton(
                onPressed: widget.onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Démarrer'),
              ),
          ],
        ],
      ),
    );
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

  IconData _getDifficultyIcon(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return Icons.star_border;
      case GameDifficulty.medium:
        return Icons.star_half;
      case GameDifficulty.hard:
        return Icons.star;
      case GameDifficulty.expert:
        return Icons.grade;
    }
  }

  Color _getDifficultyColor(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return Colors.green;
      case GameDifficulty.medium:
        return Colors.orange;
      case GameDifficulty.hard:
        return Colors.red;
      case GameDifficulty.expert:
        return Colors.purple;
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

  IconData _getStatusIcon(GameStatus status) {
    switch (status) {
      case GameStatus.waiting:
        return Icons.schedule;
      case GameStatus.playing:
        return Icons.play_arrow;
      case GameStatus.paused:
        return Icons.pause;
      case GameStatus.finished:
        return Icons.check_circle;
      case GameStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(GameStatus status) {
    switch (status) {
      case GameStatus.waiting:
        return Colors.orange;
      case GameStatus.playing:
        return Colors.green;
      case GameStatus.paused:
        return Colors.grey;
      case GameStatus.finished:
        return Colors.blue;
      case GameStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusLabel(GameStatus status) {
    switch (status) {
      case GameStatus.waiting:
        return 'En attente';
      case GameStatus.playing:
        return 'En cours';
      case GameStatus.paused:
        return 'En pause';
      case GameStatus.finished:
        return 'Terminé';
      case GameStatus.cancelled:
        return 'Annulé';
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}

/// Widget pour afficher les statistiques de jeu
class GameStatsWidget extends StatelessWidget {
  final GameStats stats;
  final bool showDetails;

  const GameStatsWidget({
    super.key,
    required this.stats,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Statistiques de Jeu',
                style: FamilyConnectTheme.h4.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats principales
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Parties jouées',
                  stats.totalGamesPlayed.toString(),
                  Icons.sports_esports,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Victoires',
                  stats.totalGamesWon.toString(),
                  Icons.emoji_events,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Points totaux',
                  stats.totalPoints.toString(),
                  Icons.stars,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats secondaires
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Taux de victoire',
                  '${(stats.winRate * 100).toStringAsFixed(1)}%',
                  Icons.percent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Score moyen',
                  stats.averageScore.toStringAsFixed(0),
                  Icons.analytics,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Série actuelle',
                  stats.currentStreak.toString(),
                  Icons.local_fire_department,
                ),
              ),
            ],
          ),
          
          if (showDetails) ...[
            const SizedBox(height: 20),
            
            // Jeux par type
            Text(
              'Jeux par type',
              style: FamilyConnectTheme.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...stats.gamesByType.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      _getGameIcon(entry.key),
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getGameTypeLabel(entry.key),
                      style: FamilyConnectTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      entry.value.toString(),
                      style: FamilyConnectTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            const SizedBox(height: 16),
            
            // Badges et titres
            if (stats.badges.isNotEmpty) ...[
              Text(
                'Badges',
                style: FamilyConnectTheme.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: stats.badges.map((badge) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: FamilyConnectTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: FamilyConnectTheme.h4.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: FamilyConnectTheme.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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

  String _getGameTypeLabel(FamilyGameType type) {
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
}

/// Widget pour le leaderboard
class GameLeaderboardWidget extends StatelessWidget {
  final List<MapEntry<String, GameStats>> leaderboard;
  final String? currentUserId;

  const GameLeaderboardWidget({
    super.key,
    required this.leaderboard,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.leaderboard,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Classement',
                style: FamilyConnectTheme.h4.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Liste du leaderboard
          if (leaderboard.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun joueur dans le classement',
                      style: FamilyConnectTheme.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final entry = leaderboard[index];
                final stats = entry.value;
                final isCurrentUser = entry.key == currentUserId;
                final position = index + 1;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isCurrentUser 
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrentUser 
                        ? Border.all(color: Theme.of(context).colorScheme.primary)
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Position
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _getPositionColor(position),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              position.toString(),
                              style: FamilyConnectTheme.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Nom utilisateur
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Joueur ${entry.key.substring(0, 8)}...',
                                style: FamilyConnectTheme.bodyMedium.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              if (isCurrentUser)
                                Text(
                                  'Vous',
                                  style: FamilyConnectTheme.bodySmall.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Points
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              stats.totalPoints.toString(),
                              style: FamilyConnectTheme.h4.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'points',
                              style: FamilyConnectTheme.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return const Color(0xFF6366F1); // Primary color
    }
  }
}

/// Indicateur de chargement pour les jeux
class GameLoadingIndicator extends StatefulWidget {
  const GameLoadingIndicator({super.key});

  @override
  State<GameLoadingIndicator> createState() => _GameLoadingIndicatorState();
}

class _GameLoadingIndicatorState extends State<GameLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      FamilyConnectTheme.primaryColor.withValues(alpha: _animation.value),
                      FamilyConnectTheme.secondaryColor.withValues(alpha: _animation.value),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sports_esports,
                  color: Colors.white,
                  size: 30,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement des jeux...',
            style: FamilyConnectTheme.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
