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
    
    final parts = date.split('-');
    
    switch (parts.length) {
      case 1:
        // Format "YYYY"
        return DatePartielle(annee: int.parse(parts[0]));
      case 2:
        // Format "YYYY-MM"
        if (parts.length >= 2) {
          return DatePartielle(
            annee: int.parse(parts[0]),
            mois: int.parse(parts[1]),
          );
        }
        throw ArgumentError('Format de date non reconnu: $date');
      case 3:
        // Format "YYYY-MM-DD"
        if (parts.length >= 3) {
          return DatePartielle(
            annee: int.parse(parts[0]),
            mois: int.parse(parts[1]),
            jour: int.parse(parts[2]),
          );
        }
        throw ArgumentError('Format de date non reconnu: $date');
      default:
        throw ArgumentError('Format de date non reconnu: $date');
    }
  }

  @override
  String toString() {
    if (jour != null && mois != null) {
      final dateFormat = DateFormat('d MMMM yyyy', 'fr_FR');
      return dateFormat.format(DateTime(annee, mois!, jour!));
    } else if (mois != null) {
      final dateFormat = DateFormat('MMMM yyyy', 'fr_FR');
      return dateFormat.format(DateTime(annee, mois!));
    } else {
      return annee.toString();
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
