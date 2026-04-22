import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/family_connect_theme.dart';
import '../models/family_reward.dart';
import '../services/family_reward_service.dart';

/// Carte de récompense pour la liste des récompenses
class FamilyRewardCard extends StatefulWidget {
  final FamilyReward reward;
  final UserRewardInventory? inventory;
  final VoidCallback? onTap;
  final VoidCallback? onClaim;
  final bool showProgress;

  const FamilyRewardCard({
    super.key,
    required this.reward,
    this.inventory,
    this.onTap,
    this.onClaim,
    this.showProgress = true,
  });

  @override
  State<FamilyRewardCard> createState() => _FamilyRewardCardState();
}

class _FamilyRewardCardState extends State<FamilyRewardCard>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.ease),
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );
    
    if (widget.showProgress) {
      _progressController.forward();
    }
    
    // Animation de shimmer pour les récompenses mythiques
    if (widget.reward.rarity == RewardRarity.mythic) {
      _shimmerController.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = widget.inventory?.isRewardUnlocked(widget.reward.id) ?? false;
    final isClaimed = widget.inventory?.isRewardClaimed(widget.reward.id) ?? false;
    final canClaim = widget.reward.canClaim && isUnlocked && !isClaimed;
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: isUnlocked 
              ? Border.all(color: widget.reward.rarityColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Shimmer effect pour les récompenses mythiques
            if (widget.reward.rarity == RewardRarity.mythic)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedBuilder(
                    animation: _shimmerAnimation,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(-1.0 + _shimmerAnimation.value, 0),
                            end: Alignment(1.0 + _shimmerAnimation.value, 0),
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            
            // Contenu principal
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header avec icône et rareté
                  Row(
                    children: [
                      // Icône de la récompense
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: widget.reward.rarityColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.reward.rarityColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Icon(
                                _getRewardIcon(widget.reward.type),
                                color: widget.reward.rarityColor,
                                size: 30,
                              ),
                            ),
                            if (isClaimed)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Informations
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.reward.name,
                              style: FamilyConnectTheme.h4.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.reward.description,
                              style: FamilyConnectTheme.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Badge de rareté
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: widget.reward.rarityColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getRarityLabel(widget.reward.rarity),
                                    style: FamilyConnectTheme.bodySmall.copyWith(
                                      color: widget.reward.rarityColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(width: 8),
                                
                                // Badge de catégorie
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _getCategoryLabel(widget.reward.category),
                                    style: FamilyConnectTheme.bodySmall.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Statut
                      _buildStatusBadge(isUnlocked, isClaimed, canClaim),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Progression
                  if (widget.showProgress && !isUnlocked)
                    _buildProgressBar(),
                  
                  // Valeur
                  if (widget.reward.type == RewardType.points)
                    _buildPointsValue(),
                  
                  // Actions
                  if (canClaim && widget.onClaim != null)
                    _buildClaimButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isUnlocked, bool isClaimed, bool canClaim) {
    Color badgeColor;
    String badgeText;
    
    if (isClaimed) {
      badgeColor = Colors.green;
      badgeText = 'Réclamé';
    } else if (isUnlocked) {
      badgeColor = Colors.orange;
      badgeText = 'Disponible';
    } else {
      badgeColor = Colors.grey;
      badgeText = 'Verrouillé';
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

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progression',
              style: FamilyConnectTheme.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Text(
              widget.reward.progressDescription,
              style: FamilyConnectTheme.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Container(
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: widget.reward.progressPercentage * _progressAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.reward.rarityColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPointsValue() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.stars,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '+${widget.reward.value} points',
            style: FamilyConnectTheme.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimButton() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.onClaim,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.reward.rarityColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, size: 18),
            const SizedBox(width: 8),
            Text('Réclamer'),
          ],
        ),
      ),
    );
  }

  IconData _getRewardIcon(RewardType type) {
    switch (type) {
      case RewardType.points:
        return Icons.stars;
      case RewardType.badge:
        return Icons.emoji_events;
      case RewardType.title:
        return Icons.military_tech;
      case RewardType.avatar:
        return Icons.face;
      case RewardType.feature:
        return Icons.lock_open;
      case RewardType.theme:
        return Icons.palette;
      case RewardType.emoji:
        return Icons.sentiment_satisfied_alt;
      case RewardType.frame:
        return Icons.crop_square;
    }
  }

  String _getRarityLabel(RewardRarity rarity) {
    switch (rarity) {
      case RewardRarity.common:
        return 'Commun';
      case RewardRarity.rare:
        return 'Rare';
      case RewardRarity.epic:
        return 'Épique';
      case RewardRarity.legendary:
        return 'Légendaire';
      case RewardRarity.mythic:
        return 'Mythique';
    }
  }

  String _getCategoryLabel(RewardCategory category) {
    switch (category) {
      case RewardCategory.gaming:
        return 'Gaming';
      case RewardCategory.family:
        return 'Famille';
      case RewardCategory.stories:
        return 'Stories';
      case RewardCategory.timeline:
        return 'Timeline';
      case RewardCategory.engagement:
        return 'Engagement';
      case RewardCategory.special:
        return 'Spécial';
      case RewardCategory.achievement:
        return 'Achievement';
      case RewardCategory.milestone:
        return 'Jalon';
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _progressController.dispose();
    super.dispose();
  }
}

/// Widget pour afficher les statistiques de récompenses
class RewardStatsWidget extends StatelessWidget {
  final UserRewardInventory inventory;
  final List<FamilyReward> allRewards;

  const RewardStatsWidget({
    super.key,
    required this.inventory,
    required this.allRewards,
  });

  @override
  Widget build(BuildContext context) {
    final unlockedRewards = allRewards.where((r) => 
        inventory.isRewardUnlocked(r.id)).toList();
    final claimedRewards = allRewards.where((r) => 
        inventory.isRewardClaimed(r.id)).toList();
    
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
                'Mes Récompenses',
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
                  'Points totaux',
                  inventory.totalPoints.toString(),
                  Icons.stars,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Débloquées',
                  unlockedRewards.length.toString(),
                  Icons.lock_open,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Réclamées',
                  claimedRewards.length.toString(),
                  Icons.card_giftcard,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Récompenses par rareté
          _buildRarityBreakdown(unlockedRewards),
          
          const SizedBox(height: 16),
          
          // Badges équipés
          if (inventory.equippedBadges.isNotEmpty)
            _buildEquippedBadges(),
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

  Widget _buildRarityBreakdown(List<FamilyReward> rewards) {
    final rarityCounts = <RewardRarity, int>{};
    for (final reward in rewards) {
      rarityCounts[reward.rarity] = (rarityCounts[reward.rarity] ?? 0) + 1;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Récompenses par rareté',
          style: FamilyConnectTheme.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: RewardRarity.values.map((rarity) {
            final count = rarityCounts[rarity] ?? 0;
            if (count == 0) return const SizedBox.shrink();
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRarityColor(rarity).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getRarityLabel(rarity),
                    style: FamilyConnectTheme.bodySmall.copyWith(
                      color: _getRarityColor(rarity),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    count.toString(),
                    style: FamilyConnectTheme.bodySmall.copyWith(
                      color: _getRarityColor(rarity),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEquippedBadges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Badges équipés',
          style: FamilyConnectTheme.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: inventory.equippedBadges.map((badgeId) {
            final reward = allRewards.firstWhere((r) => r.id == badgeId);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: reward.rarityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                reward.name,
                style: FamilyConnectTheme.bodySmall.copyWith(
                  color: reward.rarityColor,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getRarityColor(RewardRarity rarity) {
    switch (rarity) {
      case RewardRarity.common:
        return const Color(0xFF4CAF50);
      case RewardRarity.rare:
        return const Color(0xFF2196F3);
      case RewardRarity.epic:
        return const Color(0xFF9C27B0);
      case RewardRarity.legendary:
        return const Color(0xFFFF9800);
      case RewardRarity.mythic:
        return const Color(0xFFF44336);
    }
  }

  String _getRarityLabel(RewardRarity rarity) {
    switch (rarity) {
      case RewardRarity.common:
        return 'Commun';
      case RewardRarity.rare:
        return 'Rare';
      case RewardRarity.epic:
        return 'Épique';
      case RewardRarity.legendary:
        return 'Légendaire';
      case RewardRarity.mythic:
        return 'Mythique';
    }
  }
}

/// Widget pour le leaderboard des récompenses
class RewardLeaderboardWidget extends StatelessWidget {
  final List<MapEntry<String, int>> leaderboard;
  final String? currentUserId;

  const RewardLeaderboardWidget({
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
                'Classement des Points',
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
                final entry = leaderboard.elementAt(index);
                final position = index + 1;
                final isCurrentUser = entry.key == currentUserId;
                
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
                              entry.value.toString(),
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

/// Indicateur de chargement pour les récompenses
class RewardLoadingIndicator extends StatefulWidget {
  const RewardLoadingIndicator({super.key});

  @override
  State<RewardLoadingIndicator> createState() => _RewardLoadingIndicatorState();
}

class _RewardLoadingIndicatorState extends State<RewardLoadingIndicator>
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
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 30,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement des récompenses...',
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

/// Widget pour les notifications de récompenses
class RewardNotificationWidget extends StatelessWidget {
  final RewardNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;

  const RewardNotificationWidget({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.isRead 
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: notification.isRead 
            ? Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2))
            : Border.all(color: Theme.of(context).colorScheme.primary),
      ),
      child: Row(
        children: [
          // Icône
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: FamilyConnectTheme.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: FamilyConnectTheme.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(notification.createdAt),
                  style: FamilyConnectTheme.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          if (!notification.isRead)
            GestureDetector(
              onTap: onMarkAsRead,
              child: Icon(
                Icons.mark_email_read,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(RewardNotificationType type) {
    switch (type) {
      case RewardNotificationType.unlocked:
        return Icons.lock_open;
      case RewardNotificationType.claimed:
        return Icons.card_giftcard;
      case RewardNotificationType.expired:
        return Icons.access_time;
      case RewardNotificationType.available:
        return Icons.new_releases;
      case RewardNotificationType.progress:
        return Icons.trending_up;
      case RewardNotificationType.milestone:
        return Icons.flag;
      case RewardNotificationType.bonus:
        return Icons.stars;
      case RewardNotificationType.reminder:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays}j';
    }
  }
}
