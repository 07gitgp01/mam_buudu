import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/family_connect_theme.dart';
import '../models/timeline_event.dart';
import '../services/timeline_service.dart';

/// Carte d'événement pour la timeline
class TimelineEventCard extends StatefulWidget {
  final TimelineEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(String)? onReact;
  final Function(String)? onComment;
  final bool showActions;

  const TimelineEventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onReact,
    this.onComment,
    this.showActions = true,
  });

  @override
  State<TimelineEventCard> createState() => _TimelineEventCardState();
}

class _TimelineEventCardState extends State<TimelineEventCard>
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
                  // Header avec icône et date
                  _buildHeader(),
                  
                  // Média si présent
                  if (widget.event.mediaUrls.isNotEmpty)
                    _buildMediaSection(),
                  
                  // Contenu principal
                  _buildContent(),
                  
                  // Actions sociales
                  if (widget.showActions)
                    _buildSocialActions(),
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
        color: widget.event.color?.withValues(alpha: 0.1) ?? 
               widget.event.defaultColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Icône de l'événement
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.event.color ?? widget.event.defaultColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconData(widget.event.icon ?? widget.event.defaultIcon),
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
                  widget.event.title,
                  style: FamilyConnectTheme.h4.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(widget.event.eventDate),
                      style: FamilyConnectTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    if (widget.event.location != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.event.location!,
                        style: FamilyConnectTheme.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Badge d'importance
          _buildImportanceBadge(),
        ],
      ),
    );
  }

  Widget _buildImportanceBadge() {
    Color badgeColor;
    String badgeText;
    
    switch (widget.event.importance) {
      case TimelineEventImportance.low:
        badgeColor = Colors.grey;
        badgeText = 'Faible';
        break;
      case TimelineEventImportance.medium:
        badgeColor = Colors.blue;
        badgeText = 'Moyenne';
        break;
      case TimelineEventImportance.high:
        badgeColor = Colors.orange;
        badgeText = 'Haute';
        break;
      case TimelineEventImportance.critical:
        badgeColor = Colors.red;
        badgeText = 'Critique';
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

  Widget _buildMediaSection() {
    return Container(
      height: 200,
      child: PageView.builder(
        itemCount: widget.event.mediaUrls.length,
        itemBuilder: (context, index) {
          final mediaUrl = widget.event.mediaUrls[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceVariant,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildMediaWidget(mediaUrl),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMediaWidget(String mediaUrl) {
    if (mediaUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: mediaUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Icon(
            Icons.broken_image,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    } else {
      return Image.file(
        File(mediaUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Icon(
              Icons.broken_image,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        },
      );
    }
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (widget.event.description.isNotEmpty)
            Text(
              widget.event.description,
              style: FamilyConnectTheme.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          
          const SizedBox(height: 12),
          
          // Tags
          if (widget.event.tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.event.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.event.color?.withValues(alpha: 0.1) ?? 
                           widget.event.defaultColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#$tag',
                    style: FamilyConnectTheme.bodySmall.copyWith(
                      color: widget.event.color ?? widget.event.defaultColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          
          const SizedBox(height: 12),
          
          // Participants
          if (widget.event.participantIds.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.event.participantIds.length} participant${widget.event.participantIds.length > 1 ? 's' : ''}',
                  style: FamilyConnectTheme.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSocialActions() {
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
          // Réactions
          GestureDetector(
            onTap: () => _showReactionsSheet(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  if (widget.event.reactions.isNotEmpty) ...[
                    Text(
                      _getTopReactionEmojis(),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    widget.event.reactions.length.toString(),
                    style: FamilyConnectTheme.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Commentaires
          GestureDetector(
            onTap: () => widget.onComment?.call(widget.event.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.event.comments.length.toString(),
                    style: FamilyConnectTheme.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const Spacer(),
          
          // Vues
          Row(
            children: [
              Icon(
                Icons.visibility,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                widget.event.viewCount.toString(),
                style: FamilyConnectTheme.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          
          if (widget.onEdit != null || widget.onDelete != null) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              itemBuilder: (context) => [
                if (widget.onEdit != null)
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 16),
                        const SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                if (widget.onDelete != null)
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    widget.onEdit?.call();
                    break;
                  case 'delete':
                    widget.onDelete?.call();
                    break;
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showReactionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                  const Expanded(
                    child: Text(
                      'Réagir',
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
            
            // Réactions disponibles
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _getAvailableReactions().map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      widget.onReact?.call(widget.event.id);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getTopReactionEmojis() {
    if (widget.event.reactions.isEmpty) return '';
    
    // Compter les réactions par emoji
    final reactionCounts = <String, int>{};
    for (final reaction in widget.event.reactions) {
      reactionCounts[reaction.emoji] = (reactionCounts[reaction.emoji] ?? 0) + 1;
    }
    
    // Trier par nombre et prendre les 3 premiers
    final sortedReactions = reactionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedReactions
        .take(3)
        .map((e) => e.key)
        .join('');
  }

  List<String> _getAvailableReactions() {
    return ['\u2764\ufe0f', '\ud83d\ude0d', '\ud83d\ude02', '\ud83d\ude2e', '\ud83d\ude22', '\ud83d\ude0a', '\ud83d\udd25', '\ud83c\udf89', '\ud83c\udf1f', '\ud83d\udc4d', '\ud83d\udc4e', '\ud83d\ude4c', '\ud83d\udcaa', '\ud83e\udd1d', '\ud83d\ude4f'];
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'baby_carriage': return Icons.child_care;
      case 'favorite': return Icons.favorite;
      case 'peace': return Icons.self_improvement;
      case 'cake': return Icons.cake;
      case 'school': return Icons.school;
      case 'work': return Icons.work;
      case 'flight': return Icons.flight;
      case 'emoji_events': return Icons.emoji_events;
      case 'groups': return Icons.groups;
      case 'event': return Icons.event;
      default: return Icons.event;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      return 'Il y a ${difference.inDays ~/ 7} semaines';
    } else if (difference.inDays < 365) {
      return 'Il y a ${difference.inDays ~/ 30} mois';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}

/// Filtre de timeline
class TimelineFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const TimelineFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<TimelineFilterChip> createState() => _TimelineFilterChipState();
}

class _TimelineFilterChipState extends State<TimelineFilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                widget.label,
                style: FamilyConnectTheme.bodySmall.copyWith(
                  color: widget.isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Indicateur de chargement pour la timeline
class TimelineLoadingIndicator extends StatefulWidget {
  const TimelineLoadingIndicator({super.key});

  @override
  State<TimelineLoadingIndicator> createState() => _TimelineLoadingIndicatorState();
}

class _TimelineLoadingIndicatorState extends State<TimelineLoadingIndicator>
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
                  Icons.timeline,
                  color: Colors.white,
                  size: 30,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement de la timeline...',
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
