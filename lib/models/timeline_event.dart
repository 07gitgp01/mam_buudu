import 'dart:ui';

/// Types d'événements de timeline
enum TimelineEventType {
  birth,           // Naissance
  marriage,        // Mariage  
  death,           // Décès
  anniversary,     // Anniversaire
  graduation,      // Diplôme
  career,          // Carrière
  travel,          // Voyage
  achievement,     // Réussite
  familyGathering, // Réunion familiale
  custom,          // Personnalisé
}

/// Importance d'un événement
enum TimelineEventImportance {
  low,      // Faible importance
  medium,   // Importance moyenne
  high,     // Haute importance
  critical, // Importance critique
}

/// Visibilité d'un événement
enum TimelineEventVisibility {
  public,   // Visible par toute la famille
  private,  // Visible uniquement par l'utilisateur
  custom,   // Personnalisé (liste de personnes)
}

/// Événement dans la timeline familiale
class TimelineEvent {
  final String id;
  final String title;
  final String description;
  final TimelineEventType type;
  final TimelineEventImportance importance;
  final TimelineEventVisibility visibility;
  
  // Dates
  final DateTime eventDate;
  final DateTime? endDate; // Pour les événements sur plusieurs jours
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Participants
  final List<String> participantIds; // Personnes impliquées
  final String creatorId; // Qui a créé l'événement
  
  // Médias
  final List<String> mediaUrls; // Photos, vidéos, documents
  final String? thumbnailUrl; // Miniature pour l'affichage
  
  // Localisation
  final String? location;
  final double? latitude;
  final double? longitude;
  
  // Interactions sociales
  final List<TimelineReaction> reactions;
  final List<TimelineComment> comments;
  final int viewCount;
  final List<String> viewerIds; // Qui a vu l'événement
  
  // Métadonnées
  final Map<String, dynamic> metadata; // Données supplémentaires
  final List<String> tags; // Tags pour la recherche
  final String? category; // Catégorie personnalisée
  
  // Personnalisation
  final Color? color; // Couleur personnalisée
  final String? icon; // Icône personnalisée
  
