import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/personne.dart';
import '../models/union.dart';
import '../models/filiation.dart';

class GedcomExporter {
  static Future<String> exporter({
    required List<Personne> personnes,
    required List<Union> unions,
    required List<Filiation> filiations,
  }) async {
    final buffer = StringBuffer();
    
    // En-tête GEDCOM 5.5
    buffer.writeln('0 HEAD');
    buffer.writeln('1 SOUR MamBuudu');
    buffer.writeln('2 NAME MamBuudu Généalogie');
    buffer.writeln('2 VERS 1.0.0');
    buffer.writeln('1 VERS 5.5.1');
    buffer.writeln('1 CHAR UTF-8');
    buffer.writeln('1 LANG Français');
    buffer.writeln('1 DATE ${DateTime.now().toIso8601String()}');
    buffer.writeln('1 GEDC');
    buffer.writeln('2 VERS 5.5.1');
    buffer.writeln('2 FORM LINEAGE-LINKED');
    buffer.writeln('');
    
    // Exporter les individus
    for (final personne in personnes) {
      buffer.writeln('0 @${personne.id}@ INDI');
      
      // Nom complet
      final nomComplet = '${personne.prenoms} /${personne.nomNaissance}/';
      buffer.writeln('1 NAME $nomComplet');
      
      // Prénoms séparés
      if (personne.prenoms?.contains(' ') == true) {
        buffer.writeln('2 GIVN ${personne.prenoms}');
      }
      
      // Nom de naissance
      buffer.writeln('2 SURN ${personne.nomNaissance}');
      
      // Sexe
      buffer.writeln('1 SEX ${personne.sexe}');
      
      // Naissance
      if (personne.dateNaissance != null || personne.lieuNaissance != null) {
        buffer.writeln('1 BIRT');
        if (personne.dateNaissance != null) {
          buffer.writeln('2 DATE ${_formaterDateGedcom(personne.dateNaissance!.toString())}');
        }
        if (personne.lieuNaissance?.isNotEmpty == true) {
          buffer.writeln('2 PLAC ${personne.lieuNaissance}');
        }
      }
      
      // Décès
      if (personne.dateDeces != null || personne.lieuDeces != null) {
        buffer.writeln('1 DEAT');
        if (personne.dateDeces != null) {
          buffer.writeln('2 DATE ${_formaterDateGedcom(personne.dateDeces!.toString())}');
        }
        if (personne.lieuDeces?.isNotEmpty == true) {
          buffer.writeln('2 PLAC ${personne.lieuDeces}');
        }
      }
      
      // Notes
      if (personne.notes?.isNotEmpty == true) {
        buffer.writeln('1 NOTE ${personne.notes}');
      }
    }
    
    buffer.writeln('');
    
    // Exporter les familles (unions)
    for (final union in unions) {
      buffer.writeln('0 @${union.id}@ FAM');
      
      // Mariage
      if (union.dateUnion != null || union.lieuUnion != null) {
        buffer.writeln('1 MARR');
        if (union.dateUnion != null) {
          buffer.writeln('2 DATE ${_formaterDateGedcom(union.dateUnion!.toString())}');
        }
        if (union.lieuUnion?.isNotEmpty == true) {
          buffer.writeln('2 PLAC ${union.lieuUnion}');
        }
      }
      
      // Conjoint 1 (HUSB)
      if (union.conjoint1Id != null) {
        buffer.writeln('1 HUSB @${union.conjoint1Id}@');
      }
      
      // Conjoint 2 (WIFE)
      if (union.conjoint2Id != null) {
        buffer.writeln('1 WIFE @${union.conjoint2Id}@');
      }
      
      // Enfants
      final enfantsUnion = filiations
          .where((f) => f.unionId == union.id)
          .map((f) => f.enfantId)
          .toList();
      
      for (final enfantId in enfantsUnion) {
        buffer.writeln('1 CHIL @$enfantId@');
      }
    }
    
    buffer.writeln('');
    
    // Fin du fichier
    buffer.writeln('0 TRLR');
    
    return buffer.toString();
  }
  
  // Formater une date pour le format GEDCOM
  static String _formaterDateGedcom(String date) {
    // Convertir les formats de l'app vers GEDCOM
    if (date.contains('/')) {
      // Format DD/MM/YYYY -> YYYYMMDD
      final parties = date.split('/');
      if (parties.length == 3) {
        return '${parties[2]}${parties[1].padLeft(2, '0')}${parties[0].padLeft(2, '0')}';
      }
    }
    return date;
  }
  
  static Future<void> exporterVersFichier(String contenu, {String? nomFichier}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = nomFichier ?? 'arbre_genealogique_${DateTime.now().millisecondsSinceEpoch}.ged';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsString(contenu);
      
      // Partager le fichier
      await Share.shareXFiles([XFile(filePath)], text: 'Arbre généalogique au format GEDCOM');
      
    } catch (e) {
      throw Exception('Erreur lors de l\'export GEDCOM: $e');
    }
  }
}
