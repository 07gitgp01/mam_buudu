/// Modèle pour les stories familiales temporaires
class FamilyStory {
  final String id;
  final String creatorId;
  final String creatorName;
  final String? creatorAvatar;
  final String mediaUrl;
  final StoryMediaType mediaType;
  final String caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewerIds;
  final List<String>? allowedViewerIds; // null = public pour la famille
  final StoryPrivacy privacy;
  final StoryFilter? filter;
  final List<StoryReaction> reactions;
  final List<StoryComment> comments;
  final bool isViewedByCurrentUser;
  final int viewCount;

  const FamilyStory({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    this.creatorAvatar,
    required this.mediaUrl,
    required this.mediaType,
    required this.caption,
    required this.createdAt,
    required this.expiresAt,
    required this.viewerIds,
    this.allowedViewerIds,
    required this.privacy,
    this.filter,
    this.reactions = const [],
    this.comments = const [],
    this.isViewedByCurrentUser = false,
    this.viewCount = 0,
  });

  factory FamilyStory.fromJson(Map<String, dynamic> json) {
    // Validation des champs obligatoires
    if (!json.containsKey('id') || json['id'] == null) {
      throw ArgumentError('Le champ "id" est manquant dans le JSON');
    }
    if (!json.containsKey('creatorId') || json['creatorId'] == null) {
      throw ArgumentError('Le champ "creatorId" est manquant dans le JSON');
    }
    if (!json.containsKey('creatorName') || json['creatorName'] == null) {
      throw ArgumentError('Le champ "creatorName" est manquant dans le JSON');
    }
    if (!json.containsKey('mediaUrl') || json['mediaUrl'] == null) {
      throw ArgumentError('Le champ "mediaUrl" est manquant dans le JSON');
    }
    if (!json.containsKey('createdAt') || json['createdAt'] == null) {
      throw ArgumentError('Le champ "createdAt" est manquant dans le JSON');
    }
    if (!json.containsKey('expiresAt') || json['expiresAt'] == null) {
      throw ArgumentError('Le champ "expiresAt" est manquant dans le JSON');
    }

    return FamilyStory(
      id: json['id'] as String,
      creatorId: json['creatorId'] as String,
      creatorName: json['creatorName'] as String,
      creatorAvatar: json['creatorAvatar'] as String?,
      mediaUrl: json['mediaUrl'] as String,
      mediaType: StoryMediaType.values.firstWhere(
        (e) => e.toString() == 'StoryMediaType.${json['mediaType']}',
        orElse: () => StoryMediaType.photo,
      ),
      caption: json['caption'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      viewerIds: List<String>.from(json['viewerIds'] as List? ?? []),
      allowedViewerIds: json['allowedViewerIds'] != null 
          ? List<String>.from(json['allowedViewerIds'] as List)
          : null,
      privacy: StoryPrivacy.values.firstWhere(
        (e) => e.toString() == 'StoryPrivacy.${json['privacy']}',
        orElse: () => StoryPrivacy.family,
      ),
      filter: json['filter'] != null 
          ? StoryFilter.values.firstWhere(
              (e) => e.toString() == 'StoryFilter.${json['filter']}',
              orElse: () => StoryFilter.none,
            )
          : null,
      reactions: (json['reactions'] as List?)
          ?.map((r) => StoryReaction.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
      comments: (json['comments'] as List?)
          ?.map((c) => StoryComment.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
      isViewedByCurrentUser: json['isViewedByCurrentUser'] as bool? ?? false,
      viewCount: json['viewCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorAvatar': creatorAvatar,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType.toString().split('.').last,
      'caption': caption,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'viewerIds': viewerIds,
      'allowedViewerIds': allowedViewerIds,
      'privacy': privacy.toString().split('.').last,
      'filter': filter?.toString().split('.').last,
      'reactions': reactions.map((r) => r.toJson()).toList(),
      'comments': comments.map((c) => c.toJson()).toList(),
      'isViewedByCurrentUser': isViewedByCurrentUser,
      'viewCount': viewCount,
    };
  }

  FamilyStory copyWith({
    String? id,
    String? creatorId,
    String? creatorName,
    String? creatorAvatar,
    String? mediaUrl,
    StoryMediaType? mediaType,
    String? caption,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? viewerIds,
    List<String>? allowedViewerIds,
    StoryPrivacy? privacy,
    StoryFilter? filter,
    List<StoryReaction>? reactions,
    List<StoryComment>? comments,
    bool? isViewedByCurrentUser,
    int? viewCount,
  }) {
    return FamilyStory(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatar: creatorAvatar ?? this.creatorAvatar,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewerIds: viewerIds ?? this.viewerIds,
      allowedViewerIds: allowedViewerIds ?? this.allowedViewerIds,
      privacy: privacy ?? this.privacy,
      filter: filter ?? this.filter,
      reactions: reactions ?? this.reactions,
      comments: comments ?? this.comments,
      isViewedByCurrentUser: isViewedByCurrentUser ?? this.isViewedByCurrentUser,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isViewed => isViewedByCurrentUser;
  Duration get timeRemaining => expiresAt.difference(DateTime.now());
  bool get isExpiringSoon => timeRemaining.inHours < 2;
}

/// Types de médias pour les stories
enum StoryMediaType {
  photo,
  video,
  boomerang,
  superzoom,
}

/// Niveaux de confidentialité des stories
enum StoryPrivacy {
  family,      // Visible par toute la famille
  custom,      // Visible par certaines personnes seulement
  private,     // Visible par le créateur seulement
}

/// Filtres disponibles pour les stories
enum StoryFilter {
  none,
  vintage,
  blackAndWhite,
  sepia,
  warm,
  cool,
  familyGold,
  nostalgia,
}

/// Réaction à une story
class StoryReaction {
  final String id;
  final String storyId;
  final String userId;
  final String userName;
  final String emoji;
  final DateTime createdAt;

  const StoryReaction({
    required this.id,
    required this.storyId,
    required this.userId,
    required this.userName,
    required this.emoji,
    required this.createdAt,
  });

  factory StoryReaction.fromJson(Map<String, dynamic> json) {
    return StoryReaction(
      id: json['id'] as String,
      storyId: json['storyId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      emoji: json['emoji'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storyId': storyId,
      'userId': userId,
      'userName': userName,
      'emoji': emoji,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Commentaire sur une story
class StoryComment {
  final String id;
  final String storyId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime createdAt;
  final List<StoryComment> replies;

  const StoryComment({
    required this.id,
    required this.storyId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.createdAt,
    this.replies = const [],
  });

  factory StoryComment.fromJson(Map<String, dynamic> json) {
    return StoryComment(
      id: json['id'] as String,
      storyId: json['storyId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      replies: (json['replies'] as List?)
          ?.map((r) => StoryComment.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storyId': storyId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'replies': replies.map((r) => r.toJson()).toList(),
    };
  }
}

/// Collection de réactions disponibles
class StoryReactions {
  static const List<String> availableEmojis = [
    'heart', 'love', 'haha', 'wow', 'sad', 'angry',
    'fire', 'clap', 'pray', 'thumbsup', 'thumbsdown',
    'eyes', 'celebration', 'family', 'photo', 'video'
  ];

  static const Map<String, String> emojiMap = {
    'heart': 'heart',
    'love': 'love',
    'haha': 'haha',
    'wow': 'wow',
    'sad': 'sad',
    'angry': 'angry',
    'fire': 'fire',
    'clap': 'clap',
    'pray': 'pray',
    'thumbsup': 'thumbsup',
    'thumbsdown': 'thumbsdown',
    'eyes': 'eyes',
    'celebration': 'celebration',
    'family': 'family',
    'photo': 'photo',
    'video': 'video',
  };
}
