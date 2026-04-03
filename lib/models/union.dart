import 'date_partielle.dart';

class Union {
  final String id;
  final String? type;
  final DatePartielle? dateDebut;
  final String? lieuDebut;
  final DatePartielle? dateFin;
  final String? lieuFin;
  final String? notes;
  
  // Champs additionnels non stockés directement
  final List<String> parentIds;
  final List<String> enfantIds;

  Union({
    required this.id,
    this.type,
    this.dateDebut,
    this.lieuDebut,
    this.dateFin,
    this.lieuFin,
    this.notes,
    this.parentIds = const [],
    this.enfantIds = const [],
  });

  // Getters pour la compatibilité avec GEDCOM
  DatePartielle? get dateUnion => dateDebut;
  String? get lieuUnion => lieuDebut;
  String? get conjoint1Id => parentIds.isNotEmpty ? parentIds[0] : null;
  String? get conjoint2Id => parentIds.length > 1 ? parentIds[1] : null;

  factory Union.fromMap(
    Map<String, dynamic> map, {
    List<String> parentIds = const [],
    List<String> enfantIds = const [],
  }) {
    return Union(
      id: map['id'] as String,
      type: map['type'] as String?,
      dateDebut: map['date_debut'] != null
          ? DatePartielle.fromString(map['date_debut'] as String)
          : null,
      lieuDebut: map['lieu_debut'] as String?,
      dateFin: map['date_fin'] != null
          ? DatePartielle.fromString(map['date_fin'] as String)
          : null,
      lieuFin: map['lieu_fin'] as String?,
      notes: map['notes'] as String?,
      parentIds: parentIds,
      enfantIds: enfantIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'date_debut': dateDebut?.toStorage(),
      'lieu_debut': lieuDebut,
      'date_fin': dateFin?.toStorage(),
      'lieu_fin': lieuFin,
      'notes': notes,
    };
  }

  String get description {
    final typeStr = type?.isNotEmpty == true ? '$type ' : '';
    final datesStr = _getDatesDescription();
    final lieuStr = lieuDebut?.isNotEmpty == true ? ' à $lieuDebut' : '';
    
    return '$typeStr$datesStr$lieuStr'.trim();
  }

  String _getDatesDescription() {
    if (dateDebut != null && dateFin != null) {
      return 'du ${dateDebut!.toString()} au ${dateFin!.toString()}';
    } else if (dateDebut != null) {
      return 'depuis ${dateDebut!.toString()}';
    } else if (dateFin != null) {
      return 'jusqu\'en ${dateFin!.toString()}';
    } else {
      return '';
    }
  }

  String get duree {
    if (dateDebut == null || dateFin == null) return '';
    
    int annees = dateFin!.annee - dateDebut!.annee;
    
    if (dateDebut!.hasMonth && dateFin!.hasMonth) {
      final moisDebut = dateDebut!.mois!;
      final moisFin = dateFin!.mois!;
      
      if (moisFin < moisDebut) {
        annees--;
      } else if (moisFin == moisDebut) {
        if (dateDebut!.hasDay && dateFin!.hasDay) {
          final jourDebut = dateDebut!.jour!;
          final jourFin = dateFin!.jour!;
          
          if (jourFin < jourDebut) {
            annees--;
          }
        }
      }
    }
    
    if (annees < 0) return '';
    if (annees == 0) return 'moins d\'un an';
    if (annees == 1) return '1 an';
    
    return '$annees ans';
  }

  bool get estEnCours {
    if (dateFin == null) return true;
    
    final maintenant = DateTime.now();
    
    if (dateFin!.annee < maintenant.year) return false;
    if (dateFin!.annee > maintenant.year) return true;
    
    if (dateFin!.hasMonth && dateFin!.mois! < maintenant.month) return false;
    if (dateFin!.hasMonth && dateFin!.mois! > maintenant.month) return true;
    
    if (dateFin!.hasDay && dateFin!.jour! < maintenant.day) return false;
    
    return true;
  }

  Union copyWith({
    String? id,
    String? type,
    DatePartielle? dateDebut,
    String? lieuDebut,
    DatePartielle? dateFin,
    String? lieuFin,
    String? notes,
    List<String>? parentIds,
    List<String>? enfantIds,
  }) {
    return Union(
      id: id ?? this.id,
      type: type ?? this.type,
      dateDebut: dateDebut ?? this.dateDebut,
      lieuDebut: lieuDebut ?? this.lieuDebut,
      dateFin: dateFin ?? this.dateFin,
      lieuFin: lieuFin ?? this.lieuFin,
      notes: notes ?? this.notes,
      parentIds: parentIds ?? this.parentIds,
      enfantIds: enfantIds ?? this.enfantIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Union &&
        other.id == id &&
        other.type == type &&
        other.dateDebut == dateDebut &&
        other.lieuDebut == lieuDebut &&
        other.dateFin == dateFin &&
        other.lieuFin == lieuFin &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        dateDebut.hashCode ^
        lieuDebut.hashCode ^
        dateFin.hashCode ^
        lieuFin.hashCode ^
        notes.hashCode;
  }
}
