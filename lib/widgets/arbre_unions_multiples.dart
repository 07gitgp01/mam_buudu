import 'dart:math';
import 'package:flutter/material.dart';
import '../models/personne.dart';
import '../models/union.dart';
import '../database/union_repository.dart';
import '../database/filiation_repository.dart';
import '../database/personne_repository.dart';
import '../utils/constants.dart';

// Types de nœuds
abstract class NoeudArbre {
  final String id;
  String type;
  
  NoeudArbre(this.id, this.type);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NoeudArbre && runtimeType == other.runtimeType && id == other.id;
  
  @override
  int get hashCode => id.hashCode;
}

class PersonNode extends NoeudArbre {
  final Personne personne;
  
  PersonNode(this.personne) : super(personne.id, 'person');
  
  @override
  String toString() => 'PersonNode(${personne.nomComplet})';
}

class UnionNode extends NoeudArbre {
  final Union union;
  
  UnionNode(this.union) : super(union.id, 'union');
  
  @override
  String toString() => 'UnionNode(${union.type})';
}

class ChildGroupNode extends NoeudArbre {
  final List<String> enfantIds;
  final String unionId;
  
  ChildGroupNode(this.enfantIds, this.unionId) 
      : super('group_${enfantIds.join('_')}', 'child_group');
  
  @override
  String toString() => 'ChildGroupNode(${enfantIds.length} enfants)';
}

// Graphe orienté
class Graphe {
  Map<String, NoeudArbre> noeuds = {};
  Map<String, List<String>> liensSortants = {};
  Map<String, List<String>> liensEntrants = {};
  
  void ajouterNoeud(NoeudArbre noeud) {
    noeuds[noeud.id] = noeud;
    liensSortants.putIfAbsent(noeud.id, () => []);
    liensEntrants.putIfAbsent(noeud.id, () => []);
  }
  
  void ajouterLien(String sourceId, String cibleId) {
    if (!liensSortants.containsKey(sourceId)) {
      liensSortants[sourceId] = [];
    }
    if (!liensEntrants.containsKey(cibleId)) {
      liensEntrants[cibleId] = [];
    }
    
    if (!liensSortants[sourceId]!.contains(cibleId)) {
      liensSortants[sourceId]!.add(cibleId);
      liensEntrants[cibleId]!.add(sourceId);
    }
  }
  
  NoeudArbre? obtenirNoeud(String id) {
    return noeuds[id];
  }
  
  List<String> getEnfants(String noeudId) {
    return liensSortants[noeudId] ?? [];
  }
  
  List<String> getParents(String noeudId) {
    return liensEntrants[noeudId] ?? [];
  }
  
  Map<String, Personne> obtenirPersonnes() {
    final Map<String, Personne> personnes = {};
    for (final entry in noeuds.entries) {
      if (entry.value is PersonNode) {
        personnes[entry.key] = (entry.value as PersonNode).personne;
      }
    }
    return personnes;
  }
  
  Map<String, Union> obtenirUnions() {
    final Map<String, Union> unions = {};
    for (final entry in noeuds.entries) {
      if (entry.value is UnionNode) {
        unions[entry.key] = (entry.value as UnionNode).union;
      }
    }
    return unions;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Graphe:');
    for (final entry in noeuds.entries) {
      final enfants = liensSortants[entry.key] ?? [];
      buffer.writeln('  ${entry.value} -> ${enfants.join(', ')}');
    }
    return buffer.toString();
  }
}

// Constructeur de graphe
class GrapheBuilder {
  final UnionRepository _unionRepo = UnionRepository();
  final FiliationRepository _filiationRepo = FiliationRepository();
  final PersonneRepository _personneRepo = PersonneRepository();
  
  Future<Graphe> construireGraphe(Personne racine) async {
    final graphe = Graphe();
    final Set<String> visites = <String>{};
    final List<String> fileAttente = [racine.id];
    
    // Parcours BFS pour construire le graphe
    while (fileAttente.isNotEmpty) {
      final personneId = fileAttente.removeAt(0);
      if (visites.contains(personneId)) continue;
      visites.add(personneId);
      
      final personne = await _personneRepo.getById(personneId);
      if (personne == null) continue;
      
      // Ajouter le nœud personne
      final personNode = PersonNode(personne);
      graphe.ajouterNoeud(personNode);
      
      // Récupérer les unions de cette personne
      final unions = await _unionRepo.getByPersonneId(personneId);
      
      for (final union in unions) {
        await _traiterUnion(graphe, union, personneId, fileAttente, visites);
      }
    }
    
    return graphe;
  }
  
