import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/family_connect_theme.dart';
import '../models/family_story.dart';
import '../services/family_story_service.dart';
import '../widgets/family_story_widgets.dart';

/// Écran principal des stories familiales
class FamilyStoriesScreen extends StatefulWidget {
  const FamilyStoriesScreen({super.key});

  @override
  State<FamilyStoriesScreen> createState() => _FamilyStoriesScreenState();
}

class _FamilyStoriesScreenState extends State<FamilyStoriesScreen> {
  final FamilyStoryService _storyService = FamilyStoryService();
  List<FamilyStory> _stories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeStories();
  }

  Future<void> _initializeStories() async {
    try {
      // Initialiser le service
      await _storyService.initialize();
      
      // Écouter les changements
      _storyService.storiesStream.listen((stories) {
        if (mounted) {
          setState(() {
            _stories = stories;
            _isLoading = false;
          });
        }
      });
      
      // Timeout de sécurité
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
            _stories = [];
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _stories = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des stories: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Stories Familiales'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showStats,
            icon: const Icon(Icons.bar_chart),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stories.isEmpty
              ? _buildEmptyState()
              : _buildStoriesContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.photo_camera_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune story pour le moment',
            style: FamilyConnectTheme.h4.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Soyez le premier à partager un moment !',
            style: FamilyConnectTheme.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateStoryOptions,
            icon: const Icon(Icons.add),
            label: const Text('Créer une story'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: FamilyConnectTheme.radiusLg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesContent() {
    return RefreshIndicator(
      onRefresh: _refreshStories,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Barre des stories
            StoriesBar(
              stories: _stories,
              onStoryTap: _viewStory,
              onCreateStory: _showCreateStoryOptions,
            ),
            
            const SizedBox(height: 20),
            
            // Liste des stories avec détails
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stories récentes',
                    style: FamilyConnectTheme.h3.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _stories.length,
                    itemBuilder: (context, index) {
                      final story = _stories[index];
                      return _buildStoryCard(story);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(FamilyStory story) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: FamilyConnectTheme.radiusLg,
        boxShadow: FamilyConnectTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: story.creatorAvatar != null
                      ? ClipOval(
                          child: Image.file(
                            File(story.creatorAvatar!),
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
                        story.creatorName,
                        style: FamilyConnectTheme.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatTimeAgo(story.createdAt),
                        style: FamilyConnectTheme.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (story.isExpiringSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Expiré bientôt',
                      style: FamilyConnectTheme.bodySmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Média
          GestureDetector(
            onTap: () => _viewStory(story),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              child: _buildStoryMedia(story),
            ),
          ),
          
          // Caption
          if (story.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                story.caption,
                style: FamilyConnectTheme.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Réactions
                Row(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${story.reactions.length}',
                      style: FamilyConnectTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 24),
                
                // Commentaires
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${story.comments.length}',
                      style: FamilyConnectTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Vues
                Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 20,
                      color: story.isViewed 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${story.viewCount}',
                      style: FamilyConnectTheme.bodySmall.copyWith(
                        color: story.isViewed 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryMedia(FamilyStory story) {
    if (story.mediaType == StoryMediaType.photo) {
      return Image.file(
        File(story.mediaUrl),
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
    } else {
      return Container(
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Vidéo',
              style: FamilyConnectTheme.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
  }

  void _viewStory(FamilyStory story) async {
    // Marquer la story comme vue
    await _storyService.markStoryAsViewed(story.id);
    
    // Ouvrir le visualisateur de stories
    final unviewedStories = _storyService.getUnviewedStories();
    final allStories = [...unviewedStories, ..._stories.where((s) => s.isViewed)];
    
    final initialIndex = allStories.indexWhere((s) => s.id == story.id);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewer(
          stories: allStories,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _showCreateStoryOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCreateStoryBottomSheet(),
    );
  }

  Widget _buildCreateStoryBottomSheet() {
    return Container(
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
                    'Créer une story',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // Pour équilibrer
              ],
            ),
          ),
          
          // Options
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Photo depuis la caméra
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FamilyConnectTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: FamilyConnectTheme.primaryColor,
                    ),
                  ),
                  title: const Text('Photo'),
                  subtitle: const Text('Prendre une nouvelle photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
                
                // Vidéo depuis la caméra
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FamilyConnectTheme.secondaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.videocam,
                      color: FamilyConnectTheme.secondaryColor,
                    ),
                  ),
                  title: const Text('Vidéo'),
                  subtitle: const Text('Enregistrer une nouvelle vidéo'),
                  onTap: () {
                    Navigator.pop(context);
                    _recordVideo();
                  },
                ),
                
                // Photo depuis la galerie
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: Colors.orange,
                    ),
                  ),
                  title: const Text('Galerie'),
                  subtitle: const Text('Choisir une photo existante'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickPhotoFromGallery();
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    final mediaUrl = await _storyService.takePhoto();
    if (mediaUrl != null) {
      _navigateToStoryCreation(mediaUrl, StoryMediaType.photo);
    }
  }

  Future<void> _recordVideo() async {
    final mediaUrl = await _storyService.pickVideo();
    if (mediaUrl != null) {
      _navigateToStoryCreation(mediaUrl, StoryMediaType.video);
    }
  }

  Future<void> _pickPhotoFromGallery() async {
    final mediaUrl = await _storyService.pickPhotoFromGallery();
    if (mediaUrl != null) {
      _navigateToStoryCreation(mediaUrl, StoryMediaType.photo);
    }
  }

  void _navigateToStoryCreation(String mediaUrl, StoryMediaType mediaType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateStoryScreen(
          mediaUrl: mediaUrl,
          mediaType: mediaType,
        ),
      ),
    );
  }

  Future<void> _refreshStories() async {
    await _storyService.cleanupExpiredStories();
  }

  void _showStats() {
    final stats = _storyService.getStoryStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques des Stories'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stories actives: ${stats['activeStories']}'),
            Text('Vues totales: ${stats['totalViews']}'),
            Text('Réactions: ${stats['totalReactions']}'),
            Text('Commentaires: ${stats['totalComments']}'),
            Text('Vues moyennes: ${stats['averageViewsPerStory'].toStringAsFixed(1)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
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
}

/// Écran de création de story
class CreateStoryScreen extends StatefulWidget {
  final String mediaUrl;
  final StoryMediaType mediaType;

  const CreateStoryScreen({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
  });

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final FamilyStoryService _storyService = FamilyStoryService();
  final TextEditingController _captionController = TextEditingController();
  StoryFilter _selectedFilter = StoryFilter.none;
  StoryPrivacy _privacy = StoryPrivacy.family;
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Créer une story'),
        actions: [
          if (_isCreating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          else
            TextButton(
              onPressed: _createStory,
              child: const Text(
                'Partager',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Aperçu du média
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              child: _buildMediaPreview(),
            ),
          ),
          
          // Options de création
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Column(
              children: [
                // Caption
                TextField(
                  controller: _captionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ajouter une légende...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.white,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 3,
                ),
                
                const SizedBox(height: 16),
                
                // Filtres
                Row(
                  children: [
                    Text(
                      'Filtre:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: StoryFilter.values.map((filter) {
                            final isSelected = _selectedFilter == filter;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedFilter = filter),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _getFilterName(filter),
                                  style: TextStyle(
                                    color: isSelected ? Colors.black : Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Confidentialité
                Row(
                  children: [
                    Text(
                      'Visibilité:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: StoryPrivacy.values.map((privacy) {
                          final isSelected = _privacy == privacy;
                          return GestureDetector(
                            onTap: () => setState(() => _privacy = privacy),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _getPrivacyName(privacy),
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (widget.mediaType == StoryMediaType.photo) {
      return Image.file(
        File(widget.mediaUrl),
        fit: BoxFit.contain,
      );
    } else {
      return Container(
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Vidéo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _createStory() async {
    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter une légende'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // Appliquer le filtre si nécessaire
      final processedMediaUrl = await _storyService.applyFilter(
        widget.mediaUrl,
        _selectedFilter,
      );

      final story = await _storyService.createStory(
        mediaUrl: processedMediaUrl,
        mediaType: widget.mediaType,
        caption: _captionController.text.trim(),
        privacy: _privacy,
        filter: _selectedFilter,
      );

      if (story != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story créée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  String _getFilterName(StoryFilter filter) {
    switch (filter) {
      case StoryFilter.none:
        return 'Aucun';
      case StoryFilter.vintage:
        return 'Vintage';
      case StoryFilter.blackAndWhite:
        return 'NB';
      case StoryFilter.sepia:
        return 'Sépia';
      case StoryFilter.warm:
        return 'Chaud';
      case StoryFilter.cool:
        return 'Froid';
      case StoryFilter.familyGold:
        return 'Or Famille';
      case StoryFilter.nostalgia:
        return 'Nostalgie';
    }
  }

  String _getPrivacyName(StoryPrivacy privacy) {
    switch (privacy) {
      case StoryPrivacy.family:
        return 'Famille';
      case StoryPrivacy.custom:
        return 'Personnalisé';
      case StoryPrivacy.private:
        return 'Privé';
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }
}
