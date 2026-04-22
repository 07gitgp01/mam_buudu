import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/family_story.dart';
// import '../services/auth_service.dart'; // Service à créer plus tard

/// Service pour gérer les stories familiales temporaires
class FamilyStoryService {
  static final FamilyStoryService _instance = FamilyStoryService._internal();
  factory FamilyStoryService() => _instance;
  FamilyStoryService._internal();

  // TODO: Remplacer par le vrai AuthService quand disponible
  dynamic _authService; // AuthService temporaire
  final List<FamilyStory> _stories = [];
  final StreamController<List<FamilyStory>> _storiesController = 
      StreamController<List<FamilyStory>>.broadcast();
  
  List<FamilyStory> get stories => List.unmodifiable(_stories);
  Stream<List<FamilyStory>> get storiesStream => _storiesController.stream;

  /// Initialiser le service et charger les stories existantes
  Future<void> initialize() async {
    // Initialiser l'auth service temporaire
    _authService = _TempAuthService();
    await _loadStories();
    _startExpirationTimer();
    
    // S'assurer que le stream est notifié après l'initialisation
    _storiesController.add(_stories);
  }

  /// Charger toutes les stories depuis le stockage local
  Future<void> _loadStories() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final storiesFile = File(path.join(directory.path, 'family_stories.json'));
      
      _stories.clear();
      
      if (await storiesFile.exists()) {
        final content = await storiesFile.readAsString();
        
        if (content.isNotEmpty) {
          try {
            // Essayer de parser comme un JSON array
            final List<dynamic> storiesJson = [];
            final lines = content.split('\n').where((s) => s.isNotEmpty).toList();
            
            for (final line in lines) {
              try {
                // Parser chaque ligne comme JSON
                final Map<String, dynamic> storyJson = jsonDecode(line.trim()) as Map<String, dynamic>;
                storiesJson.add(storyJson);
              } catch (e) {
                debugPrint('Erreur parsing JSON line: $line, error: $e');
              }
            }
            
            for (final storyJson in storiesJson) {
              if (storyJson.isNotEmpty && storyJson is Map<String, dynamic>) {
                try {
                  debugPrint('Tentative parsing story: ${storyJson.keys}');
                  final story = FamilyStory.fromJson(storyJson);
                  if (!story.isExpired) {
                    _stories.add(story);
                    debugPrint('Story chargée avec succès: ${story.id}');
                  }
                } catch (e) {
                  debugPrint('ERREUR parsing story: $storyJson');
                  debugPrint('ERREUR details: $e');
                  debugPrint('ERREUR type: ${e.runtimeType}');
                }
              } else {
                debugPrint('StoryJson invalide: $storyJson (type: ${storyJson.runtimeType})');
              }
            }
            
            _stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          } catch (e) {
            debugPrint('Erreur parsing stories JSON: $e');
            // Si le parsing échoue, créer un fichier vide
            await storiesFile.writeAsString('');
          }
        }
      }
      
