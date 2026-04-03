import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/utilisateur.dart';
import '../database/database_helper.dart';

class AuthLocalService {
  static final AuthLocalService _instance = AuthLocalService._internal();
  factory AuthLocalService() => _instance;
  AuthLocalService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Utilisateur? _currentUser;
  static const String _currentUserKey = 'current_user_id';
  static const String _sessionTimeoutKey = 'session_timeout';
  static const Duration _sessionTimeout = Duration(days: 7);

  // Getters
  Utilisateur? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.estAdmin ?? false;

  // Hashage du mot de passe avec SHA-256 + salt
  String hashPassword(String password) {
    final salt = _generateSalt();
    final bytes = utf8.encode(password + salt);
    final hash = sha256.convert(bytes);
    return '$salt:${hash.toString()}';
  }

  // Vérification du mot de passe
  bool verifyPassword(String password, String hashedPassword) {
    final parts = hashedPassword.split(':');
    if (parts.length != 2) return false;
    
    final salt = parts[0];
    final storedHash = parts[1];
    
    final bytes = utf8.encode(password + salt);
    final computedHash = sha256.convert(bytes).toString();
    
    return computedHash == storedHash;
  }

  // Génération de salt
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  // Inscription d'un nouvel utilisateur
  Future<bool> register({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    String role = 'member',
    String? questionSecrete,
    String? reponseSecrete,
  }) async {
    try {
      final db = await _dbHelper.database;
      
      // Vérifier si l'email existe déjà
      final existingUser = await db.query(
        'utilisateurs',
        where: 'email = ?',
        whereArgs: [email],
      );
      
      if (existingUser.isNotEmpty) {
        throw Exception('Cet email est déjà utilisé');
      }

      // Créer le nouvel utilisateur
      final utilisateur = Utilisateur(
        id: _generateId(),
        email: email,
        motDePasse: hashPassword(password),
        nom: nom,
        prenom: prenom,
        role: role,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        questionSecrete: questionSecrete,
        reponseSecrete: reponseSecrete != null ? hashPassword(reponseSecrete) : null,
      );

      await db.insert('utilisateurs', utilisateur.toMap());
      
      return true;
    } catch (e) {
      print('Erreur lors de l\'inscription: $e');
      return false;
    }
  }