  const TimelineEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.importance = TimelineEventImportance.medium,
    this.visibility = TimelineEventVisibility.public,
    required this.eventDate,
    this.endDate,
    required this.createdAt,
    this.updatedAt,
    this.participantIds = const [],
    required this.creatorId,
    this.mediaUrls = const [],
    this.thumbnailUrl,
    this.location,
    this.latitude,
    this.longitude,
    this.reactions = const [],
    this.comments = const [],
    this.viewCount = 0,
    this.viewerIds = const [],
    this.metadata = const {},
    this.tags = const [],
    this.category,
    this.color,
    this.icon,
  });

  /// Créer un événement depuis JSON
  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: TimelineEventType.values.firstWhere(
        (e) => e.toString() == 'TimelineEventType.${json['type']}',
        orElse: () => TimelineEventType.custom,
      ),
      importance: TimelineEventImportance.values.firstWhere(
        (e) => e.toString() == 'TimelineEventImportance.${json['importance']}',
        orElse: () => TimelineEventImportance.medium,
      ),
      visibility: TimelineEventVisibility.values.firstWhere(
        (e) => e.toString() == 'TimelineEventVisibility.${json['visibility']}',
        orElse: () => TimelineEventVisibility.public,
      ),
      eventDate: DateTime.parse(json['eventDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      participantIds: List<String>.from(json['participantIds'] as List? ?? []),
      creatorId: json['creatorId'] as String,
      mediaUrls: List<String>.from(json['mediaUrls'] as List? ?? []),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      reactions: (json['reactions'] as List?)
          ?.map((r) => TimelineReaction.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
      comments: (json['comments'] as List?)
          ?.map((c) => TimelineComment.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
      viewCount: json['viewCount'] as int? ?? 0,
      viewerIds: List<String>.from(json['viewerIds'] as List? ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      tags: List<String>.from(json['tags'] as List? ?? []),
      category: json['category'] as String?,
      color: json['color'] != null ? Color(json['color'] as int) : null,
      icon: json['icon'] as String?,
    );
  }

  /// Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'importance': importance.toString().split('.').last,
      'visibility': visibility.toString().split('.').last,
      'eventDate': eventDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'participantIds': participantIds,
      'creatorId': creatorId,
      'mediaUrls': mediaUrls,
      'thumbnailUrl': thumbnailUrl,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'reactions': reactions.map((r) => r.toJson()).toList(),
      'comments': comments.map((c) => c.toJson()).toList(),
      'viewCount': viewCount,
      'viewerIds': viewerIds,
      'metadata': metadata,
      'tags': tags,
      'category': category,
      'color': color?.value,
      'icon': icon,
    };
  }

  /// Copier avec modifications
  TimelineEvent copyWith({
    String? id,
    String? title,
    String? description,
    TimelineEventType? type,
    TimelineEventImportance? importance,
    TimelineEventVisibility? visibility,
    DateTime? eventDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? participantIds,
    String? creatorId,
    List<String>? mediaUrls,
    String? thumbnailUrl,
    String? location,
    double? latitude,
    double? longitude,
    List<TimelineReaction>? reactions,
    List<TimelineComment>? comments,
    int? viewCount,
    List<String>? viewerIds,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    String? category,
    Color? color,
    String? icon,
  }) {
    return TimelineEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      importance: importance ?? this.importance,
      visibility: visibility ?? this.visibility,
      eventDate: eventDate ?? this.eventDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      participantIds: participantIds ?? this.participantIds,
      creatorId: creatorId ?? this.creatorId,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      reactions: reactions ?? this.reactions,
      comments: comments ?? this.comments,
      viewCount: viewCount ?? this.viewCount,
      viewerIds: viewerIds ?? this.viewerIds,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }

  /// Obtenir l'icône par défaut pour le type d'événement
  String get defaultIcon {
    switch (type) {
      case TimelineEventType.birth:
        return 'baby_carriage';
      case TimelineEventType.marriage:
        return 'favorite';
      case TimelineEventType.death:
        return 'peace';
      case TimelineEventType.anniversary:
        return 'cake';
      case TimelineEventType.graduation:
        return 'school';
      case TimelineEventType.career:
        return 'work';
      case TimelineEventType.travel:
        return 'flight';
      case TimelineEventType.achievement:
        return 'emoji_events';
      case TimelineEventType.familyGathering:
        return 'groups';
      case TimelineEventType.custom:
        return 'event';
    }
  }

  /// Obtenir la couleur par défaut pour le type d'événement
  Color get defaultColor {
    switch (type) {
      case TimelineEventType.birth:
        return const Color(0xFF4CAF50); // Vert
      case TimelineEventType.marriage:
        return const Color(0xFFE91E63); // Rose
      case TimelineEventType.death:
        return const Color(0xFF757575); // Gris
      case TimelineEventType.anniversary:
        return const Color(0xFFFF9800); // Orange
      case TimelineEventType.graduation:
        return const Color(0xFF2196F3); // Bleu
      case TimelineEventType.career:
        return const Color(0xFF9C27B0); // Violet
      case TimelineEventType.travel:
        return const Color(0xFF00BCD4); // Cyan
      case TimelineEventType.achievement:
        return const Color(0xFFFFD700); // Or
      case TimelineEventType.familyGathering:
        return const Color(0xFF795548); // Marron
      case TimelineEventType.custom:
        return const Color(0xFF607D8B); // Bleu gris
    }
  }

  /// Vérifier si l'événement est sur plusieurs jours
  bool get isMultiDay => endDate != null && !endDate!.isAtSameMomentAs(eventDate);

  /// Obtenir la durée en jours
  int get durationInDays {
    if (endDate == null) return 1;
    return endDate!.difference(eventDate).inDays + 1;
  }

  /// Vérifier si l'événement est aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return eventDate.year == now.year && 
           eventDate.month == now.month && 
           eventDate.day == now.day;
  }

  /// Vérifier si l'événement est dans le passé
  bool get isPast => eventDate.isBefore(DateTime.now());

  /// Vérifier si l'événement est dans le futur
  bool get isFuture => eventDate.isAfter(DateTime.now());

  /// Obtenir le temps écoulé depuis l'événement
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(eventDate);
    
    if (difference.inDays > 365) {
      return 'Il y a ${difference.inDays ~/ 365} an${difference.inDays ~/ 365 > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      return 'Il y a ${difference.inDays ~/ 30} mois';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  @override
  String toString() {
    return 'TimelineEvent(id: $id, title: $title, type: $type, date: $eventDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimelineEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Réaction à un événement de timeline
class TimelineReaction {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String emoji; // Réaction emoji
  final DateTime createdAt;

  const TimelineReaction({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.emoji,
    required this.createdAt,
  });

  factory TimelineReaction.fromJson(Map<String, dynamic> json) {
    return TimelineReaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String?,
      emoji: json['emoji'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'emoji': emoji,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimelineReaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Commentaire sur un événement de timeline
class TimelineComment {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<TimelineComment> replies; // Réponses imbriquées
  final String? parentId; // ID du commentaire parent si c'est une réponse

  const TimelineComment({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.replies = const [],
    this.parentId,
  });

  factory TimelineComment.fromJson(Map<String, dynamic> json) {
    return TimelineComment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      replies: (json['replies'] as List?)
          ?.map((c) => TimelineComment.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
      parentId: json['parentId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'replies': replies.map((c) => c.toJson()).toList(),
      'parentId': parentId,
    };
  }

  /// Vérifier si c'est une réponse
  bool get isReply => parentId != null;

  /// Obtenir le temps écoulé
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }

  /// Copier avec modifications
  TimelineComment copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TimelineComment>? replies,
    String? parentId,
  }) {
    return TimelineComment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      replies: replies ?? this.replies,
      parentId: parentId ?? this.parentId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimelineComment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Filtres pour la timeline
class TimelineFilter {
  final List<TimelineEventType>? eventTypes;
  final List<String>? participantIds;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<TimelineEventImportance>? importanceLevels;
  final List<String>? tags;
  final String? location;
  final bool? withMediaOnly;

  const TimelineFilter({
    this.eventTypes,
    this.participantIds,
    this.startDate,
    this.endDate,
    this.importanceLevels,
    this.tags,
    this.location,
    this.withMediaOnly,
  });

  /// Filtre vide (tout afficher)
  static const TimelineFilter none = TimelineFilter();

  /// Copier avec modifications
  TimelineFilter copyWith({
    List<TimelineEventType>? eventTypes,
    List<String>? participantIds,
    DateTime? startDate,
    DateTime? endDate,
    List<TimelineEventImportance>? importanceLevels,
    List<String>? tags,
    String? location,
    bool? withMediaOnly,
  }) {
    return TimelineFilter(
      eventTypes: eventTypes ?? this.eventTypes,
      participantIds: participantIds ?? this.participantIds,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      importanceLevels: importanceLevels ?? this.importanceLevels,
      tags: tags ?? this.tags,
      location: location ?? this.location,
      withMediaOnly: withMediaOnly ?? this.withMediaOnly,
    );
  }

  /// Vérifier si le filtre est vide
  bool get isEmpty => 
      eventTypes == null &&
      participantIds == null &&
      startDate == null &&
      endDate == null &&
      importanceLevels == null &&
      tags == null &&
      location == null &&
      withMediaOnly == null;

  @override
  String toString() {
    return 'TimelineFilter(eventTypes: $eventTypes, participants: $participantIds, dateRange: $startDate-$endDate)';
  }
}
