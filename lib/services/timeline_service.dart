import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/timeline_event.dart';

/// Service pour gérer la timeline familiale interactive
class TimelineService {
  static final TimelineService _instance = TimelineService._internal();
  factory TimelineService() => _instance;
  TimelineService._internal();

  final List<TimelineEvent> _events = [];
  final StreamController<List<TimelineEvent>> _eventsController = 
      StreamController<List<TimelineEvent>>.broadcast();
  
  List<TimelineEvent> get events => List.unmodifiable(_events);
  Stream<List<TimelineEvent>> get eventsStream => _eventsController.stream;

  // Auth service temporaire
  dynamic _authService;

  /// Initialiser le service
  Future<void> initialize() async {
    _authService = _TempAuthService();
    await _loadEvents();
    _startAutoRefresh();
  }

  /// Charger tous les événements
  Future<void> _loadEvents() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final eventsFile = File(path.join(directory.path, 'timeline_events.json'));
      
      _events.clear();
      
      if (await eventsFile.exists()) {
        final content = await eventsFile.readAsString();
        
        if (content.isNotEmpty) {
          try {
            final lines = content.split('\n').where((s) => s.isNotEmpty).toList();
            
            for (final line in lines) {
              try {
                final Map<String, dynamic> eventJson = jsonDecode(line.trim()) as Map<String, dynamic>;
                final event = TimelineEvent.fromJson(eventJson);
                _events.add(event);
              } catch (e) {
                debugPrint('Erreur parsing event: $e');
              }
            }
            
            _events.sort((a, b) => b.eventDate.compareTo(a.eventDate));
            debugPrint('Timeline events chargés: ${_events.length}');
          } catch (e) {
            debugPrint('Erreur parsing timeline JSON: $e');
            await eventsFile.writeAsString('');
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des events: $e');
      _events.clear();
    }
  }

  /// Sauvegarder les événements
  Future<void> _saveEvents() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final eventsFile = File(path.join(directory.path, 'timeline_events.json'));
      
      final eventsJson = _events.map((e) => jsonEncode(e.toJson())).join('\n');
      await eventsFile.writeAsString(eventsJson);
      debugPrint('Timeline events sauvegardés: ${_events.length}');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des events: $e');
    }
  }

  /// Créer un nouvel événement
  Future<TimelineEvent?> createEvent({
    required String title,
    required String description,
    required TimelineEventType type,
    required DateTime eventDate,
    List<String> participantIds = const [],
    List<String> mediaUrls = const [],
    String? location,
    double? latitude,
    double? longitude,
    List<String> tags = const [],
    String? category,
    Color? color,
    String? icon,
    TimelineEventImportance importance = TimelineEventImportance.medium,
    TimelineEventVisibility visibility = TimelineEventVisibility.public,
    DateTime? endDate,
  }) async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        debugPrint('Utilisateur non connecté');
        return null;
      }

      final event = TimelineEvent(
        id: const Uuid().v4(),
        title: title,
        description: description,
        type: type,
        importance: importance,
        visibility: visibility,
        eventDate: eventDate,
        endDate: endDate,
        createdAt: DateTime.now(),
        participantIds: participantIds,
        creatorId: user['id'] as String,
        mediaUrls: mediaUrls,
        location: location,
        latitude: latitude,
        longitude: longitude,
        tags: tags,
        category: category,
        color: color,
        icon: icon,
      );

      _events.insert(0, event);
      await _saveEvents();
      _eventsController.add(_events);
      
      debugPrint('Timeline event créé: ${event.id}');
      return event;
    } catch (e) {
      debugPrint('Erreur lors de la création de l\'event: $e');
      return null;
    }
  }

  /// Mettre à jour un événement
  Future<bool> updateEvent(String eventId, {
    String? title,
    String? description,
    TimelineEventType? type,
    DateTime? eventDate,
    DateTime? endDate,
    List<String>? participantIds,
    List<String>? mediaUrls,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? tags,
    String? category,
    Color? color,
    String? icon,
    TimelineEventImportance? importance,
    TimelineEventVisibility? visibility,
  }) async {
    try {
      final index = _events.indexWhere((e) => e.id == eventId);
      if (index == -1) return false;

      final updatedEvent = _events[index].copyWith(
        title: title,
        description: description,
        type: type,
        eventDate: eventDate,
        endDate: endDate,
        participantIds: participantIds,
        mediaUrls: mediaUrls,
        location: location,
        latitude: latitude,
        longitude: longitude,
        tags: tags,
        category: category,
        color: color,
        icon: icon,
        importance: importance,
        visibility: visibility,
        updatedAt: DateTime.now(),
      );

      _events[index] = updatedEvent;
      await _saveEvents();
      _eventsController.add(_events);
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de l\'event: $e');
      return false;
    }
  }

  /// Supprimer un événement
  Future<bool> deleteEvent(String eventId) async {
    try {
      final index = _events.indexWhere((e) => e.id == eventId);
      if (index == -1) return false;

      _events.removeAt(index);
      await _saveEvents();
      _eventsController.add(_events);
      
      debugPrint('Timeline event supprimé: $eventId');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression de l\'event: $e');
      return false;
    }
  }

  /// Ajouter une réaction à un événement
  Future<bool> addReaction(String eventId, String emoji) async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) return false;

      final index = _events.indexWhere((e) => e.id == eventId);
      if (index == -1) return false;

      final event = _events[index];
      
      // Vérifier si l'utilisateur a déjà réagi
      final existingReactionIndex = event.reactions.indexWhere(
        (r) => r.userId == user['id'],
      );
      
      List<TimelineReaction> updatedReactions;
      if (existingReactionIndex != -1) {
        // Mettre à jour la réaction existante
        updatedReactions = List<TimelineReaction>.from(event.reactions);
        updatedReactions[existingReactionIndex] = TimelineReaction(
          id: const Uuid().v4(),
          userId: user['id'] as String,
          userName: user['displayName'] as String,
          userAvatar: user['photoURL'] as String?,
          emoji: emoji,
          createdAt: DateTime.now(),
        );
      } else {
        // Ajouter une nouvelle réaction
        updatedReactions = [
          ...event.reactions,
          TimelineReaction(
            id: const Uuid().v4(),
            userId: user['id'] as String,
            userName: user['displayName'] as String,
            userAvatar: user['photoURL'] as String?,
            emoji: emoji,
            createdAt: DateTime.now(),
          ),
        ];
      }

      final updatedEvent = event.copyWith(reactions: updatedReactions);
      _events[index] = updatedEvent;
      await _saveEvents();
      _eventsController.add(_events);
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de la réaction: $e');
      return false;
    }
  }

  /// Ajouter un commentaire à un événement
  Future<bool> addComment(String eventId, String content, {String? parentId}) async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) return false;

      final index = _events.indexWhere((e) => e.id == eventId);
      if (index == -1) return false;

      final event = _events[index];
      
      final comment = TimelineComment(
        id: const Uuid().v4(),
        userId: user['id'] as String,
        userName: user['displayName'] as String,
        userAvatar: user['photoURL'] as String?,
        content: content,
        createdAt: DateTime.now(),
        parentId: parentId,
      );

      final updatedComments = List<TimelineComment>.from(event.comments);
      
      if (parentId != null) {
        // Ajouter comme réponse
        final parentCommentIndex = updatedComments.indexWhere((c) => c.id == parentId);
        if (parentCommentIndex != -1) {
          final parentComment = updatedComments[parentCommentIndex];
          updatedComments[parentCommentIndex] = parentComment.copyWith(
            replies: [...parentComment.replies, comment],
          );
        }
      } else {
        // Ajouter comme commentaire principal
        updatedComments.add(comment);
      }

      final updatedEvent = event.copyWith(comments: updatedComments);
      _events[index] = updatedEvent;
      await _saveEvents();
      _eventsController.add(_events);
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du commentaire: $e');
      return false;
    }
  }

  /// Marquer un événement comme vu
  Future<bool> markEventAsViewed(String eventId) async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) return false;

      final index = _events.indexWhere((e) => e.id == eventId);
      if (index == -1) return false;

      final event = _events[index];
      final userId = user['id'] as String;
      
      if (!event.viewerIds.contains(userId)) {
        final updatedViewerIds = [...event.viewerIds, userId];
        final updatedEvent = event.copyWith(
          viewerIds: updatedViewerIds,
          viewCount: event.viewCount + 1,
        );
        
        _events[index] = updatedEvent;
        await _saveEvents();
        _eventsController.add(_events);
      }
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors du marquage comme vu: $e');
      return false;
    }
  }

  /// Filtrer les événements
  List<TimelineEvent> filterEvents(TimelineFilter filter) {
    if (filter.isEmpty) return _events;

    return _events.where((event) {
      // Filtrer par type d'événement
      if (filter.eventTypes != null && 
          !filter.eventTypes!.contains(event.type)) {
        return false;
      }

      // Filtrer par participants
      if (filter.participantIds != null && 
          !filter.participantIds!.any((id) => event.participantIds.contains(id))) {
        return false;
      }

      // Filtrer par plage de dates
      if (filter.startDate != null && event.eventDate.isBefore(filter.startDate!)) {
        return false;
      }
      if (filter.endDate != null && event.eventDate.isAfter(filter.endDate!)) {
        return false;
      }

      // Filtrer par importance
      if (filter.importanceLevels != null && 
          !filter.importanceLevels!.contains(event.importance)) {
        return false;
      }

      // Filtrer par tags
      if (filter.tags != null && 
          !filter.tags!.any((tag) => event.tags.contains(tag))) {
        return false;
      }

      // Filtrer par localisation
      if (filter.location != null && 
          event.location?.toLowerCase().contains(filter.location!.toLowerCase()) != true) {
        return false;
      }

      // Filtrer par média uniquement
      if (filter.withMediaOnly == true && event.mediaUrls.isEmpty) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Obtenir les événements par personne
  List<TimelineEvent> getEventsByPerson(String personId) {
    return _events.where((event) => 
        event.participantIds.contains(personId) ||
        event.creatorId == personId).toList();
  }

  /// Obtenir les événements par type
  List<TimelineEvent> getEventsByType(TimelineEventType type) {
    return _events.where((event) => event.type == type).toList();
  }

  /// Obtenir les événements récents (derniers 30 jours)
  List<TimelineEvent> getRecentEvents({int days = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _events.where((event) => event.eventDate.isAfter(cutoffDate)).toList();
  }

  /// Obtenir les événements à venir
  List<TimelineEvent> getUpcomingEvents({int days = 30}) {
    final futureDate = DateTime.now().add(Duration(days: days));
    return _events.where((event) => 
        event.eventDate.isAfter(DateTime.now()) && 
        event.eventDate.isBefore(futureDate)).toList();
  }

  /// Obtenir les événements d'aujourd'hui
  List<TimelineEvent> getTodayEvents() {
    final now = DateTime.now();
    return _events.where((event) => 
        event.eventDate.year == now.year &&
        event.eventDate.month == now.month &&
        event.eventDate.day == now.day).toList();
  }

  /// Obtenir les statistiques de la timeline
  Map<String, dynamic> getTimelineStats() {
    final totalEvents = _events.length;
    final eventsWithMedia = _events.where((e) => e.mediaUrls.isNotEmpty).length;
    final totalReactions = _events.fold<int>(0, (sum, e) => sum + e.reactions.length);
    final totalComments = _events.fold<int>(0, (sum, e) => sum + e.comments.length);
    final totalViews = _events.fold<int>(0, (sum, e) => sum + e.viewCount);

    // Événements par type
    final eventsByType = <TimelineEventType, int>{};
    for (final event in _events) {
      eventsByType[event.type] = (eventsByType[event.type] ?? 0) + 1;
    }

    // Événements par importance
    final eventsByImportance = <TimelineEventImportance, int>{};
    for (final event in _events) {
      eventsByImportance[event.importance] = (eventsByImportance[event.importance] ?? 0) + 1;
    }

    return {
      'totalEvents': totalEvents,
      'eventsWithMedia': eventsWithMedia,
      'totalReactions': totalReactions,
      'totalComments': totalComments,
      'totalViews': totalViews,
      'averageReactionsPerEvent': totalEvents > 0 ? totalReactions / totalEvents : 0,
      'averageCommentsPerEvent': totalEvents > 0 ? totalComments / totalEvents : 0,
      'averageViewsPerEvent': totalEvents > 0 ? totalViews / totalEvents : 0,
      'eventsByType': eventsByType,
      'eventsByImportance': eventsByImportance,
    };
  }

  /// Démarrer le rafraîchissement automatique
  void _startAutoRefresh() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanupOldEvents();
    });
  }

  /// Nettoyer les anciens événements (plus de 2 ans)
  Future<void> _cleanupOldEvents() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 730));
      final initialCount = _events.length;
      
      _events.removeWhere((event) => 
          event.importance == TimelineEventImportance.low && 
          event.eventDate.isBefore(cutoffDate));

      if (_events.length != initialCount) {
        await _saveEvents();
        _eventsController.add(_events);
        debugPrint('Nettoyage timeline: ${initialCount - _events.length} événements supprimés');
      }
    } catch (e) {
      debugPrint('Erreur lors du nettoyage des events: $e');
    }
  }

  /// Libérer les ressources
  void dispose() {
    _eventsController.close();
  }
}

/// Service d'authentification temporaire
class _TempAuthService {
  Future<Map<String, dynamic>?> getCurrentUser() async {
    return {
      'id': 'temp_user_123',
      'displayName': 'Utilisateur Test',
      'photoURL': null,
    };
  }
}
