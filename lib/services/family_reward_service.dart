import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/family_reward.dart';
import '../models/family_game.dart';

/// Service pour gérer le système de récompenses familiales
class FamilyRewardService {
  static final FamilyRewardService _instance = FamilyRewardService._internal();
  factory FamilyRewardService() => _instance;
  FamilyRewardService._internal();

  final List<FamilyReward> _rewards = [];
  final Map<String, UserRewardInventory> _userInventories = {};
  final List<RewardTransaction> _transactions = [];
  final List<RewardNotification> _notifications = [];
  RewardSystemConfig? _config;
  
  final StreamController<List<FamilyReward>> _rewardsController = 
      StreamController<List<FamilyReward>>.broadcast();
  final StreamController<UserRewardInventory?> _inventoryController = 
      StreamController<UserRewardInventory?>.broadcast();
  final StreamController<List<RewardNotification>> _notificationsController = 
      StreamController<List<RewardNotification>>.broadcast();
  
  List<FamilyReward> get rewards => List.unmodifiable(_rewards);
  Stream<List<FamilyReward>> get rewardsStream => _rewardsController.stream;
  Stream<UserRewardInventory?> get inventoryStream => _inventoryController.stream;
  Stream<List<RewardNotification>> get notificationsStream => _notificationsController.stream;

  // Auth service temporaire
  dynamic _authService;

  /// Initialiser le service
  Future<void> initialize() async {
    _authService = _TempAuthService();
    await _loadRewards();
    await _loadUserInventories();
    await _loadTransactions();
    await _loadNotifications();
    await _loadConfig();
    await _createDefaultRewards();
    _startCleanupTimer();
  }

  /// Charger les récompenses
  Future<void> _loadRewards() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final rewardsFile = File(path.join(directory.path, 'family_rewards.json'));
      
      _rewards.clear();
      
