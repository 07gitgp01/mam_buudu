import 'dart:ui';

/// Types de mini-jeux familiaux
enum FamilyGameType {
  quiz,           // Quiz de connaissance familiale
  memory,         // Memory game avec photos
  timeline,       // Timeline game
  challenge,      // Défis familiaux
  creative,       // Jeux créatifs
  collaborative,  // Jeux collaboratifs
  tournament,     // Tournois
  scavenger,      // Chasses au trésor
}

/// Difficulté des jeux
enum GameDifficulty {
  easy,           // Facile
  medium,         // Moyen
  hard,           // Difficile
  expert,         // Expert
}

/// Statut d'un jeu
enum GameStatus {
  waiting,        // En attente de joueurs
  playing,        // En cours
  paused,         // En pause
  finished,       // Terminé
  cancelled,      // Annulé
}

/// Type de récompense
enum RewardType {
  points,         // Points
  badge,          // Badge
  title,          // Titre spécial
  avatar,         // Avatar personnalisé
  feature,        // Fonctionnalité débloquée
}

/// Mini-jeu familial
class FamilyGame {
  final String id;
  final String title;
  final String description;
  final FamilyGameType type;
  final GameDifficulty difficulty;
  final GameStatus status;
  
  // Dates
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime? expiresAt;
  
  // Participants
  final List<String> participantIds;
  final String creatorId;
  final int maxParticipants;
  final int minParticipants;
  
  // Configuration du jeu
  final Map<String, dynamic> gameConfig;
  final List<GameQuestion> questions;
  final List<GameRound> rounds;
  final int currentRound;
  
  // Scores et résultats
  final Map<String, int> scores;
  final String? winnerId;
  final List<GameResult> results;
  
  // Récompenses
  final List<GameReward> rewards;
  final Map<String, List<String>> earnedRewards; // userId -> rewardIds
  
  // Paramètres
  final bool isPublic;
  final bool allowSpectators;
  final int timeLimit; // en secondes
  final List<String> requiredItems; // items nécessaires pour le jeu
  
  const FamilyGame({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    this.status = GameStatus.waiting,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
    this.expiresAt,
    this.participantIds = const [],
    required this.creatorId,
    this.maxParticipants = 10,
    this.minParticipants = 2,
    this.gameConfig = const {},
    this.questions = const [],
    this.rounds = const [],
    this.currentRound = 0,
    this.scores = const {},
    this.winnerId,
    this.results = const [],
    this.rewards = const [],
    this.earnedRewards = const {},
    this.isPublic = true,
    this.allowSpectators = true,
    this.timeLimit = 300, // 5 minutes par défaut
    this.requiredItems = const [],
  });

