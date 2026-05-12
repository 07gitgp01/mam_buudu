import 'dart:ui';

/// Types de récompenses
enum RewardType {
  points,         // Points virtuels
  badge,          // Badge/Accomplissement
  title,          // Titre spécial
  avatar,         // Avatar personnalisé
  feature,        // Fonctionnalité débloquée
  theme,          // Thème personnalisé
  emoji,          // Emoji spécial
  frame,          // Cadre de profil
}

/// Catégories de récompenses
enum RewardCategory {
  gaming,         // Récompenses de jeu
  family,         // Participation familiale
  stories,        // Stories familiales
  timeline,       // Timeline/events
  engagement,     // Engagement régulier
  special,        // Événements spéciaux
  achievement,    // Accomplissements
  milestone,      // Jalons importants
}

/// Niveaux de rareté
enum RewardRarity {
  common,         // Commun (vert)
  rare,           // Rare (bleu)
  epic,           // Épique (violet)
  legendary,      // Légendaire (orange)
  mythic,         // Mythique (rouge)
}

/// Statut d'une récompense
enum RewardStatus {
  locked,         // Verrouillé
  unlocked,       // Débloqué
  claimed,        // Réclamé
  expired,        // Expiré
  active,         // Actif (pour features/themes)
}

/// Condition pour débloquer une récompense
enum RewardCondition {
  points_threshold,    // Seuil de points
  games_played,        // Nombre de jeux joués
  games_won,           // Nombre de jeux gagnés
  streak_days,         // Série de jours
  family_members,      // Nombre de membres familiaux
  stories_created,     // Stories créées
  timeline_events,     // Événements timeline
  login_days,          // Jours de connexion
  achievements_count,  // Nombre d'accomplissements
  special_event,       // Événement spécial
  referral,            // Parrainage
  level_reached,       // Niveau atteint
}

/// Récompense familiale
class FamilyReward {
  final String id;
  final String name;
  final String description;
  final RewardType type;
  final RewardCategory category;
  final RewardRarity rarity;
  final RewardStatus status;
  
  // Visuel
  final String? iconUrl;
  final String? imageUrl;
  final Color? color;
  final String? animationUrl;
  
  // Valeur et progression
  final int value; // points, niveau, etc.
  final int currentValue; // progression actuelle
  final int requiredValue; // valeur requise
  final double progressPercentage;
  
  // Conditions
  final List<RewardCondition> conditions;
  final Map<String, dynamic> conditionData; // données spécifiques aux conditions
  
  // Temps
  final DateTime createdAt;
  final DateTime? unlockedAt;
  final DateTime? claimedAt;
  final DateTime? expiresAt;
  final bool isPermanent;
  
  // Métadonnées
  final Map<String, dynamic> metadata;
  final List<String> tags;
  final bool isVisible;
  final bool isAvailable;
  
  // Récompenses associées
  final List<String> prerequisiteRewardIds; // récompenses requises
  final List<String> nextRewardIds; // récompenses suivantes

  const FamilyReward({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.rarity,
    this.status = RewardStatus.locked,
    this.iconUrl,
    this.imageUrl,
    this.color,
    this.animationUrl,
    required this.value,
    this.currentValue = 0,
    required this.requiredValue,
    required this.progressPercentage,
    this.conditions = const [],
    this.conditionData = const {},
    required this.createdAt,
    this.unlockedAt,
    this.claimedAt,
    this.expiresAt,
    this.isPermanent = true,
    this.metadata = const {},
    this.tags = const [],
    this.isVisible = true,
    this.isAvailable = true,
    this.prerequisiteRewardIds = const [],
    this.nextRewardIds = const [],
  });

