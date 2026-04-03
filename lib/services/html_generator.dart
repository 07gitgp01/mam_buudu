import '../models/personne.dart';
import '../models/union.dart';

class HtmlGenerator {
  static String genererLivret({
    required Personne racine,
    required List<Personne> toutesPersonnes,
    required Map<String, List<Union>> unionsParPersonne,
    required Map<String, List<Personne>> enfantsParPersonne,
  }) {
    final buffer = StringBuffer();
    
    // En-tête HTML avec CSS responsive
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="fr">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>Livret de Famille</title>');
    buffer.writeln('  <style>');
    buffer.writeln(_getCssStyle());
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    
    // Page de garde
    buffer.writeln(_genererPageDeGarde(racine));
    
    // Table des matières
    buffer.writeln(_genererTableMatieres(toutesPersonnes));
    
    // Arbre généalogique (placeholder pour l'image)
    buffer.writeln(_genererSectionArbre());
    
    // Fiches individuelles
    buffer.writeln(_genererFichesIndividuelles(toutesPersonnes, unionsParPersonne, enfantsParPersonne));
    
    // Index des noms
    buffer.writeln(_genererIndexNoms(toutesPersonnes));
    
    buffer.writeln('</body>');
    buffer.writeln('</html>');
    
    return buffer.toString();
  }
  
  static String _getCssStyle() {
    return '''
      * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
      }
      
      body {
        font-family: 'Georgia', serif;
        line-height: 1.6;
        color: #333;
        background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
        min-height: 100vh;
      }
      
      .page {
        max-width: 800px;
        margin: 0 auto;
        padding: 40px 20px;
        background: white;
        box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        border-radius: 8px;
        margin-bottom: 30px;
      }
      
      .page-break {
        page-break-before: always;
      }
      
      h1 {
        text-align: center;
        color: #2c3e50;
        margin-bottom: 30px;
        font-size: 2.5em;
        text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
      }
      
      h2 {
        color: #34495e;
        border-bottom: 3px solid #3498db;
        padding-bottom: 10px;
        margin: 30px 0 20px 0;
        font-size: 1.8em;
      }
      
      h3 {
        color: #2c3e50;
        margin: 20px 0 15px 0;
        font-size: 1.4em;
      }
      
      .couverture {
        text-align: center;
        padding: 60px 0;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        border-radius: 12px;
        margin-bottom: 40px;
      }
      
      .titre-couverture {
        font-size: 3em;
        font-weight: bold;
        margin-bottom: 20px;
        text-shadow: 3px 3px 6px rgba(0,0,0,0.3);
      }
      
      .sous-titre-couverture {
        font-size: 1.2em;
        opacity: 0.9;
        margin-bottom: 30px;
      }
      
      .table-matieres {
        background: #f8f9fa;
        padding: 30px;
        border-radius: 8px;
      }
      
      .table-matieres ul {
        list-style: none;
        columns: 2;
        column-gap: 40px;
      }
      
      .table-matieres li {
        margin: 8px 0;
        padding: 8px 12px;
        background: white;
        border-radius: 4px;
        border-left: 4px solid #3498db;
        transition: all 0.3s ease;
      }
      
      .table-matieres li:hover {
        background: #e3f2fd;
        transform: translateX(5px);
      }
      
      .arbre-placeholder {
        text-align: center;
        padding: 40px;
        background: #f0f3f7;
        border: 2px dashed #3498db;
        border-radius: 8px;
        margin: 30px 0;
      }
      
      .fiche {
        margin-bottom: 40px;
        padding: 30px;
        background: white;
        border-radius: 8px;
        border: 1px solid #e1e8ed;
        box-shadow: 0 2px 10px rgba(0,0,0,0.05);
      }
      
      .fiche-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 20px;
        padding-bottom: 15px;
        border-bottom: 2px solid #ecf0f1;
      }
      
      .fiche-nom {
        font-size: 1.5em;
        font-weight: bold;
        color: #2c3e50;
      }
      
      .fiche-sexe {
        padding: 4px 12px;
        border-radius: 20px;
        font-size: 0.9em;
        font-weight: bold;
      }
      
      .sexe-homme {
        background: #3498db;
        color: white;
      }
      
      .sexe-femme {
        background: #e74c3c;
        color: white;
      }
      
      .fiche-info {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
        gap: 15px;
        margin: 20px 0;
      }
      
      .info-item {
        padding: 10px;
        background: #f8f9fa;
        border-radius: 4px;
        border-left: 3px solid #3498db;
      }
      
      .info-label {
        font-weight: bold;
        color: #7f8c8d;
        margin-bottom: 5px;
        font-size: 0.9em;
      }
      
      .index {
        background: #f8f9fa;
        padding: 30px;
        border-radius: 8px;
      }
      
      .index-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 10px;
      }
      
      .index-item {
        padding: 10px;
        background: white;
        border-radius: 4px;
        border: 1px solid #e1e8ed;
        transition: all 0.3s ease;
      }
      
      .index-item:hover {
        background: #3498db;
        color: white;
        transform: translateY(-2px);
        box-shadow: 0 4px 12px rgba(52,152,219,0.2);
      }
      
      .arbre-image {
        width: 100%;
        max-width: 600px;
        height: auto;
        border-radius: 8px;
        box-shadow: 0 4px 20px rgba(0,0,0,0.1);
      }
      
      @media print {
        body {
          background: white;
        }
        
        .page {
          box-shadow: none;
          border: 1px solid #ddd;
          margin: 0;
          padding: 20px;
        }
        
        .page-break {
          page-break-before: always;
        }
        
        .couverture {
          background: #667eea !important;
          -webkit-print-color-adjust: exact;
        }
      }
      
      @media (max-width: 768px) {
        .page {
          padding: 20px 15px;
          margin: 0 10px 20px 10px;
        }
        
        .table-matieres ul {
          columns: 1;
        }
        
        .fiche-info {
          grid-template-columns: 1fr;
        }
        
        .index-grid {
          grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
        }
      }
    ''';
  }
  
