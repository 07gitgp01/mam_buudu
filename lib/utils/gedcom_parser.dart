import 'dart:io';

class GedcomParser {
  // Parse un fichier GEDCOM ligne par ligne
  static Future<Map<String, dynamic>> importer(String cheminFichier, {
    Function(int avancement, String message)? onProgress,
  }) async {
    final personnes = <Map<String, dynamic>>[];
    final unions = <Map<String, dynamic>>[];
    final filiations = <Map<String, dynamic>>[];
    
    try {
      final file = File(cheminFichier);
      final contenu = await file.readAsString();
      final lignesFichier = contenu.split('\n');
      
      onProgress?.call(0, 'Lecture du fichier GEDCOM...');
      
      Map<String, dynamic>? personneCourante;
      Map<String, dynamic>? unionCourante;
      
      for (int i = 0; i < lignesFichier.length; i++) {
        final ligne = lignesFichier[i].trim();
        if (ligne.isEmpty) continue;
        
        // Parser niveau et tag
        final reste = ligne.length > 2 ? ligne.substring(2).trim() : '';
        
        if (reste.isEmpty) continue;
        
        final espaceIndex = reste.indexOf(' ');
        final tag = espaceIndex > 0 ? reste.substring(0, espaceIndex) : reste;
        final valeur = espaceIndex > 0 ? reste.substring(espaceIndex + 1) : '';
        
        switch (tag) {
          case 'HEAD':
            // Ignorer l'en-tête
            break;
            
          case 'INDI':
            // Nouvelle personne
            personneCourante = {
              'id': valeur.replaceAll('@', ''),
              'prenoms': '',
              'nomNaissance': '',
              'sexe': '',
              'dateNaissance': null,
              'lieuNaissance': null,
              'dateDeces': null,
              'lieuDeces': null,
              'notes': [],
            };
            personnes.add(personneCourante);
            break;
            
          case 'NAME':
            if (personneCourante != null) {
              final parties = valeur.split('/');
              if (parties.length >= 2) {
                personneCourante['prenoms'] = parties[0].trim();
                personneCourante['nomNaissance'] = parties[1].trim();
              } else {
                personneCourante['prenoms'] = valeur;
              }
            }
            break;
            
          case 'SEX':
            if (personneCourante != null) {
              personneCourante['sexe'] = valeur.toUpperCase();
            }
            break;
            
          case 'BIRT':
            // Début de l'événement naissance
            break;
            
          case 'DEAT':
            // Début de l'événement décès
            break;
            
          case 'DATE':
            if (personneCourante != null) {
              // Parser la date GEDCOM
              final dateParsee = _parserDate(valeur);
              if (i > 0 && lignesFichier[i-1].contains('BIRT')) {
                personneCourante['dateNaissance'] = dateParsee;
              } else if (i > 0 && lignesFichier[i-1].contains('DEAT')) {
                personneCourante['dateDeces'] = dateParsee;
              }
            }
            break;
            
          case 'PLAC':
            if (personneCourante != null) {
              if (i > 0 && lignesFichier[i-1].contains('BIRT')) {
                personneCourante['lieuNaissance'] = valeur;
              } else if (i > 0 && lignesFichier[i-1].contains('DEAT')) {
                personneCourante['lieuDeces'] = valeur;
              }
            }
            break;
            
          case 'FAM':
            // Nouvelle union
            unionCourante = {
              'id': valeur.replaceAll('@', ''),
              'conjoint1': null,
              'conjoint2': null,
              'dateUnion': null,
              'lieuUnion': null,
              'enfants': [],
            };
            unions.add(unionCourante);
            break;
            
          case 'HUSB':
          case 'WIFE':
            if (unionCourante != null) {
              if (unionCourante['conjoint1'] == null) {
                unionCourante['conjoint1'] = valeur.replaceAll('@', '');
              } else {
                unionCourante['conjoint2'] = valeur.replaceAll('@', '');
              }
            }
            break;
            
          case 'CHIL':
            if (unionCourante != null) {
              final enfants = unionCourante['enfants'] as List<String>;
              enfants.add(valeur.replaceAll('@', ''));
            }
            break;
            
          case 'MARR':
            // Début de l'événement mariage
            break;
            
          case 'NOTE':
            if (personneCourante != null) {
              personneCourante['notes'].add(valeur);
            }
            break;
            
          case 'TRLR':
            // Fin du fichier
            break;
        }
        
        onProgress?.call(
          (i * 100 ~/ lignesFichier.length), 
          'Importation en cours...'
        );
      }
      
      // Créer les filiations
      for (final union in unions) {
        final enfants = union['enfants'] as List<String>;
        for (final enfantId in enfants) {
          filiations.add({
            'id': 'F${filiations.length + 1}',
            'enfantId': enfantId,
            'unionId': union['id'],
            'typeLien': 'biologique',
            'ordreNaissance': filiations.length + 1,
          });
        }
      }
      
      onProgress?.call(100, 'Importation terminée');
      
      return {
        'personnes': personnes,
        'unions': unions,
        'filiations': filiations,
      };
      
    } catch (e) {
      throw Exception('Erreur lors de l\'import GEDCOM: $e');
    }
  }
  
  // Parser les dates GEDCOM (ABT, BEF, AFT, etc.)
  static String? _parserDate(String dateGedcom) {
    if (dateGedcom.isEmpty) return null;
    
    // Gérer les préfixes GEDCOM
    String dateNettoyee = dateGedcom;
    String? prefixe;
    
    if (dateNettoyee.startsWith('ABT ')) {
      prefixe = 'vers ';
      dateNettoyee = dateNettoyee.substring(4);
    } else if (dateNettoyee.startsWith('BEF ')) {
      prefixe = 'avant ';
      dateNettoyee = dateNettoyee.substring(4);
    } else if (dateNettoyee.startsWith('AFT ')) {
      prefixe = 'après ';
      dateNettoyee = dateNettoyee.substring(4);
    } else if (dateNettoyee.startsWith('BET ')) {
      // Gérer les intervalles
      final parties = dateNettoyee.substring(4).split(' AND ');
      if (parties.length == 2) {
        return 'entre ${_formatDateSimple(parties[0])} et ${_formatDateSimple(parties[1])}';
      }
    }
    
    return '${prefixe ?? ''}${_formatDateSimple(dateNettoyee)}';
  }
  
  static String _formatDateSimple(String date) {
    // Format simple YYYY ou YYYY-MM-DD
    if (date.length == 4) {
      return date;
    } else if (date.contains('-')) {
      final parties = date.split('-');
      if (parties.length >= 3) {
        return '${parties[2]}/${parties[1]}/${parties[0]}';
      }
    }
    return date;
  }
}