  /// Créer une récompense depuis JSON
  factory FamilyReward.fromJson(Map<String, dynamic> json) {
    return FamilyReward(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: RewardType.values.firstWhere(
        (e) => e.toString() == 'RewardType.${json['type']}',
        orElse: () => RewardType.points,
      ),
      category: RewardCategory.values.firstWhere(
        (e) => e.toString() == 'RewardCategory.${json['category']}',
        orElse: () => RewardCategory.gaming,
      ),
      rarity: RewardRarity.values.firstWhere(
        (e) => e.toString() == 'RewardRarity.${json['rarity']}',
        orElse: () => RewardRarity.common,
      ),
      status: RewardStatus.values.firstWhere(
        (e) => e.toString() == 'RewardStatus.${json['status']}',
        orElse: () => RewardStatus.locked,
      ),
      iconUrl: json['iconUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      color: json['color'] != null ? Color(int.parse(json['color'] as String)) : null,
      animationUrl: json['animationUrl'] as String?,
      value: json['value'] as int,
      currentValue: json['currentValue'] as int? ?? 0,
      requiredValue: json['requiredValue'] as int,
      progressPercentage: (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      conditions: (json['conditions'] as List?)
          ?.map((c) => RewardCondition.values.firstWhere(
                (e) => e.toString() == 'RewardCondition.$c',
                orElse: () => RewardCondition.points_threshold,
              ))
          .toList() ?? [],
      conditionData: Map<String, dynamic>.from(json['conditionData'] as Map? ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt'] as String) : null,
      claimedAt: json['claimedAt'] != null ? DateTime.parse(json['claimedAt'] as String) : null,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
      isPermanent: json['isPermanent'] as bool? ?? true,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      tags: List<String>.from(json['tags'] as List? ?? []),
      isVisible: json['isVisible'] as bool? ?? true,
      isAvailable: json['isAvailable'] as bool? ?? true,
      prerequisiteRewardIds: List<String>.from(json['prerequisiteRewardIds'] as List? ?? []),
      nextRewardIds: List<String>.from(json['nextRewardIds'] as List? ?? []),
    );
  }

  /// Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'category': category.toString().split('.').last,
      'rarity': rarity.toString().split('.').last,
      'status': status.toString().split('.').last,
      'iconUrl': iconUrl,
      'imageUrl': imageUrl,
      'color': color?.value.toString(),
      'animationUrl': animationUrl,
      'value': value,
      'currentValue': currentValue,
      'requiredValue': requiredValue,
      'progressPercentage': progressPercentage,
      'conditions': conditions.map((c) => c.toString().split('.').last).toList(),
      'conditionData': conditionData,
      'createdAt': createdAt.toIso8601String(),
      'unlockedAt': unlockedAt?.toIso8601String(),
      'claimedAt': claimedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isPermanent': isPermanent,
      'metadata': metadata,
      'tags': tags,
      'isVisible': isVisible,
      'isAvailable': isAvailable,
      'prerequisiteRewardIds': prerequisiteRewardIds,
      'nextRewardIds': nextRewardIds,
    };
  }

  /// Copier avec modifications
  FamilyReward copyWith({
    String? id,
    String? name,
    String? description,
    RewardType? type,
    RewardCategory? category,
    RewardRarity? rarity,
    RewardStatus? status,
    String? iconUrl,
    String? imageUrl,
    Color? color,
    String? animationUrl,
    int? value,
    int? currentValue,
    int? requiredValue,
    double? progressPercentage,
    List<RewardCondition>? conditions,
    Map<String, dynamic>? conditionData,
    DateTime? createdAt,
    DateTime? unlockedAt,
    DateTime? claimedAt,
    DateTime? expiresAt,
    bool? isPermanent,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    bool? isVisible,
    bool? isAvailable,
    List<String>? prerequisiteRewardIds,
    List<String>? nextRewardIds,
  }) {
    return FamilyReward(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      status: status ?? this.status,
      iconUrl: iconUrl ?? this.iconUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      color: color ?? this.color,
      animationUrl: animationUrl ?? this.animationUrl,
      value: value ?? this.value,
      currentValue: currentValue ?? this.currentValue,
      requiredValue: requiredValue ?? this.requiredValue,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      conditions: conditions ?? this.conditions,
      conditionData: conditionData ?? this.conditionData,
      createdAt: createdAt ?? this.createdAt,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      claimedAt: claimedAt ?? this.claimedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isPermanent: isPermanent ?? this.isPermanent,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
      isVisible: isVisible ?? this.isVisible,
      isAvailable: isAvailable ?? this.isAvailable,
      prerequisiteRewardIds: prerequisiteRewardIds ?? this.prerequisiteRewardIds,
      nextRewardIds: nextRewardIds ?? this.nextRewardIds,
    );
  }

  /// Vérifier si la récompense est débloquée
  bool get isUnlocked => status == RewardStatus.unlocked || status == RewardStatus.claimed || status == RewardStatus.active;

  /// Vérifier si la récompense peut être réclamée
  bool get canClaim => status == RewardStatus.unlocked;

  /// Vérifier si la récompense est expirée
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  /// Vérifier si la progression est complète
  bool get isProgressComplete => currentValue >= requiredValue;

  /// Obtenir la couleur de rareté
  Color get rarityColor {
    switch (rarity) {
      case RewardRarity.common:
        return const Color(0xFF4CAF50); // Vert
      case RewardRarity.rare:
        return const Color(0xFF2196F3); // Bleu
      case RewardRarity.epic:
        return const Color(0xFF9C27B0); // Violet
      case RewardRarity.legendary:
        return const Color(0xFFFF9800); // Orange
      case RewardRarity.mythic:
        return const Color(0xFFF44336); // Rouge
    }
  }

  /// Obtenir l'icône par défaut pour le type
  String get defaultIcon {
    switch (type) {
      case RewardType.points:
        return 'stars';
      case RewardType.badge:
        return 'emoji_events';
      case RewardType.title:
        return 'military_tech';
      case RewardType.avatar:
        return 'face';
      case RewardType.feature:
        return 'lock_open';
      case RewardType.theme:
        return 'palette';
      case RewardType.emoji:
        return 'sentiment_satisfied_alt';
      case RewardType.frame:
        return 'crop_square';
    }
  }

  /// Obtenir la description de la progression
  String get progressDescription {
    if (isProgressComplete) {
      return 'Complété !';
    }
    return '$currentValue / $requiredValue';
  }

  @override
  String toString() {
    return 'FamilyReward(id: $id, name: $name, type: $type, rarity: $rarity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FamilyReward && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Inventaire des récompenses d'un utilisateur
class UserRewardInventory {
  final String userId;
  final List<String> unlockedRewardIds;
  final List<String> claimedRewardIds;
  final List<String> activeRewardIds; // features/themes actifs
  final Map<String, DateTime> rewardUnlockDates;
  final Map<String, DateTime> rewardClaimDates;
  final int totalPoints;
  final Map<RewardCategory, int> pointsByCategory;
  final List<String> equippedBadges;
  final String? activeTitle;
  final String? activeAvatar;
  final String? activeTheme;
  final String? activeFrame;

  const UserRewardInventory({
    required this.userId,
    this.unlockedRewardIds = const [],
    this.claimedRewardIds = const [],
    this.activeRewardIds = const [],
    this.rewardUnlockDates = const {},
    this.rewardClaimDates = const {},
    this.totalPoints = 0,
    this.pointsByCategory = const {},
    this.equippedBadges = const [],
    this.activeTitle,
    this.activeAvatar,
    this.activeTheme,
    this.activeFrame,
  });

  factory UserRewardInventory.fromJson(Map<String, dynamic> json) {
    return UserRewardInventory(
      userId: json['userId'] as String,
      unlockedRewardIds: List<String>.from(json['unlockedRewardIds'] as List? ?? []),
      claimedRewardIds: List<String>.from(json['claimedRewardIds'] as List? ?? []),
      activeRewardIds: List<String>.from(json['activeRewardIds'] as List? ?? []),
      rewardUnlockDates: Map<String, DateTime>.from(
        (json['rewardUnlockDates'] as Map? ?? {}).map(
          (key, value) => MapEntry(key, DateTime.parse(value as String)),
        ),
      ),
      rewardClaimDates: Map<String, DateTime>.from(
        (json['rewardClaimDates'] as Map? ?? {}).map(
          (key, value) => MapEntry(key, DateTime.parse(value as String)),
        ),
      ),
      totalPoints: json['totalPoints'] as int? ?? 0,
      pointsByCategory: Map<RewardCategory, int>.from(
        (json['pointsByCategory'] as Map? ?? {}).map(
          (key, value) => MapEntry(
            RewardCategory.values.firstWhere(
              (e) => e.toString() == 'RewardCategory.$key',
              orElse: () => RewardCategory.gaming,
            ),
            value as int,
          ),
        ),
      ),
      equippedBadges: List<String>.from(json['equippedBadges'] as List? ?? []),
      activeTitle: json['activeTitle'] as String?,
      activeAvatar: json['activeAvatar'] as String?,
      activeTheme: json['activeTheme'] as String?,
      activeFrame: json['activeFrame'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'unlockedRewardIds': unlockedRewardIds,
      'claimedRewardIds': claimedRewardIds,
      'activeRewardIds': activeRewardIds,
      'rewardUnlockDates': rewardUnlockDates.map((key, value) => MapEntry(key, value.toIso8601String())),
      'rewardClaimDates': rewardClaimDates.map((key, value) => MapEntry(key, value.toIso8601String())),
      'totalPoints': totalPoints,
      'pointsByCategory': pointsByCategory.map((key, value) => MapEntry(key.toString().split('.').last, value)),
      'equippedBadges': equippedBadges,
      'activeTitle': activeTitle,
      'activeAvatar': activeAvatar,
      'activeTheme': activeTheme,
      'activeFrame': activeFrame,
    };
  }

  /// Vérifier si une récompense est débloquée
  bool isRewardUnlocked(String rewardId) {
    return unlockedRewardIds.contains(rewardId);
  }

  /// Vérifier si une récompense est réclamée
  bool isRewardClaimed(String rewardId) {
    return claimedRewardIds.contains(rewardId);
  }

  /// Vérifier si une récompense est active
  bool isRewardActive(String rewardId) {
    return activeRewardIds.contains(rewardId);
  }

  /// Obtenir le nombre de récompenses par catégorie
  Map<RewardCategory, int> get rewardsByCategory {
    final counts = <RewardCategory, int>{};
    for (final category in RewardCategory.values) {
      counts[category] = 0;
    }
    return counts;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserRewardInventory && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}

/// Transaction de récompenses
class RewardTransaction {
  final String id;
  final String userId;
  final String rewardId;
  final RewardTransactionType type;
  final int amount; // points gagnés/dépensés
  final String reason;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const RewardTransaction({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.type,
    required this.amount,
    required this.reason,
    required this.createdAt,
    this.metadata = const {},
  });

  factory RewardTransaction.fromJson(Map<String, dynamic> json) {
    return RewardTransaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      rewardId: json['rewardId'] as String,
      type: RewardTransactionType.values.firstWhere(
        (e) => e.toString() == 'RewardTransactionType.${json['type']}',
        orElse: () => RewardTransactionType.earned,
      ),
      amount: json['amount'] as int,
      reason: json['reason'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'rewardId': rewardId,
      'type': type.toString().split('.').last,
      'amount': amount,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RewardTransaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Types de transactions de récompenses
enum RewardTransactionType {
  earned,         // Points gagnés
  spent,          // Points dépensés
  unlocked,       // Récompense débloquée
  claimed,        // Récompense réclamée
  expired,        // Récompense expirée
  refunded,       // Remboursement
  bonus,          // Bonus spécial
  penalty,        // Pénalité
}

/// Notification de récompense
class RewardNotification {
  final String id;
  final String userId;
  final String rewardId;
  final RewardNotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic> data;

  const RewardNotification({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.data = const {},
  });

  factory RewardNotification.fromJson(Map<String, dynamic> json) {
    return RewardNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      rewardId: json['rewardId'] as String,
      type: RewardNotificationType.values.firstWhere(
        (e) => e.toString() == 'RewardNotificationType.${json['type']}',
        orElse: () => RewardNotificationType.unlocked,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'rewardId': rewardId,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RewardNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Types de notifications de récompenses
enum RewardNotificationType {
  unlocked,       // Récompense débloquée
  claimed,        // Récompense réclamée
  expired,        // Récompense expirée
  available,      // Nouvelle récompense disponible
  progress,       // Progression mise à jour
  milestone,      // Jalon atteint
  bonus,          // Bonus reçu
  reminder,       // Rappel de réclamation
}

/// Configuration du système de récompenses
class RewardSystemConfig {
  final Map<RewardCategory, int> dailyPointLimits;
  final Map<RewardType, int> rewardLimits;
  final Map<RewardRarity, double> dropRates;
  final List<String> disabledRewardIds;
  final Map<String, dynamic> specialEventConfig;
  final bool isMaintenanceMode;
  final String? maintenanceMessage;
  final DateTime lastUpdated;

  const RewardSystemConfig({
    this.dailyPointLimits = const {},
    this.rewardLimits = const {},
    this.dropRates = const {},
    this.disabledRewardIds = const [],
    this.specialEventConfig = const {},
    this.isMaintenanceMode = false,
    this.maintenanceMessage,
    required this.lastUpdated,
  });

  factory RewardSystemConfig.fromJson(Map<String, dynamic> json) {
    return RewardSystemConfig(
      dailyPointLimits: Map<RewardCategory, int>.from(
        (json['dailyPointLimits'] as Map? ?? {}).map(
          (key, value) => MapEntry(
            RewardCategory.values.firstWhere(
              (e) => e.toString() == 'RewardCategory.$key',
              orElse: () => RewardCategory.gaming,
            ),
            value as int,
          ),
        ),
      ),
      rewardLimits: Map<RewardType, int>.from(
        (json['rewardLimits'] as Map? ?? {}).map(
          (key, value) => MapEntry(
            RewardType.values.firstWhere(
              (e) => e.toString() == 'RewardType.$key',
              orElse: () => RewardType.points,
            ),
            value as int,
          ),
        ),
      ),
      dropRates: Map<RewardRarity, double>.from(
        (json['dropRates'] as Map? ?? {}).map(
          (key, value) => MapEntry(
            RewardRarity.values.firstWhere(
              (e) => e.toString() == 'RewardRarity.$key',
              orElse: () => RewardRarity.common,
            ),
            (value as num).toDouble(),
          ),
        ),
      ),
      disabledRewardIds: List<String>.from(json['disabledRewardIds'] as List? ?? []),
      specialEventConfig: Map<String, dynamic>.from(json['specialEventConfig'] as Map? ?? {}),
      isMaintenanceMode: json['isMaintenanceMode'] as bool? ?? false,
      maintenanceMessage: json['maintenanceMessage'] as String?,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyPointLimits': dailyPointLimits.map((key, value) => MapEntry(key.toString().split('.').last, value)),
      'rewardLimits': rewardLimits.map((key, value) => MapEntry(key.toString().split('.').last, value)),
      'dropRates': dropRates.map((key, value) => MapEntry(key.toString().split('.').last, value)),
      'disabledRewardIds': disabledRewardIds,
      'specialEventConfig': specialEventConfig,
      'isMaintenanceMode': isMaintenanceMode,
      'maintenanceMessage': maintenanceMessage,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RewardSystemConfig && other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode => lastUpdated.hashCode;
}