  static String _genererPageDeGarde(Personne racine) {
    final nomComplet = '${racine.prenoms} ${racine.nomUsage ?? racine.nomNaissance}';
    
    return '''
      <div class="page couverture">
        <div class="titre-couverture">LIVRET DE FAMILLE</div>
        <div class="sous-titre-couverture">$nomComplet</div>
        <div class="sous-titre-couverture">Généalogie • ${DateTime.now().year}</div>
      </div>
    ''';
  }
  
  static String _genererTableMatieres(List<Personne> toutesPersonnes) {
    final buffer = StringBuffer();
    buffer.writeln('<div class="page">');
    buffer.writeln('  <h2>Table des matières</h2>');
    buffer.writeln('  <div class="table-matieres">');
    buffer.writeln('    <ul>');
    
    // Trier les personnes par ordre alphabétique
    final personnesTriees = List<Personne>.from(toutesPersonnes)
      ..sort((a, b) => '${a.prenoms} ${a.nomUsage ?? a.nomNaissance}'
          .compareTo('${b.prenoms} ${b.nomUsage ?? b.nomNaissance}'));
    
    buffer.writeln('      <li><a href="#page-de-garde">Page de garde</a></li>');
    buffer.writeln('      <li><a href="#arbre">Arbre généalogique</a></li>');
    buffer.writeln('      <li><a href="#fiches">Fiches individuelles</a></li>');
    
    for (int i = 0; i < personnesTriees.length; i++) {
      final personne = personnesTriees[i];
      final nomComplet = '${personne.prenoms} ${personne.nomUsage ?? personne.nomNaissance}';
      buffer.writeln('      <li><a href="#fiche-${personne.id}">$nomComplet</a></li>');
    }
    
    buffer.writeln('      <li><a href="#index">Index des noms</a></li>');
    buffer.writeln('    </ul>');
    buffer.writeln('  </div>');
    buffer.writeln('</div>');
    
    return buffer.toString();
  }
  
  static String _genererSectionArbre() {
    return '''
      <div class="page page-break">
        <h2 id="arbre">Arbre généalogique</h2>
        <div class="arbre-placeholder">
          <div style="text-align: center; margin-bottom: 20px;">
            <img src="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjQiIGhlaWdodD0iNjQiIHZpZXdCb3g9IjAgMCA2NCA2NCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCBkPSJNMzIgMTZjMC0zLjUtMy41LTMuNS0zLjVIMTZjLTMuNSAwLTYuNSAzLjUtNi41aDh2MjguMjQ4YzYuNS0zLjUgMTctMy41IDE3LTVoOGMtMy41IDAtNi41IDMuNS02LjUgNi41djMyaDhjMy41IDAgNi41LTMuNSA2LjUtNi41di04eiIvPjwvc3ZnPg==" alt="Icône d'arbre" style="width: 64px; height: 64px; opacity: 0.3;">
            <p style="color: #666; font-style: italic; margin-top: 15px;">
              L'arbre généalogique complet sera affiché ici
            </p>
          </div>
        </div>
      </div>
    ''';
  }
  