      if (await rewardsFile.exists()) {
        final content = await rewardsFile.readAsString();
        
        if (content.isNotEmpty) {
          try {
            final lines = content.split('\n').where((s) => s.isNotEmpty).toList();
            
            for (final line in lines) {
              try {
                final Map<String, dynamic> rewardJson = jsonDecode(line.trim()) as Map<String, dynamic>;
                final reward = FamilyReward.fromJson(rewardJson);
                _rewards.add(reward);
              } catch (e) {
                debugPrint('Erreur parsing reward: $e');
              }
            }
            
            debugPrint('Family rewards chargées: ${_rewards.length}');
          } catch (e) {
            debugPrint('Erreur parsing rewards JSON: $e');
            await rewardsFile.writeAsString('');
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des rewards: $e');
      _rewards.clear();
    }
  }

  /// Charger les inventaires utilisateurs
  Future<void> _loadUserInventories() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final inventoriesFile = File(path.join(directory.path, 'user_reward_inventories.json'));
      
      _userInventories.clear();
      
      if (await inventoriesFile.exists()) {
        final content = await inventoriesFile.readAsString();
        
        if (content.isNotEmpty) {
          try {
            final Map<String, dynamic> inventoriesJson = jsonDecode(content) as Map<String, dynamic>;
            
            for (final entry in inventoriesJson.entries) {
              final inventory = UserRewardInventory.fromJson(entry.value as Map<String, dynamic>);
              _userInventories[entry.key] = inventory;
            }
            
            debugPrint('User inventories chargés: ${_userInventories.length}');
          } catch (e) {
            debugPrint('Erreur parsing inventories JSON: $e');
            await inventoriesFile.writeAsString('{}');
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des inventories: $e');
      _userInventories.clear();
    }
  }

  /// Charger les transactions
  Future<void> _loadTransactions() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final transactionsFile = File(path.join(directory.path, 'reward_transactions.json'));
      
      _transactions.clear();
      
      if (await transactionsFile.exists()) {
        final content = await transactionsFile.readAsString();
        
        if (content.isNotEmpty) {
          try {
            final lines = content.split('\n').where((s) => s.isNotEmpty).toList();
            
            for (final line in lines) {
              try {
                final Map<String, dynamic> transactionJson = jsonDecode(line.trim()) as Map<String, dynamic>;
                final transaction = RewardTransaction.fromJson(transactionJson);
                _transactions.add(transaction);
              } catch (e) {
                debugPrint('Erreur parsing transaction: $e');
              }
            }
            
            debugPrint('Reward transactions chargées: ${_transactions.length}');
          } catch (e) {
            debugPrint('Erreur parsing transactions JSON: $e');
            await transactionsFile.writeAsString('');
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des transactions: $e');
      _transactions.clear();
    }
  }

  /// Charger les notifications
  Future<void> _loadNotifications() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final notificationsFile = File(path.join(directory.path, 'reward_notifications.json'));
      
      _notifications.clear();
      
      if (await notificationsFile.exists()) {
        final content = await notificationsFile.readAsString();
        
        if (content.isNotEmpty) {
          try {
            final lines = content.split('\n').where((s) => s.isNotEmpty).toList();
            
            for (final line in lines) {
              try {
                final Map<String, dynamic> notificationJson = jsonDecode(line.trim()) as Map<String, dynamic>;
                final notification = RewardNotification.fromJson(notificationJson);
                _notifications.add(notification);
              } catch (e) {
                debugPrint('Erreur parsing notification: $e');
              }
            }
            
            debugPrint('Reward notifications chargées: ${_notifications.length}');
          } catch (e) {
            debugPrint('Erreur parsing notifications JSON: $e');
            await notificationsFile.writeAsString('');
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des notifications: $e');
      _notifications.clear();
    }
  }

  /// Charger la configuration
  Future<void> _loadConfig() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final configFile = File(path.join(directory.path, 'reward_config.json'));
      
      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        
        if (content.isNotEmpty) {
          try {
            final configJson = jsonDecode(content) as Map<String, dynamic>;
            _config = RewardSystemConfig.fromJson(configJson);
            debugPrint('Reward config chargée');
          } catch (e) {
            debugPrint('Erreur parsing config JSON: $e');
            _config = RewardSystemConfig(lastUpdated: DateTime.now());
          }
        }
      } else {
        _config = RewardSystemConfig(lastUpdated: DateTime.now());
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de la config: $e');
      _config = RewardSystemConfig(lastUpdated: DateTime.now());
    }
  }

  /// Créer les récompenses par défaut
  Future<void> _createDefaultRewards() async {
    if (_rewards.isNotEmpty) return;

    final defaultRewards = [
      // Récompenses de gaming
      FamilyReward(
        id: const Uuid().v4(),
        name: 'Première Victoire',
        description: 'Gagnez votre premier jeu familial',
        type: RewardType.badge,
        category: RewardCategory.gaming,
        rarity: RewardRarity.common,
        value: 50,
        requiredValue: 1,
        progressPercentage: 0.0,
        conditions: [RewardCondition.games_won],
        conditionData: {'required': 1},
        createdAt: DateTime.now(),
        color: const Color(0xFF4CAF50),
      ),
      
      FamilyReward(
        id: const Uuid().v4(),
        name: 'Maître du Quiz',
        description: 'Gagnez 10 jeux de quiz',
        type: RewardType.badge,
        category: RewardCategory.gaming,
        rarity: RewardRarity.rare,
        value: 200,
        requiredValue: 10,
        progressPercentage: 0.0,
        conditions: [RewardCondition.games_won],
        conditionData: {'required': 10, 'gameType': 'quiz'},
        createdAt: DateTime.now(),
        color: const Color(0xFF2196F3),
      ),
      
      // Récompenses de famille
      FamilyReward(
        id: const Uuid().v4(),
        name: 'Super Familial',
        description: 'Ajoutez 5 membres à votre famille',
        type: RewardType.title,
        category: RewardCategory.family,
        rarity: RewardRarity.rare,
        value: 100,
        requiredValue: 5,
        progressPercentage: 0.0,
        conditions: [RewardCondition.family_members],
        conditionData: {'required': 5},
        createdAt: DateTime.now(),
        color: const Color(0xFF2196F3),
      ),
      
      // Récompenses d'engagement
      FamilyReward(
        id: const Uuid().v4(),
        name: 'Connecté Quotidien',
        description: 'Connectez-vous 7 jours d\'affilée',
        type: RewardType.badge,
        category: RewardCategory.engagement,
        rarity: RewardRarity.common,
        value: 100,
        requiredValue: 7,
        progressPercentage: 0.0,
        conditions: [RewardCondition.streak_days],
        conditionData: {'required': 7},
        createdAt: DateTime.now(),
        color: const Color(0xFF4CAF50),
      ),
      
      // Récompenses de stories
      FamilyReward(
        id: const Uuid().v4(),
        name: 'Story Teller',
        description: 'Créez 10 stories familiales',
        type: RewardType.badge,
        category: RewardCategory.stories,
        rarity: RewardRarity.epic,
        value: 300,
        requiredValue: 10,
        progressPercentage: 0.0,
        conditions: [RewardCondition.stories_created],
        conditionData: {'required': 10},
        createdAt: DateTime.now(),
        color: const Color(0xFF9C27B0),
      ),
      
      // Récompenses de timeline
      FamilyReward(
        id: const Uuid().v4(),
        name: 'Historien Familial',
        description: 'Créez 20 événements timeline',
        type: RewardType.badge,
        category: RewardCategory.timeline,
        rarity: RewardRarity.epic,
        value: 400,
        requiredValue: 20,
        progressPercentage: 0.0,
        conditions: [RewardCondition.timeline_events],
        conditionData: {'required': 20},
        createdAt: DateTime.now(),
        color: const Color(0xFF9C27B0),
      ),
      
      // Récompenses de points
      FamilyReward(
        id: const Uuid().v4(),
        name: 'Collectionneur de Points',
        description: 'Accumulez 1000 points',
        type: RewardType.badge,
        category: RewardCategory.achievement,
        rarity: RewardRarity.legendary,
        value: 500,
        requiredValue: 1000,
        progressPercentage: 0.0,
        conditions: [RewardCondition.points_threshold],
        conditionData: {'required': 1000},
        createdAt: DateTime.now(),
        color: const Color(0xFFFF9800),
      ),
    ];

    _rewards.addAll(defaultRewards);
    await _saveRewards();
    _rewardsController.add(_rewards);
    
    debugPrint('Récompenses par défaut créées: ${defaultRewards.length}');
  }

  /// Sauvegarder les récompenses
  Future<void> _saveRewards() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final rewardsFile = File(path.join(directory.path, 'family_rewards.json'));
      
      final rewardsJson = _rewards.map((r) => jsonEncode(r.toJson())).join('\n');
      await rewardsFile.writeAsString(rewardsJson);
      debugPrint('Family rewards sauvegardées: ${_rewards.length}');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des rewards: $e');
    }
  }