  // Connexion
  Future<bool> login(String email, String password) async {
    try {
      final db = await _dbHelper.database;
      
      final result = await db.query(
        'utilisateurs',
        where: 'email = ?',
        whereArgs: [email],
      );
      
      if (result.isEmpty) {
        throw Exception('Email ou mot de passe incorrect');
      }

      final utilisateur = Utilisateur.fromMap(result.first);
      
      if (!verifyPassword(password, utilisateur.motDePasse)) {
        throw Exception('Email ou mot de passe incorrect');
      }

      // Mettre à jour l'état de connexion
      final updatedUser = utilisateur.copyWith(
        estConnecte: true,
        derniereConnexion: DateTime.now().millisecondsSinceEpoch,
      );

      await db.update(
        'utilisateurs',
        updatedUser.toMap(),
        where: 'id = ?',
        whereArgs: [utilisateur.id],
      );

      // Déconnecter les autres utilisateurs
      await db.update(
        'utilisateurs',
        {'est_connecte': 0},
        where: 'id != ?',
        whereArgs: [utilisateur.id],
      );

      // Sauvegarder la session
      _currentUser = updatedUser;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, updatedUser.id);
      await prefs.setInt(_sessionTimeoutKey, 
        DateTime.now().add(_sessionTimeout).millisecondsSinceEpoch);

      return true;
    } catch (e) {
      print('Erreur lors de la connexion: $e');
      return false;
    }
  }

  // Déconnexion
  Future<void> logout() async {
    try {
      if (_currentUser != null) {
        final db = await _dbHelper.database;
        
        await db.update(
          'utilisateurs',
          {'est_connecte': 0},
          where: 'id = ?',
          whereArgs: [_currentUser!.id],
        );
      }

      _currentUser = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      await prefs.remove(_sessionTimeoutKey);
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
    }
  }

  // Vérification de la session au démarrage
  Future<bool> checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_currentUserKey);
      final sessionTimeout = prefs.getInt(_sessionTimeoutKey);

      if (userId == null || sessionTimeout == null) {
        return false;
      }

      // Vérifier si la session n'a pas expiré
      if (DateTime.now().millisecondsSinceEpoch > sessionTimeout) {
        await logout();
        return false;
      }

      final db = await _dbHelper.database;
      final result = await db.query(
        'utilisateurs',
        where: 'id = ? AND est_connecte = 1',
        whereArgs: [userId],
      );

      if (result.isEmpty) {
        await logout();
        return false;
      }

      _currentUser = Utilisateur.fromMap(result.first);
      
      // Étendre la session
      await prefs.setInt(_sessionTimeoutKey, 
        DateTime.now().add(_sessionTimeout).millisecondsSinceEpoch);

      return true;
    } catch (e) {
      print('Erreur lors de la vérification de session: $e');
      return false;
    }
  }

  // Récupération de l'utilisateur courant
  Future<Utilisateur?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    final hasSession = await checkSession();
    return hasSession ? _currentUser : null;
  }

  // Réinitialisation du mot de passe
  Future<bool> resetPassword(String email, String reponseSecrete, String newPassword) async {
    try {
      final db = await _dbHelper.database;
      
      final result = await db.query(
        'utilisateurs',
        where: 'email = ?',
        whereArgs: [email],
      );
      
      if (result.isEmpty) {
        throw Exception('Aucun utilisateur trouvé avec cet email');
      }

      final utilisateur = Utilisateur.fromMap(result.first);
      
      if (utilisateur.questionSecrete == null || utilisateur.reponseSecrete == null) {
        throw Exception('Aucune question secrète configurée pour cet utilisateur');
      }

      if (!verifyPassword(reponseSecrete, utilisateur.reponseSecrete!)) {
        throw Exception('Réponse incorrecte');
      }

      // Mettre à jour le mot de passe
      final updatedUser = utilisateur.copyWith(
        motDePasse: hashPassword(newPassword),
      );

      await db.update(
        'utilisateurs',
        updatedUser.toMap(),
        where: 'id = ?',
        whereArgs: [utilisateur.id],
      );

      return true;
    } catch (e) {
      print('Erreur lors de la réinitialisation du mot de passe: $e');
      return false;
    }
  }

  // Liste des questions secrètes
  static const List<String> questionsSecretes = [
    'Quel est le nom de votre premier animal de compagnie ?',
    'Dans quelle ville êtes-vous né(e) ?',
    'Quel est le nom de votre professeur préféré ?',
    'Quelle est votre couleur préférée ?',
    'Quel est le plat préféré de votre enfance ?',
    'Quel est le nom de votre meilleure amie d\'enfance ?',
  ];

  // Génération d'ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(9999).toString().padLeft(4, '0');
  }

  // Liste des utilisateurs (pour admin)
  Future<List<Utilisateur>> getAllUsers() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query('utilisateurs', orderBy: 'created_at DESC');
      return result.map((map) => Utilisateur.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
      return [];
    }
  }

  // Suppression d'un utilisateur (admin uniquement)
  Future<bool> deleteUser(String userId) async {
    try {
      if (!isAdmin) {
        throw Exception('Droits insuffisants');
      }

      if (_currentUser?.id == userId) {
        throw Exception('Impossible de supprimer votre propre compte');
      }

      final db = await _dbHelper.database;
      await db.delete('utilisateurs', where: 'id = ?', whereArgs: [userId]);
      
      return true;
    } catch (e) {
      print('Erreur lors de la suppression de l\'utilisateur: $e');
      return false;
    }
  }
}