  Future<void> _traiterUnion(
    Graphe graphe,
    Union union,
    String personneId,
    List<String> fileAttente,
    Set<String> visites,
  ) async {
    // Ajouter le nœud union
    final unionNode = UnionNode(union);
    graphe.ajouterNoeud(unionNode);
    
    // Ajouter le lien personne -> union
    graphe.ajouterLien(personneId, union.id);
    
    // Récupérer tous les participants de l'union
    final participants = await _unionRepo.getParticipants(union.id);
    
    // Ajouter les autres participants et leurs liens
    for (final participant in participants) {
      if (participant.id != personneId) {
        final participantNode = PersonNode(participant);
        graphe.ajouterNoeud(participantNode);
        graphe.ajouterLien(participant.id, union.id);
        
        // Ajouter à la file d'attente pour exploration
        if (!visites.contains(participant.id)) {
          fileAttente.add(participant.id);
        }
      }
    }
    
    // Traiter les enfants de l'union
    final enfants = await _filiationRepo.getEnfantsByUnionId(union.id);
    if (enfants.isNotEmpty) {
      final enfantIds = enfants.map((e) => e.id).toList();
      final childGroupNode = ChildGroupNode(enfantIds, union.id);
      graphe.ajouterNoeud(childGroupNode);
      
      // Ajouter le lien union -> child_group
      graphe.ajouterLien(union.id, childGroupNode.id);
      
      // Ajouter les enfants et leurs liens
      for (final enfant in enfants) {
        final enfantNode = PersonNode(enfant);
        graphe.ajouterNoeud(enfantNode);
        graphe.ajouterLien(childGroupNode.id, enfant.id);
        
        // Ajouter à la file d'attente pour exploration
        if (!visites.contains(enfant.id)) {
          fileAttente.add(enfant.id);
        }
      }
    }
  }
}

// Positionneur d'arbre (algorithme de Buchheim/Walker adapté)
class PositionneurArbre {
  static const double LARGEUR_PERSONNE = ARBRE_LARGEUR_PERSONNE;
  static const double HAUTEUR_PERSONNE = ARBRE_HAUTEUR_PERSONNE;
  static const double LARGEUR_UNION = ARBRE_LARGEUR_UNION;
  static const double ESPACEMENT_HORIZONTAL = ARBRE_ESPACEMENT_HORIZONTAL;
  static const double ESPACEMENT_VERTICAL = ARBRE_ESPACEMENT_VERTICAL;
  
  Map<String, Offset> positions = {};
  Map<String, double> largeurs = {};
  Map<String, int> niveaux = {};
  
  void calculerPositions(Graphe graphe, String racineId) {
    // 1. Calculer les niveaux (BFS depuis racine)
    _calculerNiveaux(graphe, racineId);
    
    // 2. Calculer les largeurs de sous-arbres (post-order)
    _calculerLargeurs(graphe, racineId);
    
    // 3. Positionner horizontalement (pre-order)
    _positionnerHorizontalement(graphe, racineId, 0.0);
    
    // 4. Résoudre les chevauchements
    _resoudreChevauchements(graphe);
    
    // 5. Appliquer les positions Y = niveau * ESPACEMENT_VERTICAL
    _appliquerPositionsY();
  }
  
  void _calculerNiveaux(Graphe graphe, String racineId) {
    final Map<String, int> niveauxTemp = {};
    final List<(String, int)> fileAttente = [(racineId, 0)];
    final Set<String> visites = <String>{};
    
    while (fileAttente.isNotEmpty) {
      final (noeudId, niveau) = fileAttente.removeAt(0);
      if (visites.contains(noeudId)) continue;
      
      visites.add(noeudId);
      niveauxTemp[noeudId] = niveau;
      
      final enfants = graphe.getEnfants(noeudId);
      for (final enfantId in enfants) {
        fileAttente.add((enfantId, niveau + 1));
      }
    }
    
    niveaux = niveauxTemp;
  }
  
  double _calculerLargeurs(Graphe graphe, String noeudId) {
    if (largeurs.containsKey(noeudId)) {
      return largeurs[noeudId]!;
    }
    
    final noeud = graphe.obtenirNoeud(noeudId);
    if (noeud == null) return 0.0;
    
    double largeur = _getLargeurNoeud(noeudId);
    final enfants = graphe.getEnfants(noeudId);
    
    if (enfants.isNotEmpty) {
      double largeurEnfants = 0.0;
      for (final enfantId in enfants) {
        largeurEnfants += _calculerLargeurs(graphe, enfantId);
      }
      largeurEnfants += (enfants.length - 1) * ESPACEMENT_HORIZONTAL;
      largeur = max(largeur, largeurEnfants);
    }
    
    largeurs[noeudId] = largeur;
    return largeur;
  }
  
