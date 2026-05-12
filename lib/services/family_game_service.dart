import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/family_game.dart';

/// Service pour gérer les mini-jeux familiaux
class FamilyGameService {
  static final FamilyGameService _instance = FamilyGameService._internal();
  factory FamilyGameService() => _instance;
  FamilyGameService._internal();

  final List<FamilyGame> _games = [];
  final List<GameInvitation> _invitations = [];
  final Map<String, GameStats> _userStats = {};
  final StreamController<List<FamilyGame>> _gamesController = 
      StreamController<List<FamilyGame>>.broadcast();
  final StreamController<List<GameInvitation>> _invitationsController = 
      StreamController<List<GameInvitation>>.broadcast();
  
  List<FamilyGame> get games => List.unmodifiable(_games);
  List<GameInvitation> get invitations => List.unmodifiable(_invitations);
  Stream<List<FamilyGame>> get gamesStream => _gamesController.stream;
  Stream<List<GameInvitation>> get invitationsStream => _invitationsController.stream;

  // Auth service temporaire
  dynamic _authService;

  /// Initialiser le service
  Future<void> initialize() async {
    _authService = _TempAuthService();
    await _loadGames();
    await _loadInvitations();
    await _loadUserStats();
    _startCleanupTimer();
  }

  /// Charger tous les jeux
  Future<void> _loadGames() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final gamesFile = File(path.join(directory.path, 'family_games.json'));
      
      _games.clear();
      
