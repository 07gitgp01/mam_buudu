import 'date_partielle.dart';

class Personne {
  final String id;
  final String? nomNaissance;
  final String? nomUsage;
  final String? prenoms;
  final String? sexe;
  final DatePartielle? dateNaissance;
  final String? lieuNaissance;
  final DatePartielle? dateDeces;
  final String? lieuDeces;
  final String? biographie;
  final String? notes;
  final String? photoPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  Personne({
    required this.id,
    this.nomNaissance,
    this.nomUsage,
    this.prenoms,
    this.sexe,
    this.dateNaissance,
    this.lieuNaissance,
    this.dateDeces,
    this.lieuDeces,
    this.biographie,
    this.notes,
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Personne.fromMap(Map<String, dynamic> map) {
    // Parsing sécurisé des dates created_at et updated_at
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      
      if (value is int) {
        // Timestamp en millisecondes
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          // Si le parsing échoue, utiliser la date actuelle
          return DateTime.now();
        }
      }
      
      // Par défaut, utiliser la date actuelle
      return DateTime.now();
    }
    
    return Personne(
      id: map['id'] as String,
      nomNaissance: map['nom_naissance'] as String?,
      nomUsage: map['nom_usage'] as String?,
      prenoms: map['prenoms'] as String?,
      sexe: map['sexe'] as String?,
      dateNaissance: map['date_naissance'] != null 
          ? DatePartielle.fromString(map['date_naissance'] as String)
          : null,
      lieuNaissance: map['lieu_naissance'] as String?,
      dateDeces: map['date_deces'] != null
          ? DatePartielle.fromString(map['date_deces'] as String)
          : null,
      lieuDeces: map['lieu_deces'] as String?,
      biographie: map['biographie'] as String?,
      notes: map['notes'] as String?,
      photoPath: map['photo_path'] as String?,
      createdAt: parseDateTime(map['created_at']),
      updatedAt: parseDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom_naissance': nomNaissance,
      'nom_usage': nomUsage,
      'prenoms': prenoms,
      'sexe': sexe,
      'date_naissance': dateNaissance?.toString(),
      'lieu_naissance': lieuNaissance,
      'date_deces': dateDeces?.toString(),
      'lieu_deces': lieuDeces,
      'biographie': biographie,
      'notes': notes,
      'photo_path': photoPath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get nomComplet {
    final prenom = prenoms?.isNotEmpty == true ? prenoms! : '';
    final nom = nomUsage?.isNotEmpty == true ? nomUsage! : 
                nomNaissance?.isNotEmpty == true ? nomNaissance! : '';
    
    if (prenom.isEmpty && nom.isEmpty) return 'Inconnu';
    if (prenom.isEmpty) return nom;
    if (nom.isEmpty) return prenom;
    
    return '$prenom $nom';
  }

  String get datesAffichage {
    if (dateNaissance != null) {
      if (dateDeces != null) {
        return 'né(e) le ${dateNaissance!.toString()}, décédé(e) le ${dateDeces!.toString()}';
      } else {
        if (dateNaissance!.isComplete) {
          return 'né(e) le ${dateNaissance!.toString()}';
        } else {
          return 'né(e) en ${dateNaissance!.toString()}';
        }
      }
    } else if (dateDeces != null) {
      return 'décédé(e) le ${dateDeces!.toString()}';
    } else {
      return '';
    }
  }

  String? get ageDeces {
    if (dateNaissance == null || dateDeces == null) return null;
    
    int annees = dateDeces!.annee - dateNaissance!.annee;
    
    if (dateNaissance!.hasMonth && dateDeces!.hasMonth) {
      final moisNaissance = dateNaissance!.mois!;
      final moisDeces = dateDeces!.mois!;
      
      if (moisDeces < moisNaissance) {
        annees--;
      } else if (moisDeces == moisNaissance) {
        if (dateNaissance!.hasDay && dateDeces!.hasDay) {
          final jourNaissance = dateNaissance!.jour!;
          final jourDeces = dateDeces!.jour!;
          
          if (jourDeces < jourNaissance) {
            annees--;
          }
        }
      }
    }
    
    if (annees < 0) return null;
    
    if (annees == 0) return 'moins d\'un an';
    if (annees == 1) return '1 an';
    
    return '$annees ans';
  }

  String? get ageActuel {
    if (dateNaissance == null) return null;
    
    final maintenant = DateTime.now();
    int annees = maintenant.year - dateNaissance!.annee;
    
    if (dateNaissance!.hasMonth) {
      if (maintenant.month < dateNaissance!.mois!) {
        annees--;
      } else if (maintenant.month == dateNaissance!.mois!) {
        if (dateNaissance!.hasDay) {
          if (maintenant.day < dateNaissance!.jour!) {
            annees--;
          }
        }
      }
    }
    
    if (annees < 0) return null;
    
    if (annees == 0) return 'moins d\'un an';
    if (annees == 1) return '1 an';
    
    return '$annees ans';
  }

  Personne copyWith({
    String? id,
    String? nomNaissance,
    String? nomUsage,
    String? prenoms,
    String? sexe,
    DatePartielle? dateNaissance,
    String? lieuNaissance,
    DatePartielle? dateDeces,
    String? lieuDeces,
    String? biographie,
    String? photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Personne(
      id: id ?? this.id,
      nomNaissance: nomNaissance ?? this.nomNaissance,
      nomUsage: nomUsage ?? this.nomUsage,
      prenoms: prenoms ?? this.prenoms,
      sexe: sexe ?? this.sexe,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      lieuNaissance: lieuNaissance ?? this.lieuNaissance,
      dateDeces: dateDeces ?? this.dateDeces,
      lieuDeces: lieuDeces ?? this.lieuDeces,
      biographie: biographie ?? this.biographie,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
