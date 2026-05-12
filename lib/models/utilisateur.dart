import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Utilisateur {
  final String id;
  final String email;
  final String nomComplet;
  final String? photoUrl;
  final DateTime dateCreation;
  final DateTime dernierConnexion;
  final bool estVerifie;
  final String? familleId;
  final String role; // 'admin', 'member', 'membre'
  final Map<String, dynamic> preferences;

  Utilisateur({
    required this.id,
    required this.email,
    required this.nomComplet,
    this.photoUrl,
    required this.dateCreation,
    required this.dernierConnexion,
    this.estVerifie = false,
    this.familleId,
    this.role = 'membre',
    this.preferences = const {},
  });

  // Getters
  bool get estAdmin => role == 'admin';
  bool get estMembre => role == 'membre';
  bool get estMember => role == 'member'; // Compatibilité

  // Extraire le nom et prénom du nom complet
  String? get prenom {
    final parts = nomComplet.trim().split(' ');
    return parts.isNotEmpty ? parts.first : null;
  }

  String? get nom {
    final parts = nomComplet.trim().split(' ');
    return parts.length > 1 ? parts.last : null;
  }

  // Factory constructor from Map (Firebase)
  factory Utilisateur.fromMap(Map<String, dynamic> map) {
    return Utilisateur(
      id: map['id'] as String,
      email: map['email'] as String,
      nomComplet: map['nom_complet'] as String? ?? 'Utilisateur',
      photoUrl: map['photo_url'] as String?,
      dateCreation: map['date_creation'] != null 
          ? (map['date_creation'] as Timestamp).toDate()
          : DateTime.now(),
      dernierConnexion: map['derniere_connexion'] != null
          ? (map['derniere_connexion'] as Timestamp).toDate()
          : DateTime.now(),
      estVerifie: map['est_verifie'] as bool? ?? false,
      familleId: map['famille_id'] as String?,
      role: map['role'] as String? ?? 'membre',
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
    );
  }

  // Convert to Map (Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'nom_complet': nomComplet,
      'photo_url': photoUrl,
      'date_creation': Timestamp.fromDate(dateCreation),
      'derniere_connexion': Timestamp.fromDate(dernierConnexion),
      'est_verifie': estVerifie,
      'famille_id': familleId,
      'role': role,
      'preferences': preferences,
    };
  }

  // Factory constructor from Firebase User
  factory Utilisateur.fromFirebaseUser(User user) {
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

  // Copy with
  Utilisateur copyWith({
    String? id,
    String? email,
    String? nomComplet,
    String? photoUrl,
    DateTime? dateCreation,
    DateTime? dernierConnexion,
    bool? estVerifie,
    String? familleId,
    String? role,
    Map<String, dynamic>? preferences,
  }) {
    return Utilisateur(
      id: id ?? this.id,
      email: email ?? this.email,
      nomComplet: nomComplet ?? this.nomComplet,
      photoUrl: photoUrl ?? this.photoUrl,
      dateCreation: dateCreation ?? this.dateCreation,
      dernierConnexion: dernierConnexion ?? this.dernierConnexion,
      estVerifie: estVerifie ?? this.estVerifie,
      familleId: familleId ?? this.familleId,
      role: role ?? this.role,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  String toString() {
    return 'Utilisateur(id: $id, email: $email, nomComplet: $nomComplet, role: $role, estVerifie: $estVerifie)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Utilisateur && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