      debugPrint('Stories chargées: ${_stories.length}');
    } catch (e) {
      debugPrint('Erreur lors du chargement des stories: $e');
      _stories.clear();
    }
  }

  /// Sauvegarder les stories dans le stockage local
  Future<void> _saveStories() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final storiesFile = File(path.join(directory.path, 'family_stories.json'));
      
      // Utiliser un format JSON array correct
      final storiesJson = _stories.map((s) => s.toJson()).toList();
      final jsonString = storiesJson.map((s) => jsonEncode(s)).join('\n');
      
      await storiesFile.writeAsString(jsonString);
      debugPrint('Stories sauvegardées: ${_stories.length}');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des stories: $e');
    }
  }

  /// Créer une nouvelle story
  Future<FamilyStory?> createStory({
    required String mediaUrl,
    required StoryMediaType mediaType,
    required String caption,
    StoryPrivacy privacy = StoryPrivacy.family,
    List<String>? allowedViewerIds,
    StoryFilter filter = StoryFilter.none,
  }) async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final story = FamilyStory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        creatorId: currentUser.id,
        creatorName: currentUser.displayName ?? 'Utilisateur',
        creatorAvatar: currentUser.photoURL,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        caption: caption,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        viewerIds: [],
        allowedViewerIds: allowedViewerIds,
        privacy: privacy,
        filter: filter,
      );

      _stories.insert(0, story);
      await _saveStories();
      _storiesController.add(_stories);
      debugPrint('Story créée avec succès: ${story.id}');

      return story;
    } catch (e) {
      debugPrint('Erreur lors de la création de la story: $e');
      return null;
    }
  }

  /// Prendre une photo pour une story
  Future<String?> takePhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'story_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedFile = File(path.join(directory.path, fileName));
        
        await File(photo.path).copy(savedFile.path);
        return savedFile.path;
      }
    } catch (e) {
      debugPrint('Erreur lors de la prise de photo: $e');
    }
    return null;
  }

  /// Choisir une vidéo pour une story
  Future<String?> pickVideo() async {
    try {
      final picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 30),
      );

      if (video != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'story_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final savedFile = File(path.join(directory.path, fileName));
        
        await File(video.path).copy(savedFile.path);
        return savedFile.path;
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'enregistrement vidéo: $e');
    }
    return null;
  }

  /// Choisir une photo depuis la galerie
  Future<String?> pickPhotoFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'story_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedFile = File(path.join(directory.path, fileName));
        
        await File(photo.path).copy(savedFile.path);
        return savedFile.path;
      }
    } catch (e) {
      debugPrint('Erreur lors du choix de photo: $e');
    }
    return null;
  }

  /// Marquer une story comme vue
  Future<void> markStoryAsViewed(String storyId) async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) return;

      final storyIndex = _stories.indexWhere((s) => s.id == storyId);
      if (storyIndex == -1) return;

      final story = _stories[storyIndex];
      if (!story.viewerIds.contains(currentUser.id)) {
        final updatedStory = story.copyWith(
          viewerIds: [...story.viewerIds, currentUser.id],
          viewCount: story.viewCount + 1,
          isViewedByCurrentUser: true,
        );

        _stories[storyIndex] = updatedStory;
        await _saveStories();
        _storiesController.add(_stories);
      }
    } catch (e) {
      debugPrint('Erreur lors du marquage de la story comme vue: $e');
    }
  }

  /// Ajouter une réaction à une story
  Future<void> addReaction(String storyId, String emoji) async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) return;

      final storyIndex = _stories.indexWhere((s) => s.id == storyId);
      if (storyIndex == -1) return;

      final story = _stories[storyIndex];
      
      // Vérifier si l'utilisateur a déjà réagi
      final existingReaction = story.reactions
          .where((r) => r.userId == currentUser.id)
          .firstOrNull;

      List<StoryReaction> updatedReactions;
      if (existingReaction != null) {
        // Mettre à jour la réaction existante
        updatedReactions = story.reactions.map((r) {
          if (r.id == existingReaction.id) {
            return StoryReaction(
              id: r.id,
              storyId: r.storyId,
              userId: r.userId,
              userName: r.userName,
              emoji: emoji,
              createdAt: r.createdAt,
            );
          }
          return r;
        }).toList();
      } else {
        // Ajouter une nouvelle réaction
        final reaction = StoryReaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          storyId: storyId,
          userId: currentUser.id,
          userName: currentUser.displayName ?? 'Utilisateur',
          emoji: emoji,
          createdAt: DateTime.now(),
        );
        updatedReactions = [...story.reactions, reaction];
      }

      final updatedStory = story.copyWith(reactions: updatedReactions);
      _stories[storyIndex] = updatedStory;
      await _saveStories();
      _storiesController.add(_stories);
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de réaction: $e');
    }
  }

  /// Ajouter un commentaire à une story
  Future<void> addComment(String storyId, String content) async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) return;

      final storyIndex = _stories.indexWhere((s) => s.id == storyId);
      if (storyIndex == -1) return;

      final story = _stories[storyIndex];
      
      final comment = StoryComment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        storyId: storyId,
        userId: currentUser.id,
        userName: currentUser.displayName ?? 'Utilisateur',
        userAvatar: currentUser.photoURL,
        content: content,
        createdAt: DateTime.now(),
      );

      final updatedStory = story.copyWith(
        comments: [...story.comments, comment],
      );
      _stories[storyIndex] = updatedStory;
      await _saveStories();
      _storiesController.add(_stories);
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de commentaire: $e');
    }
  }

  /// Supprimer une story
  Future<void> deleteStory(String storyId) async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) return;

      final storyIndex = _stories.indexWhere((s) => s.id == storyId);
      if (storyIndex == -1) return;

      final story = _stories[storyIndex];
      if (story.creatorId != currentUser.id) {
        throw Exception('Seul le créateur peut supprimer sa story');
      }

      // Supprimer le fichier média
      try {
        final mediaFile = File(story.mediaUrl);
        if (await mediaFile.exists()) {
          await mediaFile.delete();
        }
      } catch (e) {
        debugPrint('Erreur lors de la suppression du fichier média: $e');
      }

      _stories.removeAt(storyIndex);
      await _saveStories();
      _storiesController.add(_stories);
    } catch (e) {
      debugPrint('Erreur lors de la suppression de la story: $e');
    }
  }

  /// Obtenir les stories non vues de l'utilisateur courant
  List<FamilyStory> getUnviewedStories() {
    return _stories.where((story) => !story.isViewed && !story.isExpired).toList();
  }

  /// Obtenir les stories créées par l'utilisateur courant
  Future<List<FamilyStory>> getMyStories() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) return [];

      return _stories
          .where((story) => story.creatorId == currentUser.id && !story.isExpired)
          .toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération de mes stories: $e');
      return [];
    }
  }

  /// Nettoyer les stories expirées
  Future<void> cleanupExpiredStories() async {
    try {
      final expiredStories = _stories.where((story) => story.isExpired).toList();
      
      for (final story in expiredStories) {
        // Supprimer les fichiers médias
        try {
          final mediaFile = File(story.mediaUrl);
          if (await mediaFile.exists()) {
            await mediaFile.delete();
          }
        } catch (e) {
          debugPrint('Erreur lors de la suppression du fichier média expiré: $e');
        }
      }

      _stories.removeWhere((story) => story.isExpired);
      await _saveStories();
      _storiesController.add(_stories);
    } catch (e) {
      debugPrint('Erreur lors du nettoyage des stories expirées: $e');
    }
  }

  /// Démarrer le timer pour nettoyer automatiquement les stories expirées
  void _startExpirationTimer() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      cleanupExpiredStories();
    });
  }

  /// Appliquer un filtre à une image (simulation)
  Future<String> applyFilter(String imagePath, StoryFilter filter) async {
    // Pour l'instant, retourne simplement le chemin original
    // Dans une version future, implémenter le traitement d'image réel
    return imagePath;
  }

  /// Obtenir les statistiques des stories
  Map<String, dynamic> getStoryStats() {
    final activeStories = _stories.where((s) => !s.isExpired).toList();
    final totalViews = activeStories.fold<int>(0, (sum, story) => sum + story.viewCount);
    final totalReactions = activeStories.fold<int>(0, (sum, story) => sum + story.reactions.length);
    final totalComments = activeStories.fold<int>(0, (sum, story) => sum + story.comments.length);

    return {
      'activeStories': activeStories.length,
      'totalViews': totalViews,
      'totalReactions': totalReactions,
      'totalComments': totalComments,
      'averageViewsPerStory': activeStories.isNotEmpty ? totalViews / activeStories.length : 0,
    };
  }

  /// Libérer les ressources
  void dispose() {
    _storiesController.close();
  }
}

/// Service d'authentification temporaire pour les stories
class _TempAuthService {
  Future<Map<String, dynamic>?> getCurrentUser() async {
    // TODO: Implémenter la vraie authentification
    // Pour l'instant, retourne un utilisateur fictif
    return {
      'id': 'temp_user_123',
      'displayName': 'Utilisateur Test',
      'photoURL': null,
    };
  }
}
