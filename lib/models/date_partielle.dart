import 'package:intl/intl.dart';

class DatePartielle {
  final int annee;
  final int? mois;
  final int? jour;

  DatePartielle({
    required this.annee,
    this.mois,
    this.jour,
  });

  factory DatePartielle.fromStrings({
    required String annee,
    String? mois,
    String? jour,
  }) {
    return DatePartielle(
      annee: int.parse(annee),
      mois: mois != null ? int.parse(mois) : null,
      jour: jour != null ? int.parse(jour) : null,
    );
  }

  factory DatePartielle.fromString(String date) {
    if (date.isEmpty) {
      throw ArgumentError('La date ne peut pas être vide');
    }
    
    // Vérifier si c'est un format français
    if (date.contains(' ')) {
      final parts = date.split(' ');
      
      // Format "7 janvier 1999"
      if (parts.length == 3) {
        final jourPart = parts[0];
        final moisPart = parts[1].toLowerCase();
        final anneePart = parts[2];
        
        // Parser le jour
        final jour = int.tryParse(jourPart);
        if (jour == null) {
          throw ArgumentError('Jour non reconnu: $jourPart');
        }
        
        // Parser l'année
        final annee = int.tryParse(anneePart);
        if (annee == null) {
          throw ArgumentError('Année non reconnue: $anneePart');
        }
        
        // Parser le mois
        final moisNoms = [
          'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
          'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
        ];
        
        final moisIndex = moisNoms.indexOf(moisPart);
        if (moisIndex == -1) {
          throw ArgumentError('Mois non reconnu: $moisPart');
        }
        
        return DatePartielle(
          annee: annee,
          mois: moisIndex + 1,
          jour: jour,
        );
      }
      
      // Format "janvier 1999"
      if (parts.length == 2) {
        final moisPart = parts[0].toLowerCase();
        final anneePart = parts[1];
        
        // Parser l'année
        final annee = int.tryParse(anneePart);
        if (annee == null) {
          throw ArgumentError('Format de date non reconnu: $date');
        }
        
        // Parser le mois
        final moisNoms = [
          'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
          'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
        ];
        
        final moisIndex = moisNoms.indexOf(moisPart);
        if (moisIndex == -1) {
          throw ArgumentError('Mois non reconnu: $moisPart');
        }
        
        return DatePartielle(
          annee: annee,
          mois: moisIndex + 1,
          jour: null, // Pas de jour dans ce format
        );
      }
    }
    
    // Format standard "YYYY-MM-DD" ou "YYYY-MM" ou "YYYY"
    final parts = date.split('-');
    
    switch (parts.length) {
      case 1:
        // Format "YYYY"
        final annee = int.tryParse(parts[0]);
        if (annee == null) {
          throw ArgumentError('Format de date non reconnu: $date');
        }
        return DatePartielle(annee: annee);
      case 2:
        // Format "YYYY-MM"
        final annee = int.tryParse(parts[0]);
        final mois = int.tryParse(parts[1]);
        if (annee == null || mois == null) {
          throw ArgumentError('Format de date non reconnu: $date');
        }
        return DatePartielle(
          annee: annee,
          mois: mois,
        );
      case 3:
        // Format "YYYY-MM-DD"
        final annee = int.tryParse(parts[0]);
        final mois = int.tryParse(parts[1]);
        final jour = int.tryParse(parts[2]);
        if (annee == null || mois == null || jour == null) {
          throw ArgumentError('Format de date non reconnu: $date');
        }
        return DatePartielle(
          annee: annee,
          mois: mois,
          jour: jour,
        );
      default:
        throw ArgumentError('Format de date non reconnu: $date');
    }
  }

  @override
  String toString() {
    try {
      if (jour != null && mois != null) {
        final dateFormat = DateFormat('d MMMM yyyy', 'fr_FR');
        return dateFormat.format(DateTime(annee, mois!, jour!));
      } else if (mois != null) {
        final dateFormat = DateFormat('MMMM yyyy', 'fr_FR');
        return dateFormat.format(DateTime(annee, mois!));
      } else {
        return annee.toString();
      }
    } catch (e) {
      // Fallback si la locale n'est pas initialisée
      if (jour != null && mois != null) {
        return '$jour/$mois/$annee';
      } else if (mois != null) {
        final moisNoms = [
          'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
          'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
        ];
        return '${moisNoms[mois! - 1]} $annee';
      } else {
        return annee.toString();
      }
    }
  }

  // Méthode pour l'affichage formaté (français)
  String toDisplayString() {
    try {
      if (jour != null && mois != null) {
        final dateFormat = DateFormat('d MMMM yyyy', 'fr_FR');
        return dateFormat.format(DateTime(annee, mois!, jour!));
      } else if (mois != null) {
        final dateFormat = DateFormat('MMMM yyyy', 'fr_FR');
        return dateFormat.format(DateTime(annee, mois!));
      } else {
        return annee.toString();
      }
    } catch (e) {
      // Fallback si la locale n'est pas initialisée
      if (jour != null && mois != null) {
        return '$jour/$mois/$annee';
      } else if (mois != null) {
        final moisNoms = [
          'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
          'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
        ];
        return '${moisNoms[mois! - 1]} $annee';
      } else {
        return annee.toString();
      }
    }
  }

  String toStorage() {
    final moisStr = mois?.toString().padLeft(2, '0') ?? '00';
    final jourStr = jour?.toString().padLeft(2, '0') ?? '00';
    return '$annee-$moisStr-$jourStr';
  }

  int compareTo(DatePartielle autre) {
    // Comparaison par année
    if (annee != autre.annee) {
      return annee.compareTo(autre.annee);
    }
    
    // Comparaison par mois
    final moisThis = mois ?? 0;
    final moisAutre = autre.mois ?? 0;
    if (moisThis != moisAutre) {
      return moisThis.compareTo(moisAutre);
    }
    
    // Comparaison par jour
    final jourThis = jour ?? 0;
    final jourAutre = autre.jour ?? 0;
    return jourThis.compareTo(jourAutre);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DatePartielle &&
        other.annee == annee &&
        other.mois == mois &&
        other.jour == jour;
  }

  @override
  int get hashCode => annee.hashCode ^ mois.hashCode ^ jour.hashCode;

  bool get isComplete => jour != null && mois != null;
  bool get hasMonth => mois != null;
  bool get hasDay => jour != null;
}
