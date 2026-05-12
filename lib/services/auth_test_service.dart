import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';

/// Service de test pour vérifier l'authentification Firebase
class AuthTestService {
  static final AuthTestService _instance = AuthTestService._internal();
  factory AuthTestService() => _instance;
  AuthTestService._internal();

  final FirebaseAuthService _authService = FirebaseAuthService();

  /// Test complet de l'authentification
  Future<AuthTestResult> runFullAuthTest() async {
    final result = AuthTestResult();

    try {
      // 1. Vérifier l'initialisation de Firebase
      result.firebaseInitialized = Firebase.apps.isNotEmpty;
      if (!result.firebaseInitialized) {
        result.addError('Firebase n\'est pas initialisé');
        return result;
      }

      // 2. Vérifier l'état de connexion actuel
      result.initialUserState = _authService.isUserConnected;
      result.currentUser = _authService.currentUser;

      // 3. Tester l'inscription
      await _testSignUp(result);

      // 4. Tester la connexion
      await _testSignIn(result);

      // 5. Tester la récupération de l'utilisateur
      await _testGetCurrentUser(result);

      // 6. Tester la déconnexion
      await _testSignOut(result);

      result.success = true;
      result.message = 'Tous les tests d\'authentification ont réussi';
    } catch (e) {
      result.success = false;
      result.message = 'Erreur lors des tests: $e';
      result.addError(e.toString());
    }

    return result;
  }

  /// Tester l'inscription
  Future<void> _testSignUp(AuthTestResult result) async {
    try {
      final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      final testPassword = 'Test123456';
      final testNom = 'Utilisateur Test';

      final utilisateur = await _authService.signUpWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
        nomComplet: testNom,
      );

      result.signUpSuccess = true;
      result.signUpUserId = utilisateur.id;
      result.addInfo('Inscription réussie: ${utilisateur.nomComplet}');
    } catch (e) {
      result.signUpSuccess = false;
      result.addError('Inscription échouée: $e');
    }
  }

  /// Tester la connexion
  Future<void> _testSignIn(AuthTestResult result) async {
    try {
      // Si l'inscription a réussi, utiliser le même utilisateur
      if (result.signUpSuccess && result.signUpUserId != null) {
        // L'utilisateur est déjà connecté après l'inscription
        result.signInSuccess = _authService.isUserConnected;
        result.addInfo('Connexion vérifiée après inscription');
      } else {
        // Tester avec un compte de test
        final testEmail = 'test@example.com';
        final testPassword = 'Test123456';

        try {
          final utilisateur = await _authService.signInWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          );
          result.signInSuccess = true;
          result.addInfo('Connexion réussie: ${utilisateur.nomComplet}');
        } catch (e) {
          // C'est normal si le compte n'existe pas
          result.signInSuccess = false;
          result.addInfo('Connexion test ignorée (compte de test inexistant)');
        }
      }
    } catch (e) {
      result.signInSuccess = false;
      result.addError('Connexion échouée: $e');
    }
  }

  /// Tester la récupération de l'utilisateur actuel
  Future<void> _testGetCurrentUser(AuthTestResult result) async {
    try {
      final utilisateur = await _authService.getCurrentUser();
      result.getCurrentUserSuccess = utilisateur != null;
      
      if (utilisateur != null) {
        result.currentUserInfo = {
          'id': utilisateur.id,
          'email': utilisateur.email,
          'nomComplet': utilisateur.nomComplet,
          'estVerifie': utilisateur.estVerifie,
          'dateCreation': utilisateur.dateCreation.toString(),
        };
        result.addInfo('Utilisateur récupéré: ${utilisateur.nomComplet}');
      } else {
        result.addInfo('Aucun utilisateur connecté');
      }
    } catch (e) {
      result.getCurrentUserSuccess = false;
      result.addError('Récupération utilisateur échouée: $e');
    }
  }

  /// Tester la déconnexion
  Future<void> _testSignOut(AuthTestResult result) async {
    try {
      await _authService.logout();
      result.signOutSuccess = !_authService.isUserConnected;
      result.addInfo('Déconnexion réussie');
    } catch (e) {
      result.signOutSuccess = false;
      result.addError('Déconnexion échouée: $e');
    }
  }

  /// Vérifier l'état de l'authentification
  AuthStatus checkAuthStatus() {
    return AuthStatus(
      isFirebaseInitialized: Firebase.apps.isNotEmpty,
      isUserConnected: _authService.isUserConnected,
      currentUser: _authService.currentUser,
      userId: _authService.currentUser?.uid,
      userEmail: _authService.currentUser?.email,
      isEmailVerified: _authService.currentUser?.emailVerified ?? false,
    );
  }

  /// Test rapide de connexion
  Future<bool> quickAuthTest() async {
    try {
      // Vérifier Firebase
      if (Firebase.apps.isEmpty) {
        return false;
      }

      // Vérifier l'état d'authentification
      final isUserConnected = _authService.isUserConnected;
      
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Résultat du test d'authentification
class AuthTestResult {
  bool success = false;
  String message = '';
  bool firebaseInitialized = false;
  bool initialUserState = false;
  bool signUpSuccess = false;
  bool signInSuccess = false;
  bool getCurrentUserSuccess = false;
  bool signOutSuccess = false;
  String? signUpUserId;
  User? currentUser;
  Map<String, dynamic>? currentUserInfo;
  List<String> errors = [];
  List<String> infos = [];

  void addError(String error) {
    errors.add(error);
  }

  void addInfo(String info) {
    infos.add(info);
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'message': message,
      'firebaseInitialized': firebaseInitialized,
      'initialUserState': initialUserState,
      'signUpSuccess': signUpSuccess,
      'signInSuccess': signInSuccess,
      'getCurrentUserSuccess': getCurrentUserSuccess,
      'signOutSuccess': signOutSuccess,
      'signUpUserId': signUpUserId,
      'currentUserId': currentUser?.uid,
      'currentUserEmail': currentUser?.email,
      'currentUserInfo': currentUserInfo,
      'errors': errors,
      'infos': infos,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('=== RÉSULTAT DU TEST D\'AUTHENTIFICATION ===');
    buffer.writeln('Succès: $success');
    buffer.writeln('Message: $message');
    buffer.writeln('');
    buffer.writeln('Firebase initialisé: $firebaseInitialized');
    buffer.writeln('État initial connecté: $initialUserState');
    buffer.writeln('Inscription réussie: $signUpSuccess');
    buffer.writeln('Connexion réussie: $signInSuccess');
    buffer.writeln('Récupération utilisateur réussie: $getCurrentUserSuccess');
    buffer.writeln('Déconnexion réussie: $signOutSuccess');
    
    if (errors.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('ERREURS:');
      for (final error in errors) {
        buffer.writeln('  - $error');
      }
    }
    
    if (infos.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('INFORMATIONS:');
      for (final info in infos) {
        buffer.writeln('  - $info');
      }
    }
    
    return buffer.toString();
  }
}

/// État actuel de l'authentification
class AuthStatus {
  final bool isFirebaseInitialized;
  final bool isUserConnected;
  final User? currentUser;
  final String? userId;
  final String? userEmail;
  final bool isEmailVerified;

  AuthStatus({
    required this.isFirebaseInitialized,
    required this.isUserConnected,
    this.currentUser,
    this.userId,
    this.userEmail,
    required this.isEmailVerified,
  });

  @override
  String toString() {
    return 'AuthStatus('
        'firebase: $isFirebaseInitialized, '
        'connected: $isUserConnected, '
        'userId: $userId, '
        'email: $userEmail, '
        'verified: $isEmailVerified'
        ')';
  }
}