  /// Sauvegarder les inventaires utilisateurs
  Future<void> _saveUserInventories() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final inventoriesFile = File(path.join(directory.path, 'user_reward_inventories.json'));
      
      final inventoriesJson = <String, dynamic>{};
      for (final entry in _userInventories.entries) {
        inventoriesJson[entry.key] = entry.value.toJson();
      }
      
      await inventoriesFile.writeAsString(jsonEncode(inventoriesJson));
      debugPrint('User inventories sauvegardées: ${_userInventories.length}');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des inventories: $e');
    }
  }

  /// Sauvegarder les transactions
  Future<void> _saveTransactions() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final transactionsFile = File(path.join(directory.path, 'reward_transactions.json'));
      
      final transactionsJson = _transactions.map((t) => jsonEncode(t.toJson())).join('\n');
      await transactionsFile.writeAsString(transactionsJson);
      debugPrint('Reward transactions sauvegardées: ${_transactions.length}');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des transactions: $e');
    }
  }

  /// Sauvegarder les notifications
  Future<void> _saveNotifications() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final notificationsFile = File(path.join(directory.path, 'reward_notifications.json'));
      
      final notificationsJson = _notifications.map((n) => jsonEncode(n.toJson())).join('\n');
      await notificationsFile.writeAsString(notificationsJson);
      debugPrint('Reward notifications sauvegardées: ${_notifications.length}');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des notifications: $e');
    }
  }

  /// Obtenir l'inventaire d'un utilisateur
  UserRewardInventory? getUserInventory(String userId) {
    return _userInventories[userId];
  }

  /// Obtenir les récompenses disponibles pour un utilisateur
  List<FamilyReward> getAvailableRewards(String userId) {
    final inventory = _userInventories[userId];
    if (inventory == null) return [];
    
    return _rewards.where((reward) {
      if (!reward.isVisible || !reward.isAvailable) return false;
      if (inventory.isRewardUnlocked(reward.id)) return false;
      return true;
    }).toList();
  }

  /// Obtenir les récompenses débloquées d'un utilisateur
  List<FamilyReward> getUserUnlockedRewards(String userId) {
    final inventory = _userInventories[userId];
    if (inventory == null) return [];
    
    return _rewards.where((reward) => 
        inventory.isRewardUnlocked(reward.id)).toList();
  }

  /// Ajouter des points à un utilisateur
  Future<bool> addPoints(String userId, int points, {String? reason}) async {
    try {
      if (points <= 0) return false;
      
      // Obtenir ou créer l'inventaire
      var inventory = _userInventories[userId];
      if (inventory == null) {
        inventory = UserRewardInventory(userId: userId, totalPoints: 0);
        _userInventories[userId] = inventory;
      }
      
      // Mettre à jour les points
      final updatedInventory = UserRewardInventory(
        userId: userId,
        unlockedRewardIds: inventory.unlockedRewardIds,
        claimedRewardIds: inventory.claimedRewardIds,
        activeRewardIds: inventory.activeRewardIds,
        rewardUnlockDates: inventory.rewardUnlockDates,
        rewardClaimDates: inventory.rewardClaimDates,
        totalPoints: inventory.totalPoints + points,
        pointsByCategory: inventory.pointsByCategory,
        equippedBadges: inventory.equippedBadges,
        activeTitle: inventory.activeTitle,
        activeAvatar: inventory.activeAvatar,
        activeTheme: inventory.activeTheme,
        activeFrame: inventory.activeFrame,
      );
      
      _userInventories[userId] = updatedInventory;
      
      // Créer la transaction
      final transaction = RewardTransaction(
        id: const Uuid().v4(),
        userId: userId,
        rewardId: 'points',
        type: RewardTransactionType.earned,
        amount: points,
        reason: reason ?? 'Points bonus',
        createdAt: DateTime.now(),
      );
      _transactions.insert(0, transaction);
      
      // Vérifier les récompenses débloquées
      await _checkUnlockedRewards(userId);
      
      // Sauvegarder
      await _saveUserInventories();
      await _saveTransactions();
      _inventoryController.add(updatedInventory);
      
      debugPrint('Points ajoutés: $userId +$points');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de points: $e');
      return false;
    }
  }

  /// Débloquer une récompense
  Future<bool> unlockReward(String userId, String rewardId) async {
    try {
      final reward = _rewards.firstWhere((r) => r.id == rewardId);
      final inventory = _userInventories[userId];
      if (inventory == null) return false;
      
      if (inventory.isRewardUnlocked(rewardId)) return false;
      
      // Mettre à jour l'inventaire
      final updatedInventory = UserRewardInventory(
        userId: userId,
        unlockedRewardIds: [...inventory.unlockedRewardIds, rewardId],
        claimedRewardIds: inventory.claimedRewardIds,
        activeRewardIds: inventory.activeRewardIds,
        rewardUnlockDates: {
          ...inventory.rewardUnlockDates,
          rewardId: DateTime.now(),
        },
        rewardClaimDates: inventory.rewardClaimDates,
        totalPoints: inventory.totalPoints,
        pointsByCategory: inventory.pointsByCategory,
        equippedBadges: inventory.equippedBadges,
        activeTitle: inventory.activeTitle,
        activeAvatar: inventory.activeAvatar,
        activeTheme: inventory.activeTheme,
        activeFrame: inventory.activeFrame,
      );
      
      _userInventories[userId] = updatedInventory;
      
      // Mettre à jour le statut de la récompense
      final rewardIndex = _rewards.indexWhere((r) => r.id == rewardId);
      if (rewardIndex != -1) {
        final updatedReward = reward.copyWith(
          status: RewardStatus.unlocked,
          unlockedAt: DateTime.now(),
        );
        _rewards[rewardIndex] = updatedReward;
      }
      
      // Créer la notification
      final notification = RewardNotification(
        id: const Uuid().v4(),
        userId: userId,
        rewardId: rewardId,
        type: RewardNotificationType.unlocked,
        title: 'Récompense Débloquée !',
        message: 'Félicitations ! Vous avez débloqué "${reward.name}"',
        createdAt: DateTime.now(),
        data: {'reward': reward.toJson()},
      );
      _notifications.insert(0, notification);
      
      // Sauvegarder
      await _saveUserInventories();
      await _saveRewards();
      await _saveNotifications();
      _inventoryController.add(updatedInventory);
      _rewardsController.add(_rewards);
      _notificationsController.add(_notifications);
      
      debugPrint('Récompense débloquée: $userId -> $rewardId');
      return true;
    } catch (e) {
      debugPrint('Erreur lors du déblocage de récompense: $e');
      return false;
    }
  }

  /// Réclamer une récompense
  Future<bool> claimReward(String userId, String rewardId) async {
    try {
      final reward = _rewards.firstWhere((r) => r.id == rewardId);
      final inventory = _userInventories[userId];
      if (inventory == null) return false;
      
      if (!inventory.isRewardUnlocked(rewardId)) return false;
      if (inventory.isRewardClaimed(rewardId)) return false;
      
      // Ajouter les points de la récompense
      if (reward.type == RewardType.points) {
        await addPoints(userId, reward.value, reason: reward.name);
      }
      
      // Mettre à jour l'inventaire
      final updatedInventory = UserRewardInventory(
        userId: userId,
        unlockedRewardIds: inventory.unlockedRewardIds,
        claimedRewardIds: [...inventory.claimedRewardIds, rewardId],
        activeRewardIds: [...inventory.activeRewardIds, rewardId],
        rewardUnlockDates: inventory.rewardUnlockDates,
        rewardClaimDates: {
          ...inventory.rewardClaimDates,
          rewardId: DateTime.now(),
        },
        totalPoints: inventory.totalPoints,
        pointsByCategory: inventory.pointsByCategory,
        equippedBadges: reward.type == RewardType.badge 
            ? [...inventory.equippedBadges, rewardId]
            : inventory.equippedBadges,
        activeTitle: reward.type == RewardType.title ? rewardId : inventory.activeTitle,
        activeAvatar: reward.type == RewardType.avatar ? rewardId : inventory.activeAvatar,
        activeTheme: reward.type == RewardType.theme ? rewardId : inventory.activeTheme,
        activeFrame: reward.type == RewardType.frame ? rewardId : inventory.activeFrame,
      );
      
      _userInventories[userId] = updatedInventory;
      
      // Mettre à jour le statut de la récompense
      final rewardIndex = _rewards.indexWhere((r) => r.id == rewardId);
      if (rewardIndex != -1) {
        final updatedReward = reward.copyWith(
          status: reward.type == RewardType.feature || reward.type == RewardType.theme 
              ? RewardStatus.active 
              : RewardStatus.claimed,
          claimedAt: DateTime.now(),
        );
        _rewards[rewardIndex] = updatedReward;
      }
      
      // Créer la notification
      final notification = RewardNotification(
        id: const Uuid().v4(),
        userId: userId,
        rewardId: rewardId,
        type: RewardNotificationType.claimed,
        title: 'Récompense Réclamée !',
        message: 'Vous avez réclamé "${reward.name}"',
        createdAt: DateTime.now(),
        data: {'reward': reward.toJson()},
      );
      _notifications.insert(0, notification);
      
      // Sauvegarder
      await _saveUserInventories();
      await _saveRewards();
      await _saveNotifications();
      _inventoryController.add(updatedInventory);
      _rewardsController.add(_rewards);
      _notificationsController.add(_notifications);
      
      debugPrint('Récompense réclamée: $userId -> $rewardId');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la réclamation de récompense: $e');
      return false;
    }
  }

  /// Mettre à jour la progression d'une récompense
  Future<bool> updateRewardProgress(String userId, String rewardId, int newValue) async {
    try {
      final rewardIndex = _rewards.indexWhere((r) => r.id == rewardId);
      if (rewardIndex == -1) return false;
      
      final reward = _rewards[rewardIndex];
      final progress = math.min(newValue, reward.requiredValue);
      final percentage = progress / reward.requiredValue;
      
      final updatedReward = reward.copyWith(
        currentValue: progress,
        progressPercentage: percentage,
      );
      
      _rewards[rewardIndex] = updatedReward;
      
      // Vérifier si la récompense est débloquée
      if (progress >= reward.requiredValue && !updatedReward.isUnlocked) {
        await unlockReward(userId, rewardId);
      }
      
      await _saveRewards();
      _rewardsController.add(_rewards);
      
      debugPrint('Progression mise à jour: $rewardId -> $progress/$reward.requiredValue');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de progression: $e');
      return false;
    }
  }

  /// Vérifier les récompenses débloquées
  Future<void> _checkUnlockedRewards(String userId) async {
    final inventory = _userInventories[userId];
    if (inventory == null) return;
    
    for (final reward in _rewards) {
      if (inventory.isRewardUnlocked(reward.id)) continue;
      
      bool shouldUnlock = false;
      
      // Vérifier les conditions
      for (final condition in reward.conditions) {
        switch (condition) {
          case RewardCondition.points_threshold:
            final required = reward.conditionData['required'] as int? ?? 0;
            if (inventory.totalPoints >= required) {
              shouldUnlock = true;
            }
            break;
            
          case RewardCondition.games_played:
            // TODO: Implémenter avec les stats de jeu
            break;
            
          case RewardCondition.games_won:
            // TODO: Implémenter avec les stats de jeu
            break;
            
          case RewardCondition.streak_days:
            // TODO: Implémenter avec les stats de connexion
            break;
            
          case RewardCondition.family_members:
            // TODO: Implémenter avec les stats familiales
            break;
            
          case RewardCondition.stories_created:
            // TODO: Implémenter avec les stats de stories
            break;
            
          case RewardCondition.timeline_events:
            // TODO: Implémenter avec les stats de timeline
            break;
        }
      }
      
      if (shouldUnlock) {
        await unlockReward(userId, reward.id);
      }
    }
  }

  /// Obtenir les notifications non lues d'un utilisateur
  List<RewardNotification> getUnreadNotifications(String userId) {
    return _notifications.where((n) => 
        n.userId == userId && !n.isRead).toList();
  }

  /// Marquer une notification comme lue
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index == -1) return false;
      
      final notification = _notifications[index];
      final updatedNotification = RewardNotification(
        id: notification.id,
        userId: notification.userId,
        rewardId: notification.rewardId,
        type: notification.type,
        title: notification.title,
        message: notification.message,
        createdAt: notification.createdAt,
        isRead: true,
        data: notification.data,
      );
      
      _notifications[index] = updatedNotification;
      await _saveNotifications();
      _notificationsController.add(_notifications);
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors du marquage de notification: $e');
      return false;
    }
  }

  /// Obtenir le leaderboard des points
  List<MapEntry<String, int>> getPointsLeaderboard({int limit = 10}) {
    final sortedEntries = _userInventories.entries.toList()
      ..sort((a, b) => b.value.totalPoints.compareTo(a.value.totalPoints));
    return sortedEntries.take(limit).map((entry) => 
        MapEntry(entry.key, entry.value.totalPoints)).toList();
  }

  /// Obtenir les statistiques globales
  Map<String, dynamic> getGlobalStats() {
    final totalRewards = _rewards.length;
    final unlockedRewards = _rewards.where((r) => r.isUnlocked).length;
    final totalUsers = _userInventories.length;
    final totalPoints = _userInventories.values
        .fold(0, (sum, inventory) => sum + inventory.totalPoints);
    
    return {
      'totalRewards': totalRewards,
      'unlockedRewards': unlockedRewards,
      'totalUsers': totalUsers,
      'totalPoints': totalPoints,
      'averagePointsPerUser': totalUsers > 0 ? totalPoints / totalUsers : 0,
      'rewardsByCategory': _getRewardsByCategory(),
      'rewardsByRarity': _getRewardsByRarity(),
    };
  }

  Map<String, int> _getRewardsByCategory() {
    final counts = <String, int>{};
    for (final category in RewardCategory.values) {
      counts[category.toString().split('.').last] = 0;
    }
    
    for (final reward in _rewards) {
      final categoryName = reward.category.toString().split('.').last;
      counts[categoryName] = (counts[categoryName] ?? 0) + 1;
    }
    
    return counts;
  }

  Map<String, int> _getRewardsByRarity() {
    final counts = <String, int>{};
    for (final rarity in RewardRarity.values) {
      counts[rarity.toString().split('.').last] = 0;
    }
    
    for (final reward in _rewards) {
      final rarityName = reward.rarity.toString().split('.').last;
      counts[rarityName] = (counts[rarityName] ?? 0) + 1;
    }
    
    return counts;
  }

  /// Démarrer le timer de nettoyage
  void _startCleanupTimer() {
    Timer.periodic(const Duration(hours: 1), (timer) {
      _cleanupExpiredRewards();
      _cleanupOldNotifications();
    });
  }

  /// Nettoyer les récompenses expirées
  Future<void> _cleanupExpiredRewards() async {
    try {
      final now = DateTime.now();
      final initialCount = _rewards.length;
      
      _rewards.removeWhere((reward) => 
          reward.expiresAt != null && reward.expiresAt!.isBefore(now));

      if (_rewards.length != initialCount) {
        await _saveRewards();
        _rewardsController.add(_rewards);
        debugPrint('Nettoyage rewards: ${initialCount - _rewards.length} récompenses expirées supprimées');
      }
    } catch (e) {
      debugPrint('Erreur lors du nettoyage des rewards: $e');
    }
  }

  /// Nettoyer les anciennes notifications
  Future<void> _cleanupOldNotifications() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final initialCount = _notifications.length;
      
      _notifications.removeWhere((notification) => 
          notification.createdAt.isBefore(cutoffDate) && notification.isRead);

      if (_notifications.length != initialCount) {
        await _saveNotifications();
        _notificationsController.add(_notifications);
        debugPrint('Nettoyage notifications: ${initialCount - _notifications.length} notifications anciennes supprimées');
      }
    } catch (e) {
      debugPrint('Erreur lors du nettoyage des notifications: $e');
    }
  }

  /// Libérer les ressources
  void dispose() {
    _rewardsController.close();
    _inventoryController.close();
    _notificationsController.close();
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