  double _getLargeurNoeud(String noeudId) {
    return largeurs[noeudId] ?? _getLargeurParDefaut(noeudId);
  }
  
  void _positionnerHorizontalement(Graphe graphe, String noeudId, double x) {
    positions[noeudId] = Offset(x, 0.0);
    
    final enfants = graphe.getEnfants(noeudId);
    if (enfants.isEmpty) return;
    
    double xEnfant = x;
    for (final enfantId in enfants) {
      _positionnerHorizontalement(graphe, enfantId, xEnfant);
      xEnfant += largeurs[enfantId]! + ESPACEMENT_HORIZONTAL;
    }
    
    // Centrer le parent sur les enfants
    double largeurEnfants = 0.0;
    for (final enfantId in enfants) {
      largeurEnfants += largeurs[enfantId]!;
    }
    final largeurTotaleEnfants = largeurEnfants + (enfants.length - 1) * ESPACEMENT_HORIZONTAL;
    final xParent = x + (largeurTotaleEnfants - _getLargeurParDefaut(noeudId)) / 2;
    positions[noeudId] = Offset(xParent, 0.0);
  }
  
  void _resoudreChevauchements(Graphe graphe) {
    final List<List<String>> noeudsParNiveau = _grouperParNiveau();
    
    for (final niveau in noeudsParNiveau) {
      for (int i = 0; i < niveau.length; i++) {
        for (int j = i + 1; j < niveau.length; j++) {
          final noeud1 = niveau[i];
          final noeud2 = niveau[j];
          
          if (_chevauchent(noeud1, noeud2)) {
            final delta = _calculerDeltaPourEviterChevauchement(noeud1, noeud2);
            _decalerSousArbre(noeud2, delta, graphe);
          }
        }
      }
    }
  }
  
  List<List<String>> _grouperParNiveau() {
    final Map<int, List<String>> noeudsParNiveau = {};
    
    for (final entry in niveaux.entries) {
      final niveau = entry.value;
      noeudsParNiveau.putIfAbsent(niveau, () => []).add(entry.key);
    }
    
    // Trier par niveau
    final niveauxTries = noeudsParNiveau.keys.toList()..sort();
    return niveauxTries.map((niveau) => noeudsParNiveau[niveau]!).toList();
  }
  
  bool _chevauchement(String noeudId1, String noeudId2) {
    final pos1 = positions[noeudId1];
    final pos2 = positions[noeudId2];
    
    if (pos1 == null || pos2 == null) return false;
    
    final largeur1 = _getLargeurParDefaut(noeudId1);
    final largeur2 = _getLargeurParDefaut(noeudId2);
    
    return !(pos1.dx + largeur1 <= pos2.dx || pos2.dx + largeur2 <= pos1.dx);
  }
  
  bool _chevauchent(String noeudId1, String noeudId2) {
    return _chevauchement(noeudId1, noeudId2) || _chevauchement(noeudId2, noeudId1);
  }
  
  Offset _calculerDeltaPourEviterChevauchement(String noeudId1, String noeudId2) {
    final pos1 = positions[noeudId1]!;
    final pos2 = positions[noeudId2]!;
    final largeur1 = _getLargeurParDefaut(noeudId1);
    
    return Offset(pos1.dx + largeur1 + ESPACEMENT_HORIZONTAL - pos2.dx, 0.0);
  }
  
  void _decalerSousArbre(String noeudId, Offset delta, Graphe graphe) {
    final Set<String> visites = <String>{};
    final List<String> fileAttente = [noeudId];
    
    while (fileAttente.isNotEmpty) {
      final id = fileAttente.removeAt(0);
      if (visites.contains(id)) continue;
      
      visites.add(id);
      final pos = positions[id];
      if (pos != null) {
        positions[id] = pos + delta;
      }
      
      fileAttente.addAll(graphe.getEnfants(id));
    }
  }
  
  void _appliquerPositionsY() {
    for (final entry in positions.entries) {
      final noeudId = entry.key;
      final niveau = niveaux[noeudId] ?? 0;
      final pos = entry.value;
      positions[noeudId] = Offset(pos.dx, niveau * ESPACEMENT_VERTICAL);
    }
  }
  
  double _getLargeurParDefaut(String noeudId) {
    // Déterminer la largeur par défaut selon le type de nœud
    if (noeudId.startsWith('group_')) {
      return LARGEUR_UNION; // Les groupes d'enfants ont la largeur d'une union
    } else if (noeudId.length > 10 && noeudId.contains('-')) {
      // Probablement une UUID d'union
      return LARGEUR_UNION;
    } else {
      return LARGEUR_PERSONNE;
    }
  }
}
