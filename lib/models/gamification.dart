import 'package:flutter/material.dart';

/// Niveaux de gamification
enum GameLevel {
  debutant('Débutant', 0, Colors.green, Icons.emoji_emotions),
  explorateur('Explorateur', 100, Colors.blue, Icons.explore),
  historien('Historien', 500, Colors.purple, Icons.history_edu),
  genealogiste('Généalogiste', 1500, Colors.orange, Icons.family_restroom),
  expert('Expert', 5000, Colors.red, Icons.military_tech),
  maitre('Maître', 10000, Colors.amber, Icons.workspace_premium);

  const GameLevel(this.title, this.minPoints, this.color, this.icon);
  final String title;
  final int minPoints;
  final Color color;
  final IconData icon;

  static GameLevel fromPoints(int points) {
    for (final level in GameLevel.values.reversed) {
      if (points >= level.minPoints) return level;
    }
    return GameLevel.debutant;
  }
}

/// Types d'actions pour les points
enum ActionType {
  addPerson('Ajouter une personne', 10),
  addPhoto('Ajouter une photo', 5),
  addUnion('Créer une union', 15),
  addDocument('Ajouter un document', 8),
  loginDaily('Connexion quotidienne', 2),
  shareProfile('Partager un profil', 3),
  comment('Commenter', 2),
  like('Aimer', 1);

  const ActionType(this.title, this.points);
  final String title;
  final int points;
}

/// Badges de gamification
class Badge {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final Color color;
  final int pointsRequired;
  final BadgeType type;

  const Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.color,
    required this.pointsRequired,
    required this.type,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      iconPath: json['iconPath'],
      color: Color(int.parse(json['color'])),
      pointsRequired: json['pointsRequired'],
      type: BadgeType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => BadgeType.action,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconPath': iconPath,
      'color': color.value,
      'pointsRequired': pointsRequired,
      'type': type.toString(),
    };
  }
}

enum BadgeType {
  action('Action'),
  streak('Série'),
  social('Social'),
  milestone('Jalon');

  const BadgeType(this.title);
  final String title;
}

/// Profil de gamification utilisateur
class GameProfile {
  final String userId;
  int totalPoints;
  int currentStreak;
  int longestStreak;
  List<String> unlockedBadges;
  Map<String, int> actionCounts;
  DateTime? lastLoginDate;
  List<ActionHistory> recentActions;

  GameProfile({
    required this.userId,
    this.totalPoints = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.unlockedBadges = const [],
    this.actionCounts = const {},
    this.lastLoginDate,
    this.recentActions = const [],
  });

  GameLevel get currentLevel => GameLevel.fromPoints(totalPoints);
  
  int get pointsToNextLevel {
    final currentLevel = this.currentLevel;
    final nextLevelIndex = GameLevel.values.indexOf(currentLevel) + 1;
    if (nextLevelIndex >= GameLevel.values.length) return 0;
    
    final nextLevel = GameLevel.values[nextLevelIndex];
    return nextLevel.minPoints - totalPoints;
  }

  double get levelProgress {
    final currentLevel = this.currentLevel;
    final nextLevelIndex = GameLevel.values.indexOf(currentLevel) + 1;
    if (nextLevelIndex >= GameLevel.values.length) return 1.0;
    
    final nextLevel = GameLevel.values[nextLevelIndex];
    final levelRange = nextLevel.minPoints - currentLevel.minPoints;
    final progressInLevel = totalPoints - currentLevel.minPoints;
    
    return progressInLevel / levelRange;
  }

