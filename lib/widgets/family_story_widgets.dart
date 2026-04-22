import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/family_connect_theme.dart';
import '../models/family_story.dart';
import '../services/family_story_service.dart';

/// Widget pour afficher un cercle de story dans la barre des stories
class StoryCircle extends StatelessWidget {
  final FamilyStory story;
  final VoidCallback onTap;
  final double size;
  final bool showRing;

  const StoryCircle({
    super.key,
    required this.story,
    required this.onTap,
    this.size = 70,
    this.showRing = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Stack(
          children: [
            // Anneau extérieur
            if (showRing)
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: story.isViewed
                      ? LinearGradient(
                          colors: [
                            Colors.grey.withValues(alpha: 0.3),
                            Colors.grey.withValues(alpha: 0.3),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            FamilyConnectTheme.primaryColor,
                            FamilyConnectTheme.secondaryColor,
                          ],
                        ),
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
            
            // Image de la story
            Positioned.fill(
              child: Container(
                margin: EdgeInsets.all(showRing ? 6 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                child: ClipOval(
                  child: _buildStoryMedia(context),
                ),
              ),
            ),
            
            // Indicateur de temps restant
            if (story.isExpiringSoon)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.timer,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryMedia(BuildContext context) {
    if (story.mediaType == StoryMediaType.photo) {
      return Image.file(
        File(story.mediaUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Icon(
              Icons.broken_image,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          );
        },
      );
    } else {
      return Container(
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: Icon(
          Icons.videocam,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      );
    }
  }
}

/// Widget pour créer une nouvelle story (bouton +)
class CreateStoryCircle extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const CreateStoryCircle({
    super.key,
    required this.onTap,
    this.size = 70,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Stack(
          children: [
            // Anneau extérieur
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
            
            // Bouton +
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barre horizontale des stories
class StoriesBar extends StatefulWidget {
  final List<FamilyStory> stories;
  final Function(FamilyStory) onStoryTap;
  final VoidCallback onCreateStory;

  const StoriesBar({
    super.key,
    required this.stories,
    required this.onStoryTap,
    required this.onCreateStory,
  });

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.stories.length + 1, // +1 pour le bouton de création
        itemBuilder: (context, index) {
          if (index == 0) {
            return CreateStoryCircle(
              onTap: widget.onCreateStory,
            );
          }
          
          final story = widget.stories[index - 1];
          return StoryCircle(
            story: story,
            onTap: () => widget.onStoryTap(story),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

/// Écran de visualisation d'une story
class StoryViewer extends StatefulWidget {
  final List<FamilyStory> stories;
  final int initialIndex;
  final VoidCallback? onClose;

  const StoryViewer({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    this.onClose,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late AnimationController _fadeController;
  int _currentIndex = 0;
  bool _showReactions = false;
  bool _showComments = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    
    _progressController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _startProgressAnimation();
  }

  void _startProgressAnimation() {
    _progressController.reset();
    _progressController.forward().then((_) {
      if (mounted && _currentIndex < widget.stories.length - 1) {
        _nextStory();
      } else {
        _closeStory();
      }
    });
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startProgressAnimation();
    } else {
      _closeStory();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startProgressAnimation();
    }
  }

  void _closeStory() {
    widget.onClose?.call();
    Navigator.pop(context);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _startProgressAnimation();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Aucune story disponible',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    final currentStory = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Contenu de la story
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.stories.length,
            itemBuilder: (context, index) {
              final story = widget.stories[index];
              return _buildStoryContent(story);
            },
          ),
          
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Barre de progression
                  Row(
                    children: List.generate(
                      widget.stories.length,
                      (index) => Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: index == _currentIndex 
                                ? _progressController.value 
                                : (index < _currentIndex ? 1.0 : 0.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Infos utilisateur
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        child: currentStory.creatorAvatar != null
                            ? ClipOval(
                                child: Image.file(
                                  File(currentStory.creatorAvatar!),
                                  fit: BoxFit.cover,
                                  width: 40,
                                  height: 40,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.person,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentStory.creatorName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _formatTimeRemaining(currentStory.timeRemaining),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _closeStory,
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Actions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Caption
                  if (currentStory.caption.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        currentStory.caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  
                  // Barre d'actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Réactions
                      GestureDetector(
                        onTap: () => _toggleReactions(),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_border,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      
                      // Commentaires
                      GestureDetector(
                        onTap: () => _toggleComments(),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      
                      // Partager
                      GestureDetector(
                        onTap: () => _shareStory(currentStory),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.share,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Overlay réactions
          if (_showReactions)
            _buildReactionsOverlay(currentStory),
          
          // Overlay commentaires
          if (_showComments)
            _buildCommentsOverlay(currentStory),
        ],
      ),
    );
  }

  Widget _buildStoryContent(FamilyStory story) {
    if (story.mediaType == StoryMediaType.photo) {
      return Image.file(
        File(story.mediaUrl),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.videocam,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Vidéo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildReactionsOverlay(FamilyStory story) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Réagir',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: StoryReactions.availableEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = StoryReactions.availableEmojis[index];
                  return GestureDetector(
                    onTap: () => _addReaction(story, emoji),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => _toggleReactions(),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsOverlay(FamilyStory story) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _toggleComments(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Commentaires',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Pour équilibrer avec le bouton back
                ],
              ),
            ),
            
            // Liste des commentaires
            Expanded(
              child: story.comments.isEmpty
                  ? Center(
                      child: Text(
                        'Soyez le premier à commenter !',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: story.comments.length,
                      itemBuilder: (context, index) {
                        final comment = story.comments[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment.content,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimeAgo(comment.createdAt),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            
            // Champ de saisie
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ajouter un commentaire...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Colors.white,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _toggleComments(),
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleReactions() {
    setState(() {
      _showReactions = !_showReactions;
      _showComments = false;
    });
  }

  void _toggleComments() {
    setState(() {
      _showComments = !_showComments;
      _showReactions = false;
    });
  }

  void _addReaction(FamilyStory story, String emoji) async {
    final storyService = FamilyStoryService();
    await storyService.addReaction(story.id, emoji);
    _toggleReactions();
  }

  void _addComment(FamilyStory story, String content) async {
    final storyService = FamilyStoryService();
    await storyService.addComment(story.id, content);
  }

  void _shareStory(FamilyStory story) {
    // Implémenter le partage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Partage bientôt disponible !'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.isNegative) return 'Expirée';
    
    if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}min';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
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

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}