  static String _genererFichesIndividuelles(
    List<Personne> toutesPersonnes,
    Map<String, List<Union>> unionsParPersonne,
    Map<String, List<Personne>> enfantsParPersonne,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('<div class="page page-break">');
    buffer.writeln('  <h2 id="fiches">Fiches individuelles</h2>');
    
    // Trier par ordre alphabétique
    final personnesTriees = List<Personne>.from(toutesPersonnes)
      ..sort((a, b) => '${a.prenoms} ${a.nomUsage ?? a.nomNaissance}'
          .compareTo('${b.prenoms} ${b.nomUsage ?? b.nomNaissance}'));
    
    for (final personne in personnesTriees) {
      buffer.writeln(_genererFicheIndividuelle(personne, unionsParPersonne, enfantsParPersonne));
    }
    
    buffer.writeln('</div>');
    return buffer.toString();
  }
  
  static String _genererFicheIndividuelle(
    Personne personne,
    Map<String, List<Union>> unionsParPersonne,
    Map<String, List<Personne>> enfantsParPersonne,
  ) {
    final nomComplet = '${personne.prenoms} ${personne.nomUsage ?? personne.nomNaissance}';
    final sexeClass = personne.sexe == 'M' ? 'sexe-homme' : 'sexe-femme';
    final sexeTexte = personne.sexe == 'M' ? 'Homme' : 'Femme';
    
    final buffer = StringBuffer();
    buffer.writeln('<div class="fiche" id="fiche-${personne.id}">');
    buffer.writeln('  <div class="fiche-header">');
    buffer.writeln('    <div class="fiche-nom">$nomComplet</div>');
    buffer.writeln('    <div class="fiche-sexe $sexeClass">$sexeTexte</div>');
    buffer.writeln('  </div>');
    
    buffer.writeln('  <div class="fiche-info">');
    
    // Informations de base
    if (personne.dateNaissance != null) {
      buffer.writeln('    <div class="info-item">');
      buffer.writeln('      <div class="info-label">Date de naissance</div>');
      buffer.writeln('      <div>${personne.dateNaissance}</div>');
      buffer.writeln('    </div>');
    }
    
    if (personne.lieuNaissance != null && personne.lieuNaissance!.isNotEmpty) {
      buffer.writeln('    <div class="info-item">');
      buffer.writeln('      <div class="info-label">Lieu de naissance</div>');
      buffer.writeln('      <div>${personne.lieuNaissance}</div>');
      buffer.writeln('    </div>');
    }
    
    // Unions
    final unions = unionsParPersonne[personne.id] ?? [];
    if (unions.isNotEmpty) {
      buffer.writeln('    <div class="info-item">');
      buffer.writeln('      <div class="info-label">Union(s)</div>');
      buffer.writeln('      <div>');
      for (final union in unions) {
        buffer.writeln('        • Union du ${union.toString()}');
      }
      buffer.writeln('      </div>');
      buffer.writeln('    </div>');
    }
    
    // Enfants
    final enfants = enfantsParPersonne[personne.id] ?? [];
    if (enfants.isNotEmpty) {
      buffer.writeln('    <div class="info-item">');
      buffer.writeln('      <div class="info-label">Enfant(s)</div>');
      buffer.writeln('      <div>');
      for (final enfant in enfants) {
        final nomEnfant = '${enfant.prenoms} ${enfant.nomUsage ?? enfant.nomNaissance}';
        buffer.writeln('        • <a href="#fiche-${enfant.id}">$nomEnfant</a>');
      }
      buffer.writeln('      </div>');
      buffer.writeln('    </div>');
    }
    
    buffer.writeln('  </div>');
    buffer.writeln('</div>');
    
    return buffer.toString();
  }
  
  static String _genererIndexNoms(List<Personne> toutesPersonnes) {
    final buffer = StringBuffer();
    buffer.writeln('<div class="page page-break">');
    buffer.writeln('  <h2 id="index">Index des noms</h2>');
    buffer.writeln('  <div class="index">');
    buffer.writeln('    <div class="index-grid">');
    
    // Trier par ordre alphabétique
    final personnesTriees = List<Personne>.from(toutesPersonnes)
      ..sort((a, b) => '${a.prenoms} ${a.nomUsage ?? a.nomNaissance}'
          .compareTo('${b.prenoms} ${b.nomUsage ?? b.nomNaissance}'));
    
    for (final personne in personnesTriees) {
      final nomComplet = '${personne.prenoms} ${personne.nomUsage ?? personne.nomNaissance}';
      buffer.writeln('      <div class="index-item">');
      buffer.writeln('        <a href="#fiche-${personne.id}">$nomComplet</a>');
      buffer.writeln('      </div>');
    }
    
    buffer.writeln('    </div>');
    buffer.writeln('  </div>');
    buffer.writeln('</div>');
    
    return buffer.toString();
  }
}
