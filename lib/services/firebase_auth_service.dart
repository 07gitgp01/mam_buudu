import 'package:firebase_auth/firebase_auth.dart';
import '../models/utilisateur.dart';

/// Service d'authentification Firebase pour Mam Buudu
class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  /// Stream d'authentification pour écouter les changements d'état
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Utilisateur actuellement connecté
  User? get currentUser => _auth.currentUser;

  /// Vérifie si un utilisateur est connecté
  bool get isUserConnected => _auth.currentUser != null;

  /// Récupère l'utilisateur actuel avec ses informations complètes
  Future<Utilisateur?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    return Utilisateur(
      id: user.uid,
      email: user.email ?? '',
      nomComplet: user.displayName ?? 'Utilisateur',
      photoUrl: user.photoURL,
      dateCreation: user.metadata.creationTime ?? DateTime.now(),
      dernierConnexion: user.metadata.lastSignInTime ?? DateTime.now(),
      estVerifie: user.emailVerified,
    );
  }

  /// Inscription avec email et mot de passe
  Future<Utilisateur> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String nomComplet,
  }) async {
    try {
      // Créer le compte utilisateur
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      
      // Mettre à jour le profil avec le nom
      await user.updateDisplayName(nomComplet);
      
      // Envoyer l'email de vérification
      await user.sendEmailVerification();

      return Utilisateur(
        id: user.uid,
        email: user.email ?? email,
        nomComplet: nomComplet,
        photoUrl: user.photoURL,
        dateCreation: user.metadata.creationTime ?? DateTime.now(),
        dernierConnexion: user.metadata.lastSignInTime ?? DateTime.now(),
        estVerifie: user.emailVerified,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription: $e');
    }
  }

  /// Connexion avec email et mot de passe
  Future<Utilisateur> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      
      return Utilisateur(
        id: user.uid,
        email: user.email ?? email,
        nomComplet: user.displayName ?? 'Utilisateur',
        photoUrl: user.photoURL,
        dateCreation: user.metadata.creationTime ?? DateTime.now(),
        dernierConnexion: user.metadata.lastSignInTime ?? DateTime.now(),
        estVerifie: user.emailVerified,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de la connexion: $e');
    }
  }

  /// Connexion avec Google
  Future<Utilisateur> signInWithGoogle() async {
    try {
      // TODO: Implémenter l'authentification Google
      // Nécessite google_sign_in package
      throw Exception('Connexion Google non implémentée encore');
    } catch (e) {
      throw Exception('Erreur lors de la connexion Google: $e');
    }
  }

  /// Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de la réinitialisation du mot de passe: $e');
    }
  }

  /// Mise à jour du profil utilisateur
  Future<void> updateProfile({
    String? nomComplet,
    String? photoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Aucun utilisateur connecté');

      if (nomComplet != null) {
        await user.updateDisplayName(nomComplet);
      }
      
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }

  /// Vérification de l'email
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Aucun utilisateur connecté');
      
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'email de vérification: $e');
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }

  /// Suppression du compte
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Aucun utilisateur connecté');
      
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du compte: $e');
    }
  }

  /// Gestion des exceptions FirebaseAuth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Le mot de passe est trop faible (minimum 6 caractères)';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé par un autre compte';
      case 'user-not-found':
        return 'Aucun utilisateur trouvé pour cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'invalid-email':
        return 'Format d\'email invalide';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'too-many-requests':
        return 'Trop de tentatives de connexion. Veuillez réessayer plus tard';
      case 'operation-not-allowed':
        return 'Opération non autorisée';
      case 'network-request-failed':
        return 'Erreur de connexion réseau';
      default:
        return 'Erreur d\'authentification: ${e.message}';
    }
  }

  /// Vérifier si l'email est déjà utilisé
  Future<bool> isEmailAlreadyUsed(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Changer le mot de passe
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Aucun utilisateur connecté');
      
      // Réauthentifier l'utilisateur avec le mot de passe actuel
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Changer le mot de passe
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors du changement de mot de passe: $e');
    }
  }
}
