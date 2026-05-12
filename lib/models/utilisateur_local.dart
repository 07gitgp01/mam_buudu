class UtilisateurLocal {
  final String id;
  final String email;
  final String motDePasse;
  final String? nom;
  final String? prenom;
  final String role; // 'admin', 'member'
  final bool estConnecte;
  final int? derniereConnexion;
  final int createdAt;
  final String? questionSecrete;
  final String? reponseSecrete;

  UtilisateurLocal({
    required this.id,
    required this.email,
    required this.motDePasse,
    this.nom,
    this.prenom,
    this.role = 'member',
    this.estConnecte = false,
    this.derniereConnexion,
    required this.createdAt,
    this.questionSecrete,
    this.reponseSecrete,
  });

  // Getters
  String get nomComplet {
    if (nom != null && prenom != null) {
      return '$prenom $nom';
    } else if (nom != null) {
      return nom!;
    } else if (prenom != null) {
      return prenom!;
    }
    return email;
  }

  bool get estAdmin => role == 'admin';
  bool get estMember => role == 'member';

  // Factory constructor from Map
  factory UtilisateurLocal.fromMap(Map<String, dynamic> map) {
    return UtilisateurLocal(
      id: map['id'] as String,
      email: map['email'] as String,
      motDePasse: map['mot_de_passe'] as String,
      nom: map['nom'] as String?,
      prenom: map['prenom'] as String?,
      role: map['role'] as String? ?? 'member',
      estConnecte: (map['est_connecte'] as int) == 1,
      derniereConnexion: map['derniere_connexion'] as int?,
      createdAt: map['created_at'] as int,
      questionSecrete: map['question_secrete'] as String?,
      reponseSecrete: map['reponse_secrete'] as String?,
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'mot_de_passe': motDePasse,
      'nom': nom,
      'prenom': prenom,
      'role': role,
      'est_connecte': estConnecte ? 1 : 0,
      'derniere_connexion': derniereConnexion,
      'created_at': createdAt,
      'question_secrete': questionSecrete,
      'reponse_secrete': reponseSecrete,
    };
  }

  // Copy with
  UtilisateurLocal copyWith({
    String? id,
    String? email,
    String? motDePasse,
    String? nom,
    String? prenom,
    String? role,
    bool? estConnecte,
    int? derniereConnexion,
    int? createdAt,
    String? questionSecrete,
    String? reponseSecrete,
  }) {
    return UtilisateurLocal(
      id: id ?? this.id,
      email: email ?? this.email,
      motDePasse: motDePasse ?? this.motDePasse,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      role: role ?? this.role,
      estConnecte: estConnecte ?? this.estConnecte,
      derniereConnexion: derniereConnexion ?? this.derniereConnexion,
      createdAt: createdAt ?? this.createdAt,
      questionSecrete: questionSecrete ?? this.questionSecrete,
      reponseSecrete: reponseSecrete ?? this.reponseSecrete,
    );
  }

  @override
  String toString() {
    return 'UtilisateurLocal(id: $id, email: $email, nom: $nomComplet, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UtilisateurLocal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
