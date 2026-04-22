class NotificationLocale {
  final String id;
  final String utilisateurId;
  final String type; // 'anniversaire', 'evenement', 'rappel'
  final String titre;
  final String message;
  final DateTime dateNotification;
  final bool estLue;
  final bool estEnvoyee;
  final DateTime? dateCreation;
  final String? personneId; // ID de la personne concernée (optionnel)

  const NotificationLocale({
    required this.id,
    required this.utilisateurId,
    required this.type,
    required this.titre,
    required this.message,
    required this.dateNotification,
    this.estLue = false,
    this.estEnvoyee = false,
    this.dateCreation,
    this.personneId,
  });

  // Constructeur pour les notifications d'anniversaire
  NotificationLocale.anniversaire({
    required this.id,
    required this.utilisateurId,
    required this.titre,
    required this.message,
    required this.dateNotification,
    this.personneId,
  }) : type = 'anniversaire',
       estLue = false,
       estEnvoyee = false,
       dateCreation = DateTime.now();

  // Constructeur pour les événements
  NotificationLocale.evenement({
    required this.id,
    required this.utilisateurId,
    required this.titre,
    required this.message,
    required this.dateNotification,
    this.personneId,
  }) : type = 'evenement',
       estLue = false,
       estEnvoyee = false,
       dateCreation = DateTime.now();

  // Constructeur pour les rappels
  NotificationLocale.rappel({
    required this.id,
    required this.utilisateurId,
    required this.titre,
    required this.message,
    required this.dateNotification,
    this.personneId,
  }) : type = 'rappel',
       estLue = false,
       estEnvoyee = false,
       dateCreation = DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'utilisateur_id': utilisateurId,
      'type': type,
      'titre': titre,
      'message': message,
      'date_notification': dateNotification.millisecondsSinceEpoch,
      'est_lue': estLue ? 1 : 0,
      'est_envoyee': estEnvoyee ? 1 : 0,
      'date_creation': dateCreation?.millisecondsSinceEpoch,
      'personne_id': personneId,
    };
  }

  factory NotificationLocale.fromMap(Map<String, dynamic> map) {
    return NotificationLocale(
      id: map['id'] as String,
      utilisateurId: map['utilisateur_id'] as String,
      type: map['type'] as String,
      titre: map['titre'] as String,
      message: map['message'] as String,
      dateNotification: DateTime.fromMillisecondsSinceEpoch(map['date_notification'] as int),
      estLue: (map['est_lue'] as int) == 1,
      estEnvoyee: (map['est_envoyee'] as int) == 1,
      dateCreation: map['date_creation'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['date_creation'] as int)
          : null,
      personneId: map['personne_id'] as String?,
    );
  }

  NotificationLocale copyWith({
    String? id,
    String? utilisateurId,
    String? type,
    String? titre,
    String? message,
    DateTime? dateNotification,
    bool? estLue,
    bool? estEnvoyee,
    DateTime? dateCreation,
    String? personneId,
  }) {
    return NotificationLocale(
      id: id ?? this.id,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      type: type ?? this.type,
      titre: titre ?? this.titre,
      message: message ?? this.message,
      dateNotification: dateNotification ?? this.dateNotification,
      estLue: estLue ?? this.estLue,
      estEnvoyee: estEnvoyee ?? this.estEnvoyee,
      dateCreation: dateCreation ?? this.dateCreation,
      personneId: personneId ?? this.personneId,
    );
  }

  @override
  String toString() {
    return 'NotificationLocale(id: $id, type: $type, titre: $titre, dateNotification: $dateNotification)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationLocale && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
