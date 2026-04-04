class PersonneUtilisateur {
  final String personneId;
  final String utilisateurId;
  final String permission; // 'read', 'write', 'admin'
  final int createdAt;
  final int updatedAt;

  PersonneUtilisateur({
    required this.personneId,
    required this.utilisateurId,
    this.permission = 'read',
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor from Map
  factory PersonneUtilisateur.fromMap(Map<String, dynamic> map) {
    return PersonneUtilisateur(
      personneId: map['personne_id'] as String,
      utilisateurId: map['utilisateur_id'] as String,
      permission: map['permission'] as String? ?? 'read',
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'personne_id': personneId,
      'utilisateur_id': utilisateurId,
      'permission': permission,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Copy with
  PersonneUtilisateur copyWith({
    String? personneId,
    String? utilisateurId,
    String? permission,
    int? createdAt,
    int? updatedAt,
  }) {
    return PersonneUtilisateur(
      personneId: personneId ?? this.personneId,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      permission: permission ?? this.permission,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getters
  bool get canRead => ['read', 'write', 'admin'].contains(permission);
  bool get canWrite => ['write', 'admin'].contains(permission);
  bool get canAdmin => permission == 'admin';

  @override
  String toString() {
    return 'PersonneUtilisateur(personneId: $personneId, utilisateurId: $utilisateurId, permission: $permission)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PersonneUtilisateur &&
        other.personneId == personneId &&
        other.utilisateurId == utilisateurId;
  }

  @override
  int get hashCode => personneId.hashCode ^ utilisateurId.hashCode;

  // Constantes pour les permissions
  static const String PERMISSION_READ = 'read';
  static const String PERMISSION_WRITE = 'write';
  static const String PERMISSION_ADMIN = 'admin';

  // Liste des permissions disponibles
  static const List<String> PERMISSIONS = [
    PERMISSION_READ,
    PERMISSION_WRITE,
    PERMISSION_ADMIN,
  ];

  // Labels pour les permissions
  static String getPermissionLabel(String permission) {
    switch (permission) {
      case PERMISSION_READ:
        return 'Lecture seule';
      case PERMISSION_WRITE:
        return 'Lecture & écriture';
      case PERMISSION_ADMIN:
        return 'Administrateur';
      default:
        return 'Inconnue';
    }
  }

  // Description des permissions
  static String getPermissionDescription(String permission) {
    switch (permission) {
      case PERMISSION_READ:
        return 'Peut voir les informations de la personne';
      case PERMISSION_WRITE:
        return 'Peut voir et modifier les informations de la personne';
      case PERMISSION_ADMIN:
        return 'Peut voir, modifier et supprimer la personne';
      default:
        return 'Permission non définie';
    }
  }
}
