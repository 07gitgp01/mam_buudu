import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/family_connect_theme.dart';
import '../models/gamification.dart' as gam;
import '../services/gamification_service.dart';

/// Widget pour afficher le niveau de gamification
class LevelIndicator extends StatefulWidget {
  final gam.GameProfile profile;
  final bool showDetails;
  final double? width;

  const LevelIndicator({
    super.key,
    required this.profile,
    this.showDetails = true,
    this.width,
  });

  @override
  State<LevelIndicator> createState() => _LevelIndicatorState();
}

class _LevelIndicatorState extends State<LevelIndicator>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.profile.levelProgress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: FamilyConnectTheme.defaultCurve,
    ));
    
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.profile.currentLevel;
    
    return Container(
      width: widget.width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            level.color.withValues(alpha: 0.1),
            level.color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: FamilyConnectTheme.radiusLg,
        border: Border.all(
          color: level.color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec niveau
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [level.color, level.color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: FamilyConnectTheme.radiusFull,
                ),
                child: Icon(
                  level.icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.title,
                      style: FamilyConnectTheme.h4.copyWith(
                        color: level.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${widget.profile.totalPoints} points',
                      style: FamilyConnectTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.showDetails)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: level.color.withValues(alpha: 0.1),
                    borderRadius: FamilyConnectTheme.radiusFull,
                  ),
                  child: Text(
                    '+${widget.profile.pointsToNextLevel}',
                    style: FamilyConnectTheme.bodySmall.copyWith(
                      color: level.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          
          if (widget.showDetails) ...[
            const SizedBox(height: 16),
            
            // Barre de progression
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: FamilyConnectTheme.radiusFull,
                  ),
                  child: Stack(
                    children: [
                      // Progression
                      FractionallySizedBox(
                        widthFactor: _progressAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [level.color, level.color.withValues(alpha: 0.7)],
                            ),
                            borderRadius: FamilyConnectTheme.radiusFull,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 8),
            
            // Texte de progression
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Niveau ${gam.GameLevel.values.indexOf(level) + 1}',
                  style: FamilyConnectTheme.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  '${(widget.profile.levelProgress * 100).toInt()}%',
                  style: FamilyConnectTheme.bodySmall.copyWith(
                    color: level.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget pour afficher les badges
class BadgesGrid extends StatelessWidget {
  final List<String> unlockedBadgeIds;
  final bool showLocked;
  final Function(gam.Badge)? onBadgeTap;

  const BadgesGrid({
    super.key,
    required this.unlockedBadgeIds,
    this.showLocked = true,
    this.onBadgeTap,
  });

  @override
  Widget build(BuildContext context) {
    final allBadges = gam.BadgesCollection.allBadges;
    final unlockedBadges = gam.BadgesCollection.getUnlockedBadges(unlockedBadgeIds);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: showLocked ? allBadges.length : unlockedBadges.length,
      itemBuilder: (context, index) {
        final badge = showLocked 
            ? allBadges[index]
            : unlockedBadges[index];
        final isUnlocked = unlockedBadgeIds.contains(badge.id);
        
        return _BadgeCard(
          badge: badge,
          isUnlocked: isUnlocked,
          onTap: () => onBadgeTap?.call(badge),
        );
      },
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final gam.Badge badge;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const _BadgeCard({
    required this.badge,
    required this.isUnlocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUnlocked ? onTap : null,
        borderRadius: FamilyConnectTheme.radiusLg,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: isUnlocked
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      badge.color.withValues(alpha: 0.2),
                      badge.color.withValues(alpha: 0.1),
                    ],
                  )
                : null,
            color: isUnlocked 
                ? null 
                : Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: FamilyConnectTheme.radiusLg,
            border: Border.all(
              color: isUnlocked 
                  ? badge.color.withValues(alpha: 0.3)
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              width: isUnlocked ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône du badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: isUnlocked
                      ? LinearGradient(
                          colors: [badge.color, badge.color.withValues(alpha: 0.7)],
                        )
                      : LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                          ],
                        ),
                  borderRadius: FamilyConnectTheme.radiusFull,
                ),
                child: Icon(
                  _getBadgeIcon(badge.id),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Nom du badge
              Text(
                badge.title,
                style: FamilyConnectTheme.bodySmall.copyWith(
                  color: isUnlocked 
                      ? badge.color
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getBadgeIcon(String badgeId) {
    switch (badgeId) {
      case 'first_person':
        return Icons.person_add;
      case 'photo_master':
        return Icons.photo_camera;
      case 'union_creator':
        return Icons.favorite;
      case 'week_warrior':
        return Icons.calendar_today;
      case 'month_master':
        return Icons.emoji_events;
      case 'social_butterfly':
        return Icons.share;
      case 'commentator':
        return Icons.comment;
      case 'centurion':
        return Icons.military_tech;
      case 'millennium':
        return Icons.workspace_premium;
      default:
        return Icons.star;
    }
  }
}

/// Widget pour afficher la série de connexions
class StreakIndicator extends StatefulWidget {
  final int currentStreak;
  final int longestStreak;

  const StreakIndicator({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  State<StreakIndicator> createState() => _StreakIndicatorState();
}

class _StreakIndicatorState extends State<StreakIndicator>
    with TickerProviderStateMixin {
  
  late AnimationController _fireController;
  late Animation<double> _fireAnimation;

  @override
  void initState() {
    super.initState();
    _fireController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fireAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _fireController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.currentStreak > 0) {
      _fireController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _fireController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withValues(alpha: 0.1),
            Colors.red.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: FamilyConnectTheme.radiusLg,
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _fireAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _fireAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange, Colors.red],
                        ),
                        borderRadius: FamilyConnectTheme.radiusFull,
                      ),
                      child: const Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Série actuelle',
                      style: FamilyConnectTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      '${widget.currentStreak} jours',
                      style: FamilyConnectTheme.h4.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: FamilyConnectTheme.radiusFull,
                ),
                child: Text(
                  'Max: ${widget.longestStreak}',
                  style: FamilyConnectTheme.bodySmall.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher les points gagnés récemment
class PointsAnimation extends StatefulWidget {
  final int points;
  final String? description;

  const PointsAnimation({
    super.key,
    required this.points,
    this.description,
  });

  @override
  State<PointsAnimation> createState() => _PointsAnimationState();
}

class _PointsAnimationState extends State<PointsAnimation>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: -50.0,
      end: -100.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
    ));
    
    _controller.forward().then((_) {
      if (mounted) {
        Navigator.of(context).removeRoute(ModalRoute.of(context)!);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      right: 20 + _slideAnimation.value,
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.teal],
                ),
                borderRadius: FamilyConnectTheme.radiusLg,
                boxShadow: FamilyConnectTheme.shadowLg,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${widget.points}',
                    style: FamilyConnectTheme.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.description != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 20,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.description!,
                        style: FamilyConnectTheme.bodySmall.copyWith(
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Widget pour afficher les statistiques de gamification
class GamificationStats extends StatelessWidget {
  final gam.GameProfile profile;

  const GamificationStats({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: FamilyConnectTheme.radiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques',
            style: FamilyConnectTheme.h4.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          
          // Grid de statistiques
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _StatItem(
                icon: Icons.star,
                label: 'Points totaux',
                value: '${profile.totalPoints}',
                color: Colors.amber,
              ),
              _StatItem(
                icon: Icons.emoji_events,
                label: 'Badges',
                value: '${profile.unlockedBadges.length}',
                color: Colors.purple,
              ),
              _StatItem(
                icon: Icons.local_fire_department,
                label: 'Série',
                value: '${profile.currentStreak} jours',
                color: Colors.orange,
              ),
              _StatItem(
                icon: Icons.history,
                label: 'Actions',
                value: '${profile.actionCounts.values.fold(0, (a, b) => a + b)}',
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: FamilyConnectTheme.radiusMd,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: FamilyConnectTheme.radiusSm,
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: FamilyConnectTheme.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  value,
                  style: FamilyConnectTheme.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
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