  /// Créer un jeu depuis JSON
  factory FamilyGame.fromJson(Map<String, dynamic> json) {
    return FamilyGame(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: FamilyGameType.values.firstWhere(
        (e) => e.toString() == 'FamilyGameType.${json['type']}',
        orElse: () => FamilyGameType.quiz,
      ),
      difficulty: GameDifficulty.values.firstWhere(
        (e) => e.toString() == 'GameDifficulty.${json['difficulty']}',
        orElse: () => GameDifficulty.medium,
      ),
      status: GameStatus.values.firstWhere(
        (e) => e.toString() == 'GameStatus.${json['status']}',
        orElse: () => GameStatus.waiting,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'] as String) : null,
      finishedAt: json['finishedAt'] != null ? DateTime.parse(json['finishedAt'] as String) : null,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
      participantIds: List<String>.from(json['participantIds'] as List? ?? []),
      creatorId: json['creatorId'] as String,
      maxParticipants: json['maxParticipants'] as int? ?? 10,
      minParticipants: json['minParticipants'] as int? ?? 2,
      gameConfig: Map<String, dynamic>.from(json['gameConfig'] as Map? ?? {}),
      questions: (json['questions'] as List?)
          ?.map((q) => GameQuestion.fromJson(q as Map<String, dynamic>))
          .toList() ?? [],
      rounds: (json['rounds'] as List?)
          ?.map((r) => GameRound.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
      currentRound: json['currentRound'] as int? ?? 0,
      scores: Map<String, int>.from(json['scores'] as Map? ?? {}),
      winnerId: json['winnerId'] as String?,
      results: (json['results'] as List?)
          ?.map((r) => GameResult.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
      rewards: (json['rewards'] as List?)
          ?.map((r) => GameReward.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
      earnedRewards: Map<String, List<String>>.from(json['earnedRewards'] as Map? ?? {}),
      isPublic: json['isPublic'] as bool? ?? true,
      allowSpectators: json['allowSpectators'] as bool? ?? true,
      timeLimit: json['timeLimit'] as int? ?? 300,
      requiredItems: List<String>.from(json['requiredItems'] as List? ?? []),
    );
  }

  /// Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'finishedAt': finishedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'participantIds': participantIds,
      'creatorId': creatorId,
      'maxParticipants': maxParticipants,
      'minParticipants': minParticipants,
      'gameConfig': gameConfig,
      'questions': questions.map((q) => q.toJson()).toList(),
      'rounds': rounds.map((r) => r.toJson()).toList(),
      'currentRound': currentRound,
      'scores': scores,
      'winnerId': winnerId,
      'results': results.map((r) => r.toJson()).toList(),
      'rewards': rewards.map((r) => r.toJson()).toList(),
      'earnedRewards': earnedRewards,
      'isPublic': isPublic,
      'allowSpectators': allowSpectators,
      'timeLimit': timeLimit,
      'requiredItems': requiredItems,
    };
  }

  /// Copier avec modifications
  FamilyGame copyWith({
    String? id,
    String? title,
    String? description,
    FamilyGameType? type,
    GameDifficulty? difficulty,
    GameStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    DateTime? expiresAt,
    List<String>? participantIds,
    String? creatorId,
    int? maxParticipants,
    int? minParticipants,
    Map<String, dynamic>? gameConfig,
    List<GameQuestion>? questions,
    List<GameRound>? rounds,
    int? currentRound,
    Map<String, int>? scores,
    String? winnerId,
    List<GameResult>? results,
    List<GameReward>? rewards,
    Map<String, List<String>>? earnedRewards,
    bool? isPublic,
    bool? allowSpectators,
    int? timeLimit,
    List<String>? requiredItems,
  }) {
    return FamilyGame(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      participantIds: participantIds ?? this.participantIds,
      creatorId: creatorId ?? this.creatorId,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      minParticipants: minParticipants ?? this.minParticipants,
      gameConfig: gameConfig ?? this.gameConfig,
      questions: questions ?? this.questions,
      rounds: rounds ?? this.rounds,
      currentRound: currentRound ?? this.currentRound,
      scores: scores ?? this.scores,
      winnerId: winnerId ?? this.winnerId,
      results: results ?? this.results,
      rewards: rewards ?? this.rewards,
      earnedRewards: earnedRewards ?? this.earnedRewards,
      isPublic: isPublic ?? this.isPublic,
      allowSpectators: allowSpectators ?? this.allowSpectators,
      timeLimit: timeLimit ?? this.timeLimit,
      requiredItems: requiredItems ?? this.requiredItems,
    );
  }

  /// Vérifier si le jeu peut commencer
  bool get canStart => 
      participantIds.length >= minParticipants &&
      participantIds.length <= maxParticipants &&
      status == GameStatus.waiting;

  /// Vérifier si le jeu est terminé
  bool get isFinished => status == GameStatus.finished;

  /// Vérifier si le jeu est en cours
  bool get isPlaying => status == GameStatus.playing;

  /// Obtenir le nombre de participants
  int get participantCount => participantIds.length;

  /// Vérifier si l'utilisateur peut rejoindre
  bool canJoin(String userId) => 
      !participantIds.contains(userId) &&
      participantIds.length < maxParticipants &&
      status == GameStatus.waiting;

  /// Obtenir le score d'un participant
  int? getScore(String userId) => scores[userId];

  /// Obtenir le classement
  List<MapEntry<String, int>> get leaderboard {
    final sortedScores = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedScores;
  }

  /// Obtenir l'icône par défaut pour le type de jeu
  String get defaultIcon {
    switch (type) {
      case FamilyGameType.quiz:
        return 'quiz';
      case FamilyGameType.memory:
        return 'memory';
      case FamilyGameType.timeline:
        return 'timeline';
      case FamilyGameType.challenge:
        return 'emoji_events';
      case FamilyGameType.creative:
        return 'brush';
      case FamilyGameType.collaborative:
        return 'groups';
      case FamilyGameType.tournament:
        return 'military_tech';
      case FamilyGameType.scavenger:
        return 'search';
    }
  }

  /// Obtenir la couleur par défaut pour le type de jeu
  Color get defaultColor {
    switch (type) {
      case FamilyGameType.quiz:
        return const Color(0xFF9C27B0); // Violet
      case FamilyGameType.memory:
        return const Color(0xFF2196F3); // Bleu
      case FamilyGameType.timeline:
        return const Color(0xFFFF9800); // Orange
      case FamilyGameType.challenge:
        return const Color(0xFFF44336); // Rouge
      case FamilyGameType.creative:
        return const Color(0xFF4CAF50); // Vert
      case FamilyGameType.collaborative:
        return const Color(0xFF607D8B); // Bleu gris
      case FamilyGameType.tournament:
        return const Color(0xFFFFD700); // Or
      case FamilyGameType.scavenger:
        return const Color(0xFF795548); // Marron
    }
  }

  @override
  String toString() {
    return 'FamilyGame(id: $id, title: $title, type: $type, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FamilyGame && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Question de jeu
class GameQuestion {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final int points;
  final int timeLimit; // en secondes
  final Map<String, dynamic> metadata; // images, sons, etc.

  const GameQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.points = 10,
    this.timeLimit = 30,
    this.metadata = const {},
  });

  factory GameQuestion.fromJson(Map<String, dynamic> json) {
    return GameQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List? ?? []),
      correctAnswer: json['correctAnswer'] as String,
      explanation: json['explanation'] as String?,
      points: json['points'] as int? ?? 10,
      timeLimit: json['timeLimit'] as int? ?? 30,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'points': points,
      'timeLimit': timeLimit,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameQuestion && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Manche de jeu
class GameRound {
  final String id;
  final int roundNumber;
  final String title;
  final String description;
  final List<String> questionIds;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, int> roundScores; // userId -> score
  final Map<String, dynamic> roundConfig;

  const GameRound({
    required this.id,
    required this.roundNumber,
    required this.title,
    required this.description,
    required this.questionIds,
    required this.startTime,
    this.endTime,
    this.roundScores = const {},
    this.roundConfig = const {},
  });

  factory GameRound.fromJson(Map<String, dynamic> json) {
    return GameRound(
      id: json['id'] as String,
      roundNumber: json['roundNumber'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      questionIds: List<String>.from(json['questionIds'] as List? ?? []),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      roundScores: Map<String, int>.from(json['roundScores'] as Map? ?? {}),
      roundConfig: Map<String, dynamic>.from(json['roundConfig'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roundNumber': roundNumber,
      'title': title,
      'description': description,
      'questionIds': questionIds,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'roundScores': roundScores,
      'roundConfig': roundConfig,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameRound && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Résultat de jeu
class GameResult {
  final String id;
  final String userId;
  final String gameId;
  final int finalScore;
  final int position;
  final DateTime completedAt;
  final Map<String, dynamic> statistics; // temps, bonnes réponses, etc.
  final List<String> earnedRewardIds;

  const GameResult({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.finalScore,
    required this.position,
    required this.completedAt,
    this.statistics = const {},
    this.earnedRewardIds = const [],
  });

  factory GameResult.fromJson(Map<String, dynamic> json) {
    return GameResult(
      id: json['id'] as String,
      userId: json['userId'] as String,
      gameId: json['gameId'] as String,
      finalScore: json['finalScore'] as int,
      position: json['position'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
      statistics: Map<String, dynamic>.from(json['statistics'] as Map? ?? {}),
      earnedRewardIds: List<String>.from(json['earnedRewardIds'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'gameId': gameId,
      'finalScore': finalScore,
      'position': position,
      'completedAt': completedAt.toIso8601String(),
      'statistics': statistics,
      'earnedRewardIds': earnedRewardIds,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameResult && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Récompense de jeu
class GameReward {
  final String id;
  final String title;
  final String description;
  final RewardType type;
  final int value; // points, niveau, etc.
  final String? iconUrl;
  final String? imageUrl;
  final Map<String, dynamic> rewardData; // données spécifiques au type

  const GameReward({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    this.iconUrl,
    this.imageUrl,
    this.rewardData = const {},
  });

  factory GameReward.fromJson(Map<String, dynamic> json) {
    return GameReward(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: RewardType.values.firstWhere(
        (e) => e.toString() == 'RewardType.${json['type']}',
        orElse: () => RewardType.points,
      ),
      value: json['value'] as int,
      iconUrl: json['iconUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      rewardData: Map<String, dynamic>.from(json['rewardData'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'value': value,
      'iconUrl': iconUrl,
      'imageUrl': imageUrl,
      'rewardData': rewardData,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameReward && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Invitation à un jeu
class GameInvitation {
  final String id;
  final String gameId;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime sentAt;
  final DateTime? respondedAt;
  final bool isAccepted;
  final bool isDeclined;

  const GameInvitation({
    required this.id,
    required this.gameId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.sentAt,
    this.respondedAt,
    this.isAccepted = false,
    this.isDeclined = false,
  });

  factory GameInvitation.fromJson(Map<String, dynamic> json) {
    return GameInvitation(
      id: json['id'] as String,
      gameId: json['gameId'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      message: json['message'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt'] as String) : null,
      isAccepted: json['isAccepted'] as bool? ?? false,
      isDeclined: json['isDeclined'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameId': gameId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'sentAt': sentAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'isAccepted': isAccepted,
      'isDeclined': isDeclined,
    };
  }

  /// Vérifier si l'invitation est en attente
  bool get isPending => !isAccepted && !isDeclined;

  /// Copier avec modifications
  GameInvitation copyWith({
    String? id,
    String? gameId,
    String? senderId,
    String? receiverId,
    String? message,
    DateTime? sentAt,
    DateTime? respondedAt,
    bool? isAccepted,
    bool? isDeclined,
  }) {
    return GameInvitation(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      sentAt: sentAt ?? this.sentAt,
      respondedAt: respondedAt ?? this.respondedAt,
      isAccepted: isAccepted ?? this.isAccepted,
      isDeclined: isDeclined ?? this.isDeclined,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameInvitation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Statistiques de jeu pour un utilisateur
class GameStats {
  final String userId;
  final int totalGamesPlayed;
  final int totalGamesWon;
  final int totalGamesLost;
  final int totalPoints;
  final double averageScore;
  final Map<FamilyGameType, int> gamesByType;
  final Map<GameDifficulty, int> gamesByDifficulty;
  final List<String> badges;
  final List<String> titles;
  final DateTime lastPlayed;
  final int currentStreak;
  final int bestStreak;

  const GameStats({
    required this.userId,
    this.totalGamesPlayed = 0,
    this.totalGamesWon = 0,
    this.totalGamesLost = 0,
    this.totalPoints = 0,
    this.averageScore = 0.0,
    this.gamesByType = const {},
    this.gamesByDifficulty = const {},
    this.badges = const [],
    this.titles = const [],
    required this.lastPlayed,
    this.currentStreak = 0,
    this.bestStreak = 0,
  });

  factory GameStats.fromJson(Map<String, dynamic> json) {
    return GameStats(
      userId: json['userId'] as String,
      totalGamesPlayed: json['totalGamesPlayed'] as int? ?? 0,
      totalGamesWon: json['totalGamesWon'] as int? ?? 0,
      totalGamesLost: json['totalGamesLost'] as int? ?? 0,
      totalPoints: json['totalPoints'] as int? ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      gamesByType: Map<FamilyGameType, int>.from(
        (json['gamesByType'] as Map? ?? {}).map(
          (key, value) => MapEntry(
            FamilyGameType.values.firstWhere(
              (e) => e.toString() == 'FamilyGameType.$key',
              orElse: () => FamilyGameType.quiz,
            ),
            value as int,
          ),
        ),
      ),
      gamesByDifficulty: Map<GameDifficulty, int>.from(
        (json['gamesByDifficulty'] as Map? ?? {}).map(
          (key, value) => MapEntry(
            GameDifficulty.values.firstWhere(
              (e) => e.toString() == 'GameDifficulty.$key',
              orElse: () => GameDifficulty.medium,
            ),
            value as int,
          ),
        ),
      ),
      badges: List<String>.from(json['badges'] as List? ?? []),
      titles: List<String>.from(json['titles'] as List? ?? []),
      lastPlayed: DateTime.parse(json['lastPlayed'] as String),
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalGamesPlayed': totalGamesPlayed,
      'totalGamesWon': totalGamesWon,
      'totalGamesLost': totalGamesLost,
      'totalPoints': totalPoints,
      'averageScore': averageScore,
      'gamesByType': gamesByType.map((key, value) => MapEntry(key.toString().split('.').last, value)),
      'gamesByDifficulty': gamesByDifficulty.map((key, value) => MapEntry(key.toString().split('.').last, value)),
      'badges': badges,
      'titles': titles,
      'lastPlayed': lastPlayed.toIso8601String(),
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
    };
  }

  /// Calculer le taux de victoire
  double get winRate => totalGamesPlayed > 0 ? totalGamesWon / totalGamesPlayed : 0.0;

  /// Obtenir le type de jeu préféré
  FamilyGameType? get favoriteGameType {
    if (gamesByType.isEmpty) return null;
    return gamesByType.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Obtenir la difficulté préférée
  GameDifficulty? get favoriteDifficulty {
    if (gamesByDifficulty.isEmpty) return null;
    return gamesByDifficulty.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Copier avec modifications
  GameStats copyWith({
    String? userId,
    int? totalGamesPlayed,
    int? totalGamesWon,
    int? totalGamesLost,
    int? totalPoints,
    double? averageScore,
    Map<FamilyGameType, int>? gamesByType,
    Map<GameDifficulty, int>? gamesByDifficulty,
    List<String>? badges,
    List<String>? titles,
    DateTime? lastPlayed,
    int? currentStreak,
    int? bestStreak,
  }) {
    return GameStats(
      userId: userId ?? this.userId,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalGamesWon: totalGamesWon ?? this.totalGamesWon,
      totalGamesLost: totalGamesLost ?? this.totalGamesLost,
      totalPoints: totalPoints ?? this.totalPoints,
      averageScore: averageScore ?? this.averageScore,
      gamesByType: gamesByType ?? this.gamesByType,
      gamesByDifficulty: gamesByDifficulty ?? this.gamesByDifficulty,
      badges: badges ?? this.badges,
      titles: titles ?? this.titles,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameStats && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