      if (await gamesFile.exists()) {
        final content = await gamesFile.readAsString();
        
        if (content.isNotEmpty) {
          try {
            final lines = content.split('\n').where((s) => s.isNotEmpty).toList();
            
            for (final line in lines) {
              try {
                final Map<String, dynamic> gameJson = jsonDecode(line.trim()) as Map<String, dynamic>;
                final game = FamilyGame.fromJson(gameJson);
                _games.add(game);
              } catch (e) {
                debugPrint('Erreur parsing game: $e');
              }
            }
            
            _games.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            debugPrint('Family games chargés: ${_games.length}');
          } catch (e) {
            debugPrint('Erreur parsing games JSON: $e');
            await gamesFile.writeAsString('');
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des games: $e');
      _games.clear();
    }
  }

  /// Charger les invitations
  Future<void> _loadInvitations() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final invitationsFile = File(path.join(directory.path, 'game_invitations.json'));
      
      _invitations.clear();
      
      if (await invitationsFile.exists()) {
        final content = await invitationsFile.readAsString();
        
        if (content.isNotEmpty) {
          try {
            final lines = content.split('\n').where((s) => s.isNotEmpty).toList();
            
            for (final line in lines) {
              try {
                final Map<String, dynamic> invitationJson = jsonDecode(line.trim()) as Map<String, dynamic>;
                final invitation = GameInvitation.fromJson(invitationJson);
                _invitations.add(invitation);
              } catch (e) {
                debugPrint('Erreur parsing invitation: $e');
              }
            }
            
            _invitations.sort((a, b) => b.sentAt.compareTo(a.sentAt));
            debugPrint('Game invitations chargées: ${_invitations.length}');
          } catch (e) {
            debugPrint('Erreur parsing invitations JSON: $e');
            await invitationsFile.writeAsString('');
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des invitations: $e');
      _invitations.clear();
    }
  }

  /// Charger les statistiques utilisateur
  Future<void> _loadUserStats() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final statsFile = File(path.join(directory.path, 'game_stats.json'));
      
      _userStats.clear();
      
      if (await statsFile.exists()) {
        final content = await statsFile.readAsString();
        
        if (content.isNotEmpty) {
          try {
            final Map<String, dynamic> statsJson = jsonDecode(content) as Map<String, dynamic>;
            
            for (final entry in statsJson.entries) {
              final stats = GameStats.fromJson(entry.value as Map<String, dynamic>);
              _userStats[entry.key] = stats;
            }
            
            debugPrint('Game stats chargées: ${_userStats.length}');
          } catch (e) {
            debugPrint('Erreur parsing stats JSON: $e');
            await statsFile.writeAsString('{}');
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des stats: $e');
      _userStats.clear();
    }
  }

  /// Sauvegarder les jeux
  Future<void> _saveGames() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final gamesFile = File(path.join(directory.path, 'family_games.json'));
      
      final gamesJson = _games.map((g) => jsonEncode(g.toJson())).join('\n');
      await gamesFile.writeAsString(gamesJson);
      debugPrint('Family games sauvegardés: ${_games.length}');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des games: $e');
    }
  }

  /// Sauvegarder les invitations
  Future<void> _saveInvitations() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final invitationsFile = File(path.join(directory.path, 'game_invitations.json'));
      
      final invitationsJson = _invitations.map((i) => jsonEncode(i.toJson())).join('\n');
      await invitationsFile.writeAsString(invitationsJson);
      debugPrint('Game invitations sauvegardées: ${_invitations.length}');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des invitations: $e');
    }
  }

  /// Sauvegarder les statistiques
  Future<void> _saveUserStats() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final statsFile = File(path.join(directory.path, 'game_stats.json'));
      
      final statsJson = <String, dynamic>{};
      for (final entry in _userStats.entries) {
        statsJson[entry.key] = entry.value.toJson();
      }
      
      await statsFile.writeAsString(jsonEncode(statsJson));
      debugPrint('Game stats sauvegardées: ${_userStats.length}');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des stats: $e');
    }
  }

  /// Créer un nouveau jeu
  Future<FamilyGame?> createGame({
    required String title,
    required String description,
    required FamilyGameType type,
    required GameDifficulty difficulty,
    int maxParticipants = 10,
    int minParticipants = 2,
    int timeLimit = 300,
    List<GameQuestion>? questions,
    List<GameReward>? rewards,
    bool isPublic = true,
    bool allowSpectators = true,
    DateTime? expiresAt,
  }) async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        debugPrint('Utilisateur non connecté');
        return null;
      }

      final game = FamilyGame(
        id: const Uuid().v4(),
        title: title,
        description: description,
        type: type,
        difficulty: difficulty,
        createdAt: DateTime.now(),
        creatorId: user['id'] as String,
        participantIds: [user['id'] as String],
        maxParticipants: maxParticipants,
        minParticipants: minParticipants,
        timeLimit: timeLimit,
        questions: questions ?? _generateDefaultQuestions(type),
        rewards: rewards ?? _generateDefaultRewards(type),
        isPublic: isPublic,
        allowSpectators: allowSpectators,
        expiresAt: expiresAt,
      );

      _games.insert(0, game);
      await _saveGames();
      _gamesController.add(_games);
      
      debugPrint('Family game créé: ${game.id}');
      return game;
    } catch (e) {
      debugPrint('Erreur lors de la création du game: $e');
      return null;
    }
  }

  /// Rejoindre un jeu
  Future<bool> joinGame(String gameId, String userId) async {
    try {
      final index = _games.indexWhere((g) => g.id == gameId);
      if (index == -1) return false;

      final game = _games[index];
      if (!game.canJoin(userId)) return false;

      final updatedGame = game.copyWith(
        participantIds: [...game.participantIds, userId],
      );

      _games[index] = updatedGame;
      await _saveGames();
      _gamesController.add(_games);
      
      debugPrint('Utilisateur $userId a rejoint le jeu $gameId');
      return true;
    } catch (e) {
      debugPrint('Erreur lors du join game: $e');
      return false;
    }
  }

  /// Quitter un jeu
  Future<bool> leaveGame(String gameId, String userId) async {
    try {
      final index = _games.indexWhere((g) => g.id == gameId);
      if (index == -1) return false;

      final game = _games[index];
      if (!game.participantIds.contains(userId)) return false;

      final updatedGame = game.copyWith(
        participantIds: game.participantIds.where((id) => id != userId).toList(),
      );

      _games[index] = updatedGame;
      await _saveGames();
      _gamesController.add(_games);
      
      debugPrint('Utilisateur $userId a quitté le jeu $gameId');
      return true;
    } catch (e) {
      debugPrint('Erreur lors du leave game: $e');
      return false;
    }
  }

  /// Démarrer un jeu
  Future<bool> startGame(String gameId) async {
    try {
      final index = _games.indexWhere((g) => g.id == gameId);
      if (index == -1) return false;

      final game = _games[index];
      if (!game.canStart) return false;

      final updatedGame = game.copyWith(
        status: GameStatus.playing,
        startedAt: DateTime.now(),
        currentRound: 1,
        rounds: _generateRounds(game),
      );

      _games[index] = updatedGame;
      await _saveGames();
      _gamesController.add(_games);
      
      debugPrint('Jeu $gameId démarré');
      return true;
    } catch (e) {
      debugPrint('Erreur lors du start game: $e');
      return false;
    }
  }

  /// Terminer un jeu
  Future<bool> finishGame(String gameId) async {
    try {
      final index = _games.indexWhere((g) => g.id == gameId);
      if (index == -1) return false;

      final game = _games[index];
      if (!game.isPlaying) return false;

      // Calculer le gagnant
      final winnerId = _calculateWinner(game);
      
      // Créer les résultats
      final results = _generateGameResults(game, winnerId);

      final updatedGame = game.copyWith(
        status: GameStatus.finished,
        finishedAt: DateTime.now(),
        winnerId: winnerId,
        results: results,
      );

      _games[index] = updatedGame;
      await _saveGames();
      _gamesController.add(_games);
      
      // Mettre à jour les statistiques
      await _updateGameStats(updatedGame);
      
      debugPrint('Jeu $gameId terminé, gagnant: $winnerId');
      return true;
    } catch (e) {
      debugPrint('Erreur lors du finish game: $e');
      return false;
    }
  }

  /// Inviter un utilisateur à un jeu
  Future<bool> inviteUser(String gameId, String receiverId, {String? message}) async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) return false;

      final game = _games.firstWhere((g) => g.id == gameId);
      if (!game.canJoin(receiverId)) return false;

      final invitation = GameInvitation(
        id: const Uuid().v4(),
        gameId: gameId,
        senderId: user['id'] as String,
        receiverId: receiverId,
        message: message ?? 'Rejoignez-moi pour jouer à "${game.title}" !',
        sentAt: DateTime.now(),
      );

      _invitations.insert(0, invitation);
      await _saveInvitations();
      _invitationsController.add(_invitations);
      
      debugPrint('Invitation envoyée: $receiverId -> $gameId');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'invitation: $e');
      return false;
    }
  }

  /// Répondre à une invitation
  Future<bool> respondToInvitation(String invitationId, bool accept) async {
    try {
      final index = _invitations.indexWhere((i) => i.id == invitationId);
      if (index == -1) return false;

      final invitation = _invitations[index];
      if (!invitation.isPending) return false;

      final updatedInvitation = invitation.copyWith(
        respondedAt: DateTime.now(),
        isAccepted: accept,
        isDeclined: !accept,
      );

      _invitations[index] = updatedInvitation;
      await _saveInvitations();
      _invitationsController.add(_invitations);

      if (accept) {
        await joinGame(invitation.gameId, invitation.receiverId);
      }
      
      debugPrint('Invitation $invitationId: ${accept ? "acceptée" : "déclinée"}');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la réponse à l\'invitation: $e');
      return false;
    }
  }

  /// Obtenir les jeux disponibles
  List<FamilyGame> getAvailableGames({String? userId}) {
    return _games.where((game) {
      if (userId != null && !game.canJoin(userId)) return false;
      return game.status == GameStatus.waiting && game.isPublic;
    }).toList();
  }

  /// Obtenir les jeux d'un utilisateur
  List<FamilyGame> getUserGames(String userId) {
    return _games.where((game) => 
        game.participantIds.contains(userId) || game.creatorId == userId).toList();
  }

  /// Obtenir les invitations d'un utilisateur
  List<GameInvitation> getUserInvitations(String userId) {
    return _invitations.where((invitation) => 
        invitation.receiverId == userId && invitation.isPending).toList();
  }

  /// Obtenir les statistiques d'un utilisateur
  GameStats? getUserStats(String userId) {
    return _userStats[userId];
  }

  /// Obtenir le leaderboard global
  List<MapEntry<String, GameStats>> getGlobalLeaderboard({int limit = 10}) {
    final sortedStats = _userStats.entries.toList()
      ..sort((a, b) => b.value.totalPoints.compareTo(a.value.totalPoints));
    return sortedStats.take(limit).toList();
  }

  /// Obtenir le leaderboard pour un type de jeu
  List<MapEntry<String, GameStats>> getTypeLeaderboard(FamilyGameType type, {int limit = 10}) {
    final filteredStats = _userStats.entries.where((entry) =>
        entry.value.gamesByType.containsKey(type)).toList();
    
    filteredStats.sort((a, b) => b.value.gamesByType[type]!.compareTo(a.value.gamesByType[type]!));
    return filteredStats.take(limit).toList();
  }

  /// Générer des questions par défaut
  List<GameQuestion> _generateDefaultQuestions(FamilyGameType type) {
    switch (type) {
      case FamilyGameType.quiz:
        return [
          GameQuestion(
            id: const Uuid().v4(),
            question: 'Quel est le nom de famille de votre grand-mère maternelle ?',
            options: ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
            correctAnswer: 'Option 1',
            explanation: 'C\'est une question sur votre famille',
          ),
          GameQuestion(
            id: const Uuid().v4(),
            question: 'En quelle année vos parents se sont-ils mariés ?',
            options: ['1990', '1995', '2000', '2005'],
            correctAnswer: '1995',
            explanation: 'Date importante pour votre famille',
          ),
        ];
      
      case FamilyGameType.memory:
        return [
          GameQuestion(
            id: const Uuid().v4(),
            question: 'Retrouvez la paire correspondante',
            options: ['Photo A', 'Photo B', 'Photo C', 'Photo D'],
            correctAnswer: 'Photo A',
            explanation: 'Memory game classique',
          ),
        ];
      
      case FamilyGameType.timeline:
        return [
          GameQuestion(
            id: const Uuid().v4(),
            question: 'Quel événement s\'est produit en premier ?',
            options: ['Naissance', 'Mariage', 'Diplôme', 'Voyage'],
            correctAnswer: 'Naissance',
            explanation: 'Ordre chronologique',
          ),
        ];
      
      default:
        return [];
    }
  }

  /// Générer des récompenses par défaut
  List<GameReward> _generateDefaultRewards(FamilyGameType type) {
    return [
      GameReward(
        id: const Uuid().v4(),
        title: 'Champion de quiz',
        description: 'Gagnant d\'un quiz familial',
        type: RewardType.badge,
        value: 100,
        iconUrl: 'assets/icons/quiz_winner.png',
      ),
      GameReward(
        id: const Uuid().v4(),
        title: 'Points de participation',
        description: 'Points pour avoir participé',
        type: RewardType.points,
        value: 50,
      ),
    ];
  }

  /// Générer les manches du jeu
  List<GameRound> _generateRounds(FamilyGame game) {
    final rounds = <GameRound>[];
    final totalQuestions = game.questions.length;
    final questionsPerRound = math.max(1, totalQuestions ~/ 3);
    
    for (int i = 0; i < 3; i++) {
      final startIndex = i * questionsPerRound;
      final endIndex = math.min(startIndex + questionsPerRound, totalQuestions);
      
      if (startIndex < totalQuestions) {
        final round = GameRound(
          id: const Uuid().v4(),
          roundNumber: i + 1,
          title: 'Manche ${i + 1}',
          description: 'Questions ${startIndex + 1} à ${endIndex}',
          questionIds: game.questions
              .sublist(startIndex, endIndex)
              .map((q) => q.id)
              .toList(),
          startTime: DateTime.now(),
        );
        rounds.add(round);
      }
    }
    
    return rounds;
  }

  /// Calculer le gagnant
  String? _calculateWinner(FamilyGame game) {
    if (game.scores.isEmpty) return null;
    
    final sortedScores = game.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedScores.first.key;
  }

  /// Générer les résultats du jeu
  List<GameResult> _generateGameResults(FamilyGame game, String? winnerId) {
    final results = <GameResult>[];
    final sortedScores = game.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (int i = 0; i < sortedScores.length; i++) {
      final entry = sortedScores[i];
      final result = GameResult(
        id: const Uuid().v4(),
        userId: entry.key,
        gameId: game.id,
        finalScore: entry.value,
        position: i + 1,
        completedAt: DateTime.now(),
        statistics: {
          'correctAnswers': entry.value ~/ 10, // Approximation
          'totalQuestions': game.questions.length,
          'accuracy': (entry.value / (game.questions.length * 10)) * 100,
        },
      );
      results.add(result);
    }
    
    return results;
  }

  /// Mettre à jour les statistiques après un jeu
  Future<void> _updateGameStats(FamilyGame game) async {
    for (final participant in game.participantIds) {
      final score = game.scores[participant] ?? 0;
      final isWinner = game.winnerId == participant;
      
      // Obtenir ou créer les stats
      var stats = _userStats[participant];
      if (stats == null) {
        stats = GameStats(
          userId: participant,
          lastPlayed: DateTime.now(),
        );
        _userStats[participant] = stats;
      }
      
      // Mettre à jour les stats
      final updatedStats = stats.copyWith(
        totalGamesPlayed: stats.totalGamesPlayed + 1,
        totalGamesWon: stats.totalGamesWon + (isWinner ? 1 : 0),
        totalGamesLost: stats.totalGamesLost + (isWinner ? 0 : 1),
        totalPoints: stats.totalPoints + score,
        averageScore: (stats.totalPoints + score) / (stats.totalGamesPlayed + 1),
        lastPlayed: DateTime.now(),
        currentStreak: isWinner ? stats.currentStreak + 1 : 0,
        bestStreak: math.max(stats.bestStreak, isWinner ? stats.currentStreak + 1 : 0),
        gamesByType: {
          ...stats.gamesByType,
          game.type: (stats.gamesByType[game.type] ?? 0) + 1,
        },
        gamesByDifficulty: {
          ...stats.gamesByDifficulty,
          game.difficulty: (stats.gamesByDifficulty[game.difficulty] ?? 0) + 1,
        },
      );
      
      _userStats[participant] = updatedStats;
    }
    
    await _saveUserStats();
  }

  /// Démarrer le timer de nettoyage
  void _startCleanupTimer() {
    Timer.periodic(const Duration(hours: 1), (timer) {
      _cleanupExpiredGames();
      _cleanupOldInvitations();
    });
  }

  /// Nettoyer les jeux expirés
  Future<void> _cleanupExpiredGames() async {
    try {
      final now = DateTime.now();
      final initialCount = _games.length;
      
      _games.removeWhere((game) => 
          game.expiresAt != null && game.expiresAt!.isBefore(now));

      if (_games.length != initialCount) {
        await _saveGames();
        _gamesController.add(_games);
        debugPrint('Nettoyage games: ${initialCount - _games.length} jeux expirés supprimés');
      }
    } catch (e) {
      debugPrint('Erreur lors du nettoyage des games: $e');
    }
  }

  /// Nettoyer les anciennes invitations
  Future<void> _cleanupOldInvitations() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      final initialCount = _invitations.length;
      
      _invitations.removeWhere((invitation) => 
          invitation.sentAt.isBefore(cutoffDate) && invitation.isPending);

      if (_invitations.length != initialCount) {
        await _saveInvitations();
        _invitationsController.add(_invitations);
        debugPrint('Nettoyage invitations: ${initialCount - _invitations.length} invitations anciennes supprimées');
      }
    } catch (e) {
      debugPrint('Erreur lors du nettoyage des invitations: $e');
    }
  }

  /// Libérer les ressources
  void dispose() {
    _gamesController.close();
    _invitationsController.close();
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
