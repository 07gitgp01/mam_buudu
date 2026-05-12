import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/gamification.dart';
import '../services/auth_local_service.dart';

/// Service de gamification pour gérer les points, badges et achievements
class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  final AuthLocalService _authService = AuthLocalService();
  GameProfile? _currentProfile;
  final Map<String, GameProfile> _profiles = {};
  
  // Streams pour les notifications de gamification
  final _pointsController = StreamController<int>.broadcast();
  final _badgeController = StreamController<Badge>.broadcast();
  final _levelController = StreamController<GameLevel>.broadcast();
  final _streakController = StreamController<int>.broadcast();

  Stream<int> get pointsStream => _pointsController.stream;
  Stream<Badge> get badgeStream => _badgeController.stream;
  Stream<GameLevel> get levelStream => _levelController.stream;
  Stream<int> get streakStream => _streakController.stream;

  /// Vérifier si un utilisateur est connecté
  Future<bool> isUserConnected() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      return currentUser != null;
    } catch (e) {
      return false;
    }
  }

  /// Initialiser le profil de gamification
  Future<GameProfile> initializeProfile() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      final userId = currentUser.id;
      
      // Charger le profil existant ou en créer un nouveau
      if (_profiles.containsKey(userId)) {
        _currentProfile = _profiles[userId];
      } else {
        _currentProfile = await _loadProfile(userId);
        _profiles[userId] = _currentProfile!;
      }

      // Vérifier la connexion quotidienne
      await _checkDailyLogin();

      return _currentProfile!;
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du profil: $e');
      rethrow;
    }
  }

  /// Ajouter des points pour une action
  Future<void> addPoints({
    required ActionType action,
    String? targetId,
    String? description,
  }) async {
    try {
      if (_currentProfile == null) {
        await initializeProfile();
      }

      final profile = _currentProfile!;
      final points = action.points;
      
      // Créer l'historique d'action
      final actionHistory = ActionHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: profile.userId,
        action: action,
        points: points,
        timestamp: DateTime.now(),
        targetId: targetId,
        description: description,
      );

      // Mettre à jour le profil
      final oldPoints = profile.totalPoints;
      final oldLevel = profile.currentLevel;
      
      final newActionCounts = Map<String, int>.from(profile.actionCounts);
      newActionCounts[action.toString()] = (newActionCounts[action.toString()] ?? 0) + 1;

      final newRecentActions = List<ActionHistory>.from(profile.recentActions);
      newRecentActions.insert(0, actionHistory);
      
      // Garder seulement les 100 dernières actions
      if (newRecentActions.length > 100) {
        newRecentActions.removeRange(100, newRecentActions.length);
      }

      _currentProfile = profile.copyWith(
        totalPoints: oldPoints + points,
        actionCounts: newActionCounts,
        recentActions: newRecentActions,
      );

      _profiles[profile.userId] = _currentProfile!;

      // Sauvegarder le profil
      await _saveProfile(_currentProfile!);

      // Notifier les changements
      _pointsController.add(_currentProfile!.totalPoints);

      // Vérifier le changement de niveau
      final newLevel = _currentProfile!.currentLevel;
      if (newLevel != oldLevel) {
        _levelController.add(newLevel);
        await _checkLevelUpBadges(newLevel);
      }

      // Vérifier les nouveaux badges
      await _checkActionBadges(action, newActionCounts[action.toString()]!);

      debugPrint('Points ajoutés: $points pour l\'action ${action.title}');
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de points: $e');
    }
  }

  /// Vérifier la connexion quotidienne
  Future<void> _checkDailyLogin() async {
    try {
      if (_currentProfile == null) return;

      final profile = _currentProfile!;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      if (profile.lastLoginDate != null) {
        final lastLogin = DateTime(
          profile.lastLoginDate!.year,
          profile.lastLoginDate!.month,
          profile.lastLoginDate!.day,
        );

        if (lastLogin.isBefore(today)) {
          // Calculer la différence en jours
          final difference = today.difference(lastLogin).inDays;
          
          if (difference == 1) {
            // Connexion consécutive
            final newStreak = profile.currentStreak + 1;
            final newLongestStreak = max(newStreak, profile.longestStreak);
            
            _currentProfile = profile.copyWith(
              currentStreak: newStreak,
              longestStreak: newLongestStreak,
              lastLoginDate: now,
            );

            // Ajouter les points de connexion quotidienne
            await addPoints(
              action: ActionType.loginDaily,
              description: 'Connexion ${newStreak} jours d\'affilée',
            );

            _streakController.add(newStreak);
            
            // Vérifier les badges de série
            await _checkStreakBadges(newStreak);
          } else {
            // Série brisée
            _currentProfile = profile.copyWith(
              currentStreak: 1,
              lastLoginDate: now,
            );

            await addPoints(
              action: ActionType.loginDaily,
              description: 'Nouvelle série de connexions',
            );

            _streakController.add(1);
          }
        }
        // Si déjà connecté aujourd'hui, ne rien faire
      } else {
        // Première connexion
        _currentProfile = profile.copyWith(
          currentStreak: 1,
          lastLoginDate: now,
        );

        await addPoints(
          action: ActionType.loginDaily,
          description: 'Première connexion',
        );

        _streakController.add(1);
      }

      await _saveProfile(_currentProfile!);
    } catch (e) {
      debugPrint('Erreur lors de la vérification de connexion quotidienne: $e');
    }
  }

  /// Vérifier les badges d'action
  Future<void> _checkActionBadges(ActionType action, int count) async {
    try {
      if (_currentProfile == null) return;

      final profile = _currentProfile!;
      List<Badge> newBadges = [];

      // Vérifier les badges spécifiques à l'action
      switch (action) {
        case ActionType.addPerson:
          if (count == 1) {
            final badge = BadgesCollection.getBadgeById('first_person');
            if (badge != null && !profile.unlockedBadges.contains(badge.id)) {
              newBadges.add(badge);
            }
          }
          break;
        
        case ActionType.addPhoto:
          if (count >= 10) {
            final badge = BadgesCollection.getBadgeById('photo_master');
            if (badge != null && !profile.unlockedBadges.contains(badge.id)) {
              newBadges.add(badge);
            }
          }
          break;
        
        case ActionType.addUnion:
          if (count >= 5) {
            final badge = BadgesCollection.getBadgeById('union_creator');
            if (badge != null && !profile.unlockedBadges.contains(badge.id)) {
              newBadges.add(badge);
            }
          }
          break;
        
        case ActionType.addDocument:
          // Pas de badge spécifique pour l'ajout de documents pour l'instant
          break;
        
        case ActionType.loginDaily:
          // Pas de badge spécifique pour la connexion quotidienne (géré par streak)
          break;
        
        case ActionType.shareProfile:
          final shareCount = profile.actionCounts[ActionType.shareProfile.toString()] ?? 0;
          if (shareCount >= 10) {
            final badge = BadgesCollection.getBadgeById('social_butterfly');
            if (badge != null && !profile.unlockedBadges.contains(badge.id)) {
              newBadges.add(badge);
            }
          }
          break;
        
        case ActionType.comment:
          final commentCount = profile.actionCounts[ActionType.comment.toString()] ?? 0;
          if (commentCount >= 25) {
            final badge = BadgesCollection.getBadgeById('commentator');
            if (badge != null && !profile.unlockedBadges.contains(badge.id)) {
              newBadges.add(badge);
            }
          }
          break;
        
        case ActionType.like:
          // Pas de badge spécifique pour les likes pour l'instant
          break;
      }

      // Débloquer les nouveaux badges
      for (final badge in newBadges) {
        await _unlockBadge(badge);
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification des badges d\'action: $e');
    }
  }

  /// Vérifier les badges de série
  Future<void> _checkStreakBadges(int streak) async {
    try {
      if (_currentProfile == null) return;

      final profile = _currentProfile!;
      List<Badge> newBadges = [];

      if (streak >= 7) {
        final badge = BadgesCollection.getBadgeById('week_warrior');
        if (badge != null && !profile.unlockedBadges.contains(badge.id)) {
          newBadges.add(badge);
        }
      }

      if (streak >= 30) {
        final badge = BadgesCollection.getBadgeById('month_master');
        if (badge != null && !profile.unlockedBadges.contains(badge.id)) {
          newBadges.add(badge);
        }
      }

      // Débloquer les nouveaux badges
      for (final badge in newBadges) {
        await _unlockBadge(badge);
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification des badges de série: $e');
    }
  }

  /// Vérifier les badges de niveau
  Future<void> _checkLevelUpBadges(GameLevel level) async {
    try {
      if (_currentProfile == null) return;

      final profile = _currentProfile!;
      List<Badge> newBadges = [];

      if (profile.totalPoints >= 100) {
        final badge = BadgesCollection.getBadgeById('centurion');
        if (badge != null && !profile.unlockedBadges.contains(badge.id)) {
          newBadges.add(badge);
        }
      }

      if (profile.totalPoints >= 1000) {
        final badge = BadgesCollection.getBadgeById('millennium');
        if (badge != null && !profile.unlockedBadges.contains(badge.id)) {
          newBadges.add(badge);
        }
      }

      // Débloquer les nouveaux badges
      for (final badge in newBadges) {
        await _unlockBadge(badge);
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification des badges de niveau: $e');
    }
  }

  /// Débloquer un badge
  Future<void> _unlockBadge(Badge badge) async {
    try {
      if (_currentProfile == null) return;

      final profile = _currentProfile!;
      if (!profile.unlockedBadges.contains(badge.id)) {
        final newUnlockedBadges = List<String>.from(profile.unlockedBadges);
        newUnlockedBadges.add(badge.id);

        _currentProfile = profile.copyWith(
          unlockedBadges: newUnlockedBadges,
        );

        _profiles[profile.userId] = _currentProfile!;
        await _saveProfile(_currentProfile!);

        // Notifier le déblocage du badge
        _badgeController.add(badge);

        debugPrint('Badge débloqué: ${badge.title}');
      }
    } catch (e) {
      debugPrint('Erreur lors du déblocage du badge: $e');
    }
  }

  /// Obtenir le profil actuel
  GameProfile? get currentProfile => _currentProfile;

  /// Obtenir les statistiques de gamification
  Map<String, dynamic> getStatistics() {
    if (_currentProfile == null) return {};

    final profile = _currentProfile!;
    return {
      'totalPoints': profile.totalPoints,
      'currentLevel': profile.currentLevel.title,
      'levelProgress': profile.levelProgress,
      'pointsToNextLevel': profile.pointsToNextLevel,
      'currentStreak': profile.currentStreak,
      'longestStreak': profile.longestStreak,
      'unlockedBadgesCount': profile.unlockedBadges.length,
      'totalBadgesCount': BadgesCollection.allBadges.length,
      'recentActions': profile.recentActions.take(10).toList(),
      'actionCounts': profile.actionCounts,
    };
  }

  /// Charger un profil depuis le stockage local
  Future<GameProfile> _loadProfile(String userId) async {
    try {
      // Pour l'instant, retourner un profil vide
      // Dans une vraie implémentation, charger depuis SharedPreferences ou une base de données
      return GameProfile(userId: userId);
    } catch (e) {
      debugPrint('Erreur lors du chargement du profil: $e');
      return GameProfile(userId: userId);
    }
  }

  /// Sauvegarder un profil dans le stockage local
  Future<void> _saveProfile(GameProfile profile) async {
    try {
      // Pour l'instant, ne rien faire
      // Dans une vraie implémentation, sauvegarder dans SharedPreferences ou une base de données
      debugPrint('Profil sauvegardé pour l\'utilisateur ${profile.userId}');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du profil: $e');
    }
  }

  /// Réinitialiser le profil (pour les tests)
  void resetProfile() {
    if (_currentProfile != null) {
      _profiles.remove(_currentProfile!.userId);
      _currentProfile = null;
    }
  }

  /// Disposer les ressources
  void dispose() {
    _pointsController.close();
    _badgeController.close();
    _levelController.close();
    _streakController.close();
  }
}
