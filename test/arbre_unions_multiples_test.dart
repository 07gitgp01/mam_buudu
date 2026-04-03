import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/personne.dart';
import '../../lib/models/union.dart';
import '../../lib/models/date_partielle.dart';
import '../../lib/database/personne_repository.dart';
import '../../lib/database/union_repository.dart';
import '../../lib/database/filiation_repository.dart';
import '../../lib/widgets/arbre_unions_multiples.dart';

void main() {
  group('Arbre Unions Multiples Tests', () {
    late PersonneRepository personneRepo;
    late UnionRepository unionRepo;
    late FiliationRepository filiationRepo;
    late GrapheBuilder grapheBuilder;
    late PositionneurArbre positionneur;

    setUpAll(() async {
      // Initialisation des repositories
      personneRepo = PersonneRepository();
      unionRepo = UnionRepository();
      filiationRepo = FiliationRepository();
      grapheBuilder = GrapheBuilder();
      positionneur = PositionneurArbre();
    });

    test('Test simple: 2 personnes + union + 1 enfant', () async {
      // Création des personnes de test
      final personne1 = Personne(
        id: 'p1',
        nomNaissance: 'Dupont',
        prenoms: 'Jean',
        sexe: 'M',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final personne2 = Personne(
        id: 'p2',
        nomNaissance: 'Durand',
        prenoms: 'Marie',
        sexe: 'F',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final enfant = Personne(
        id: 'e1',
        nomNaissance: 'Dupont',
        prenoms: 'Pierre',
        sexe: 'M',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Création de l'union
      final union = Union(
        id: 'u1',
        type: 'mariage',
        dateDebut: DatePartielle.annee(2020),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Construction du graphe
      final graphe = Graphe();
      
      // Ajout des nœuds
      final personNode1 = PersonNode(personne1);
      final personNode2 = PersonNode(personne2);
      final unionNode = UnionNode(union);
      final enfantNode = PersonNode(enfant);
      final childGroupNode = ChildGroupNode(['e1'], 'u1');

      graphe.ajouterNoeud(personNode1);
      graphe.ajouterNoeud(personNode2);
      graphe.ajouterNoeud(unionNode);
      graphe.ajouterNoeud(enfantNode);
      graphe.ajouterNoeud(childGroupNode);

      // Ajout des liens
      graphe.ajouterLien('p1', 'u1');
      graphe.ajouterLien('p2', 'u1');
      graphe.ajouterLien('u1', 'group_e1');
      graphe.ajouterLien('group_e1', 'e1');

      // Vérification de la structure
      expect(graphe.noeuds.length, equals(5));
      expect(graphe.getEnfants('p1'), contains('u1'));
      expect(graphe.getEnfants('p2'), contains('u1'));
      expect(graphe.getEnfants('u1'), contains('group_e1'));
      expect(graphe.getEnfants('group_e1'), contains('e1'));

      // Test du positionnement
      positionneur.calculerPositions(graphe, 'p1');
      
      expect(positionneur.positions.containsKey('p1'), isTrue);
      expect(positionneur.positions.containsKey('p2'), isTrue);
      expect(positionneur.positions.containsKey('u1'), isTrue);
      expect(positionneur.positions.containsKey('e1'), isTrue);

      // Vérification des niveaux
      expect(positionneur.niveaux['p1'], equals(0));
      expect(positionneur.niveaux['p2'], equals(0));
      expect(positionneur.niveaux['u1'], equals(1));
      expect(positionneur.niveaux['e1'], equals(2));
    });

    test('Test remariage: personne A union1 avec B, union2 avec C', () async {
      // Création des personnes
      final personneA = Personne(
        id: 'pa',
        nomNaissance: 'Martin',
        prenoms: 'Alice',
        sexe: 'F',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final personneB = Personne(
        id: 'pb',
        nomNaissance: 'Bernard',
        prenoms: 'Bob',
        sexe: 'M',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final personneC = Personne(
        id: 'pc',
        nomNaissance: 'Charles',
        prenoms: 'Charlie',
        sexe: 'M',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Création des unions
      final union1 = Union(
        id: 'u1',
        type: 'mariage',
        dateDebut: DatePartielle.annee(2010),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final union2 = Union(
        id: 'u2',
        type: 'mariage',
        dateDebut: DatePartielle.annee(2020),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Construction du graphe
      final graphe = Graphe();
      
      // Ajout des nœuds
      graphe.ajouterNoeud(PersonNode(personneA));
      graphe.ajouterNoeud(PersonNode(personneB));
      graphe.ajouterNoeud(PersonNode(personneC));
      graphe.ajouterNoeud(UnionNode(union1));
      graphe.ajouterNoeud(UnionNode(union2));

      // Ajout des liens (remariage)
      graphe.ajouterLien('pa', 'u1');
      graphe.ajouterLien('pb', 'u1');
      graphe.ajouterLien('pa', 'u2');
      graphe.ajouterLien('pc', 'u2');

      // Vérification de la structure
      expect(graphe.noeuds.length, equals(5));
      expect(graphe.getEnfants('pa'), unorderedEquals(['u1', 'u2']));
      expect(graphe.getEnfants('pb'), contains('u1'));
      expect(graphe.getEnfants('pc'), contains('u2'));

      // Test du positionnement
      positionneur.calculerPositions(graphe, 'pa');
      
      expect(positionneur.positions.containsKey('pa'), isTrue);
      expect(positionneur.positions.containsKey('pb'), isTrue);
      expect(positionneur.positions.containsKey('pc'), isTrue);
      expect(positionneur.positions.containsKey('u1'), isTrue);
      expect(positionneur.positions.containsKey('u2'), isTrue);

      // Vérification des niveaux
      expect(positionneur.niveaux['pa'], equals(0));
      expect(positionneur.niveaux['pb'], equals(1));
      expect(positionneur.niveaux['pc'], equals(1));
      expect(positionneur.niveaux['u1'], equals(1));
      expect(positionneur.niveaux['u2'], equals(1));
    });

    test('Test détection de boucles infinies', () async {
      // Création d'un graphe avec une boucle
      final graphe = Graphe();
      
      final personne1 = Personne(
        id: 'p1',
        nomNaissance: 'Test1',
        prenoms: 'Alice',
        sexe: 'F',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final personne2 = Personne(
        id: 'p2',
        nomNaissance: 'Test2',
        prenoms: 'Bob',
        sexe: 'M',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Ajout des nœuds
      graphe.ajouterNoeud(PersonNode(personne1));
      graphe.ajouterNoeud(PersonNode(personne2));

      // Création d'une boucle (p1 -> p2 -> p1)
      graphe.ajouterLien('p1', 'p2');
      graphe.ajouterLien('p2', 'p1');

      // Test du positionnement
      positionneur.calculerPositions(graphe, 'p1');

      // Vérification que les deux nœuds ont des positions
      expect(positionneur.positions.containsKey('p1'), isTrue);
      expect(positionneur.positions.containsKey('p2'), isTrue);

      // Vérification qu'ils sont au même niveau (pas de hiérarchie claire)
      expect(positionneur.niveaux['p1'], equals(positionneur.niveaux['p2']));
    });

    test('Test largeurs des nœuds', () {
      final positionneur = PositionneurArbre();
      
      // Test largeur personne
      expect(positionneur._getLargeurParDefaut('person_id'), equals(120.0));
      
      // Test largeur union
      expect(positionneur._getLargeurParDefaut('union_id'), equals(60.0));
      
      // Test largeur groupe d'enfants
      expect(positionneur._getLargeurParDefaut('group_child1_child2'), equals(60.0));
      
      // Test largeur UUID
      expect(positionneur._getLargeurParDefaut('123e4567-e89b-12d3-a456-426614174000'), equals(60.0));
    });

    test('Test résolution de chevauchements', () {
      final graphe = Graphe();
      final positionneur = PositionneurArbre();
      
      // Création de nœuds qui se chevauchent
      graphe.ajouterNoeud(PersonNode(Personne(
        id: 'p1',
        nomNaissance: 'Test1',
        prenoms: 'Alice',
        sexe: 'F',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )));
      
      graphe.ajouterNoeud(PersonNode(Personne(
        id: 'p2',
        nomNaissance: 'Test2',
        prenoms: 'Bob',
        sexe: 'M',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )));

      // Positionnement initial avec chevauchement
      positionneur.positions['p1'] = const Offset(0, 0);
      positionneur.positions['p2'] = const Offset(50, 0); // Chevauchement avec p1 (largeur 120)
      positionneur.niveaux['p1'] = 0;
      positionneur.niveaux['p2'] = 0;

      // Test de détection de chevauchement
      expect(positionneur._chevauchement('p1', 'p2'), isTrue);
      expect(positionneur._chevauchement('p2', 'p1'), isTrue);
      
      // Test de résolution
      final delta = positionneur._calculerDeltaPourEviterChevauchement('p1', 'p2');
      expect(delta.dx, greaterThan(0)); // Doit décaler p2 vers la droite
    });
  });
}
