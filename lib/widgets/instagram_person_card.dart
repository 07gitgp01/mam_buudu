import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/family_connect_theme.dart';
import '../models/personne.dart';
import '../models/date_partielle.dart';

/// Person cards animées style Instagram avec micro-interactions
/// Effet parallax, swipe actions, animations fluides
class InstagramPersonCard extends StatefulWidget {
  final Personne personne;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final bool showActions;
  final bool enableSwipe;

  const InstagramPersonCard({
    super.key,
    required this.personne,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onShare,
    this.showActions = true,
    this.enableSwipe = true,
  });

  @override
  State<InstagramPersonCard> createState() => _InstagramPersonCardState();
}

class _InstagramPersonCardState extends State<InstagramPersonCard>
    with TickerProviderStateMixin {
  
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _glowAnimation;
  
  bool _isPressed = false;
  bool _isSwiped = false;
  double _dragOffset = 0.0;
  
  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: FamilyConnectTheme.fastDuration,
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: FamilyConnectTheme.normalDuration,
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: FamilyConnectTheme.defaultCurve,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.3, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: FamilyConnectTheme.defaultCurve,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    // Animation d'entrée initiale
    _glowController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    super.dispose();
  }
  
  void _onTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    setState(() {
      _isPressed = true;
    });
    _scaleController.forward();
  }
  
  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();
    
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }
  
  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();
  }
  
  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enableSwipe) return;
    
    setState(() {
      _dragOffset += details.delta.dx;
      _dragOffset = _dragOffset.clamp(-100.0, 100.0);
    });
  }
  
  void _onPanEnd(DragEndDetails details) {
    if (!widget.enableSwipe) return;
    
    final velocity = details.velocity.pixelsPerSecond.dx;
    
    if (velocity > 300) {
      // Swipe vers la droite - action positive
      _handleSwipeRight();
    } else if (velocity < -300) {
      // Swipe vers la gauche - action négative
      _handleSwipeLeft();
    } else {
      // Retour à la position initiale
      setState(() {
        _dragOffset = 0.0;
      });
    }
  }
  
  void _handleSwipeRight() {
    HapticFeedback.mediumImpact();
    if (widget.onShare != null) {
      widget.onShare!();
    }
    setState(() {
      _dragOffset = 0.0;
    });
  }
  
  void _handleSwipeLeft() {
    HapticFeedback.mediumImpact();
    if (widget.onEdit != null) {
      widget.onEdit!();
    }
    setState(() {
      _dragOffset = 0.0;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _glowAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: FamilyConnectTheme.radiusLg,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: 0.1 * _glowAnimation.value,
                    ),
                    blurRadius: 20 * _glowAnimation.value,
                    spreadRadius: 2 * _glowAnimation.value,
                  ),
                  ...FamilyConnectTheme.shadowMd,
                ],
              ),
              child: Material(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: FamilyConnectTheme.radiusLg,
                child: GestureDetector(
                  onTapDown: _onTapDown,
                  onTapUp: _onTapUp,
                  onTapCancel: _onTapCancel,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: Stack(
                    children: [
                      // Swipe actions background
                      if (widget.enableSwipe)
                        _buildSwipeActions(),
                      
                      // Main card content
                      Transform.translate(
                        offset: Offset(_dragOffset, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: FamilyConnectTheme.radiusLg,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).colorScheme.surfaceVariant,
                                Theme.of(context).colorScheme.surface,
                              ],
                            ),
                          ),
                          child: _buildCardContent(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSwipeActions() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: FamilyConnectTheme.radiusLg,
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              FamilyConnectTheme.successColor.withValues(alpha: 0.8),
              FamilyConnectTheme.primaryColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Action gauche (Partager)
            Container(
              width: 80,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                color: FamilyConnectTheme.successColor.withValues(alpha: 0.8),
              ),
              child: const Icon(
                Icons.share,
                color: Colors.white,
                size: 28,
              ),
            ),
            
            // Action droite (Modifier)
            Container(
              width: 80,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                color: FamilyConnectTheme.primaryColor.withValues(alpha: 0.8),
              ),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCardContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec avatar et actions
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPersonInfo(),
              ),
              if (widget.showActions)
                _buildActionMenu(),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Description/Stats
          _buildPersonStats(),
          
          const SizedBox(height: 12),
          
          // Actions bar
          _buildActionBar(),
        ],
      ),
    );
  }
  
  Widget _buildAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: FamilyConnectTheme.primaryGradient,
        borderRadius: FamilyConnectTheme.radiusFull,
        boxShadow: FamilyConnectTheme.shadowSm,
      ),
      child: Stack(
        children: [
          if (widget.personne.photoPath != null &&
              File(widget.personne.photoPath!).existsSync())
            ClipRRect(
              borderRadius: FamilyConnectTheme.radiusFull,
              child: Image.file(
                File(widget.personne.photoPath!),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            )
          else
            Center(
              child: Text(
                _getInitials(widget.personne.nomComplet),
                style: FamilyConnectTheme.h4.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          
          // Badge de statut
          if (widget.personne.dateDeces != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: FamilyConnectTheme.errorColor,
                  borderRadius: FamilyConnectTheme.radiusFull,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildPersonInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.personne.nomComplet,
          style: FamilyConnectTheme.h4.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        _buildPersonDetails(),
      ],
    );
  }
  
  Widget _buildPersonDetails() {
    final List<String> details = [];
    
    if (widget.personne.dateNaissance != null) {
      final age = _calculateAge(widget.personne.dateNaissance!);
      details.add('$age ans');
    }
    
    if (widget.personne.lieuNaissance != null &&
        widget.personne.lieuNaissance!.isNotEmpty) {
      details.add(widget.personne.lieuNaissance!);
    }
    
    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 14,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            details.join(' · '),
            style: FamilyConnectTheme.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPersonStats() {
    final stats = <String, int>{};
    
    // Simuler des statistiques
    stats['Photos'] = widget.personne.photoPath != null ? 1 : 0;
    stats['Documents'] = 2; // Simulé
    stats['Relations'] = 5; // Simulé
    
    return Row(
      children: stats.entries.map((entry) {
        return Expanded(
          child: _buildStatItem(entry.key, entry.value),
        );
      }).toList(),
    );
  }
  
  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          '$value',
          style: FamilyConnectTheme.h3.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: FamilyConnectTheme.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionMenu() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      color: Theme.of(context).colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: FamilyConnectTheme.radiusMd,
      ),
      onSelected: (value) {
        HapticFeedback.lightImpact();
        switch (value) {
          case 'edit':
            if (widget.onEdit != null) widget.onEdit!();
            break;
          case 'delete':
            if (widget.onDelete != null) widget.onDelete!();
            break;
          case 'share':
            if (widget.onShare != null) widget.onShare!();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Modifier',
                style: FamilyConnectTheme.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(
                Icons.share,
                size: 20,
                color: FamilyConnectTheme.successColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Partager',
                style: FamilyConnectTheme.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete,
                size: 20,
                color: FamilyConnectTheme.errorColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Supprimer',
                style: FamilyConnectTheme.bodyMedium.copyWith(
                  color: FamilyConnectTheme.errorColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: FamilyConnectTheme.radiusSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            icon: Icons.favorite_border,
            label: 'Aimer',
            onTap: () {
              HapticFeedback.lightImpact();
              // Action liker
            },
          ),
          _buildActionButton(
            icon: Icons.comment_outlined,
            label: 'Commenter',
            onTap: () {
              HapticFeedback.lightImpact();
              // Action commenter
            },
          ),
          _buildActionButton(
            icon: Icons.share_outlined,
            label: 'Partager',
            onTap: widget.onShare,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: FamilyConnectTheme.radiusSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: FamilyConnectTheme.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
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
  
  String _calculateAge(DatePartielle birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.annee;
    
    // Ajuster l'âge si l'anniversaire n'est pas encore passé
    if (birthDate.mois != null && birthDate.mois! > now.month) {
      age--;
    } else if (birthDate.mois == now.month && 
               birthDate.jour != null && 
               birthDate.jour! > now.day) {
      age--;
    }
    
    if (age < 0) return 'À naître';
    if (age == 0) return '< 1 an';
    if (age == 1) return '1 an';
    return '$age ans';
  }
}