  factory GameProfile.fromJson(Map<String, dynamic> json) {
    return GameProfile(
      userId: json['userId'],
      totalPoints: json['totalPoints'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      unlockedBadges: List<String>.from(json['unlockedBadges'] ?? []),
      actionCounts: Map<String, int>.from(json['actionCounts'] ?? {}),
      lastLoginDate: json['lastLoginDate'] != null 
          ? DateTime.parse(json['lastLoginDate'])
          : null,
      recentActions: (json['recentActions'] as List?)
          ?.map((e) => ActionHistory.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalPoints': totalPoints,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'unlockedBadges': unlockedBadges,
      'actionCounts': actionCounts,
      'lastLoginDate': lastLoginDate?.toIso8601String(),
      'recentActions': recentActions.map((e) => e.toJson()).toList(),
    };
  }

  GameProfile copyWith({
    String? userId,
    int? totalPoints,
    int? currentStreak,
    int? longestStreak,
    List<String>? unlockedBadges,
    Map<String, int>? actionCounts,
    DateTime? lastLoginDate,
    List<ActionHistory>? recentActions,
  }) {
    return GameProfile(
      userId: userId ?? this.userId,
      totalPoints: totalPoints ?? this.totalPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      actionCounts: actionCounts ?? this.actionCounts,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      recentActions: recentActions ?? this.recentActions,
    );
  }
}

/// Historique des actions
class ActionHistory {
  final String id;
  final String userId;
  final ActionType action;
  final int points;
  final DateTime timestamp;
  final String? targetId;
  final String? description;

  ActionHistory({
    required this.id,
    required this.userId,
    required this.action,
    required this.points,
    required this.timestamp,
    this.targetId,
    this.description,
  });

  factory ActionHistory.fromJson(Map<String, dynamic> json) {
    return ActionHistory(
      id: json['id'],
      userId: json['userId'],
      action: ActionType.values.firstWhere(
        (e) => e.toString() == json['action'],
        orElse: () => ActionType.addPerson,
      ),
      points: json['points'] ?? 0,
      timestamp: DateTime.parse(json['timestamp']),
      targetId: json['targetId'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'action': action.toString(),
      'points': points,
      'timestamp': timestamp.toIso8601String(),
      'targetId': targetId,
      'description': description,
    };
  }
}

/// Badges prédéfinis
class BadgesCollection {
  static const List<Badge> allBadges = [
    // Badges d'action
    Badge(
      id: 'first_person',
      title: 'Premiers Pas',
      description: 'Ajouter votre première personne',
      iconPath: 'assets/badges/first_person.png',
      color: Colors.green,
      pointsRequired: 10,
      type: BadgeType.action,
    ),
    Badge(
      id: 'photo_master',
      title: 'Photographe',
      description: 'Ajouter 10 photos',
      iconPath: 'assets/badges/photo_master.png',
      color: Colors.blue,
      pointsRequired: 50,
      type: BadgeType.action,
    ),
    Badge(
      id: 'union_creator',
      title: 'Cupidon',
      description: 'Créer 5 unions',
      iconPath: 'assets/badges/union_creator.png',
      color: Colors.pink,
      pointsRequired: 75,
      type: BadgeType.action,
    ),
    
    // Badges de série
    Badge(
      id: 'week_warrior',
      title: 'Guerrier de la Semaine',
      description: 'Connexion 7 jours d\'affilée',
      iconPath: 'assets/badges/week_warrior.png',
      color: Colors.orange,
      pointsRequired: 14,
      type: BadgeType.streak,
    ),
    Badge(
      id: 'month_master',
      title: 'Maître du Mois',
      description: 'Connexion 30 jours d\'affilée',
      iconPath: 'assets/badges/month_master.png',
      color: Colors.red,
      pointsRequired: 60,
      type: BadgeType.streak,
    ),
    
    // Badges sociaux
    Badge(
      id: 'social_butterfly',
      title: 'Papillon Social',
      description: 'Partager 10 profils',
      iconPath: 'assets/badges/social_butterfly.png',
      color: Colors.purple,
      pointsRequired: 30,
      type: BadgeType.social,
    ),
    Badge(
      id: 'commentator',
      title: 'Commentateur',
      description: 'Faire 25 commentaires',
      iconPath: 'assets/badges/commentator.png',
      color: Colors.teal,
      pointsRequired: 50,
      type: BadgeType.social,
    ),
    
    // Badges de jalons
    Badge(
      id: 'centurion',
      title: 'Centurion',
      description: 'Atteindre 100 points',
      iconPath: 'assets/badges/centurion.png',
      color: Colors.amber,
      pointsRequired: 100,
      type: BadgeType.milestone,
    ),
    Badge(
      id: 'millennium',
      title: 'Millennium',
      description: 'Atteindre 1000 points',
      iconPath: 'assets/badges/millennium.png',
      color: Colors.indigo,
      pointsRequired: 1000,
      type: BadgeType.milestone,
    ),
  ];

  static Badge? getBadgeById(String id) {
    try {
      return allBadges.firstWhere((badge) => badge.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<Badge> getUnlockedBadges(List<String> badgeIds) {
    return allBadges.where((badge) => badgeIds.contains(badge.id)).toList();
  }

  static List<Badge> getAvailableBadges(List<String> badgeIds, int userPoints) {
    return allBadges.where((badge) => 
        !badgeIds.contains(badge.id) && 
        userPoints >= badge.pointsRequired
    ).toList();
  }
}
