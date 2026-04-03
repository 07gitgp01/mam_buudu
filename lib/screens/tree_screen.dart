import 'package:flutter/material.dart';
import '../models/personne.dart';
import '../models/union.dart';
import '../database/personne_repository.dart';
import '../database/union_repository.dart';
import '../database/filiation_repository.dart';

class TreeScreen extends StatefulWidget {
  final String racineId;

  const TreeScreen({
    super.key,
    required this.racineId,
  });

  @override
  State<TreeScreen> createState() => _TreeScreenState();
}

class _TreeScreenState extends State<TreeScreen> {
  final PersonneRepository _personneRepo = PersonneRepository();
  final UnionRepository _unionRepo = UnionRepository();
  final FiliationRepository _filiationRepo = FiliationRepository();
  
  // État de l'arbre
  final Map<String, Personne> _allPersonnes = {};
  final Map<String, Union> _allUnions = {};
  final Map<String, List<String>> _relationsParentsEnfants = {};
  final Map<String, List<String>> _relationsEnfantsParents = {};
  final Map<String, Offset> _positions = {};
  
  // Contrôles de vue
  final TransformationController _transformationController = TransformationController();
  double _scale = 1.0;
  Offset _panOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _chargerArbreComplet();
  }

  Future<void> _chargerArbreComplet() async {
    try {
      setState(() {
        _positions.clear();
        _allPersonnes.clear();
        _allUnions.clear();
        _relationsParentsEnfants.clear();
        _relationsEnfantsParents.clear();
      });

      // 1. Charger TOUTES les personnes de la base de données
      final toutesLesPersonnes = await _personneRepo.getAll();
      for (final personne in toutesLesPersonnes) {
        _allPersonnes[personne.id] = personne;
      }

      // 2. Charger TOUTES les unions
      final toutesLesUnions = await _unionRepo.getAll();
      for (final union in toutesLesUnions) {
        _allUnions[union.id] = union;
      }

      // 3. Construire les relations parent-enfant complètes
      await _construireRelationsCompletes();

      // 4. Calculer les positions pour toutes les personnes
      _calculerPositionsArbre();

      // 5. Centrer automatiquement sur la racine
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centrerSurRacine();
      });

      setState(() {});
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement de l\'arbre: $e')),
        );
      }
    }
  }

  Future<void> _construireRelationsCompletes() async {
    // Initialiser les relations
    for (final personneId in _allPersonnes.keys) {
      _relationsParentsEnfants[personneId] = [];
      _relationsEnfantsParents[personneId] = [];
    }

    // Parcourir toutes les unions pour construire les relations
    for (final union in _allUnions.values) {
      // Récupérer les participants de l'union
      final participants = await _unionRepo.getParticipants(union.id);
      if (participants.length < 2) continue;

      // Récupérer les enfants de cette union
      final enfants = await _filiationRepo.getEnfantsByUnionId(union.id);

      // Pour chaque enfant, établir les relations avec les parents
      for (final enfant in enfants) {
        for (final parent in participants) {
          // Relation parent -> enfant
          if (!_relationsParentsEnfants[parent.id]!.contains(enfant.id)) {
            _relationsParentsEnfants[parent.id]!.add(enfant.id);
          }
          
          // Relation enfant -> parent
          if (!_relationsEnfantsParents[enfant.id]!.contains(parent.id)) {
            _relationsEnfantsParents[enfant.id]!.add(parent.id);
          }
        }
      }
    }
  }

  void _calculerPositionsArbre() {
    if (_allPersonnes.isEmpty) return;

    // Algorithme simple de positionnement en arbre
    final Map<String, int> niveaux = {};
    final List<String> fileAttente = [widget.racineId];
    final Set<String> visites = <String>{};
    int niveauActuel = 0;

    // Calculer les niveaux par BFS
    while (fileAttente.isNotEmpty) {
      final niveauSize = fileAttente.length;
      
      for (int i = 0; i < niveauSize; i++) {
        final personneId = fileAttente.removeAt(0);
        if (visites.contains(personneId)) continue;
        
        visites.add(personneId);
        niveaux[personneId] = niveauActuel;
        
        // Ajouter les enfants à la file d'attente
        final enfants = _relationsParentsEnfants[personneId] ?? [];
        for (final enfantId in enfants) {
          if (!visites.contains(enfantId)) {
            fileAttente.add(enfantId);
          }
        }
        
        // Ajouter les parents à la file d'attente (pour remonter l'arbre)
        final parents = _relationsEnfantsParents[personneId] ?? [];
        for (final parentId in parents) {
          if (!visites.contains(parentId)) {
            fileAttente.add(parentId);
          }
        }
      }
      
      niveauActuel++;
    }

    // Grouper par niveau
    final Map<int, List<String>> personnesParNiveau = {};
    for (final entry in niveaux.entries) {
      final niveau = entry.value;
      final personneId = entry.key;
      
      if (!personnesParNiveau.containsKey(niveau)) {
        personnesParNiveau[niveau] = [];
      }
      personnesParNiveau[niveau]!.add(personneId);
    }

    // Positionner les personnes avec un meilleur espacement
    const double espacementHorizontal = 160.0;
    const double espacementVertical = 140.0;

    for (final entry in personnesParNiveau.entries) {
      final niveau = entry.key;
      final personnesDuNiveau = entry.value;
      
      // Centrer le groupe horizontalement
      final largeurTotale = (personnesDuNiveau.length - 1) * espacementHorizontal;
      final positionXDepart = -largeurTotale / 2;
      
      for (int i = 0; i < personnesDuNiveau.length; i++) {
        final personneId = personnesDuNiveau[i];
        _positions[personneId] = Offset(
          positionXDepart + (i * espacementHorizontal),
          niveau * espacementVertical,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Arbre généalogique (${_allPersonnes.length} personnes)'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in, color: Colors.white),
            onPressed: _zoomer,
            tooltip: 'Zoomer',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out, color: Colors.white),
            onPressed: _dezoomer,
            tooltip: 'Dézoomer',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _reinitialiserVue,
            tooltip: 'Réinitialiser la vue',
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_strong, color: Colors.white),
            onPressed: _centrerSurRacine,
            tooltip: 'Centrer sur la racine',
          ),
        ],
      ),
      body: _allPersonnes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement de l\'arbre généalogique...'),
                ],
              ),
            )
          : _buildArbreInteractif(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: _changerRacine,
            backgroundColor: Colors.green[600],
            icon: const Icon(Icons.person_search, color: Colors.white),
            label: const Text('Changer racine', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            onPressed: _navigateToLivret,
            backgroundColor: Colors.blue[600],
            icon: const Icon(Icons.book, color: Colors.white),
            label: const Text('Générer livret', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildArbreInteractif() {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.1,
      maxScale: 5.0,
      boundaryMargin: const EdgeInsets.all(100),
      panEnabled: true,
      scaleEnabled: true,
      onInteractionUpdate: (details) {
        setState(() {
          _scale = _transformationController.value.getMaxScaleOnAxis();
        });
      },
      child: Container(
        width: 2000,
        height: 2000,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50]!,
              Colors.green[50]!,
            ],
          ),
        ),
        child: GestureDetector(
          onTapDown: _handleTapDown,
          child: CustomPaint(
            painter: ArbreGenealogiquePainter(
              positions: _positions,
              personnes: _allPersonnes,
              relationsParentsEnfants: _relationsParentsEnfants,
              relationsEnfantsParents: _relationsEnfantsParents,
              onTapPersonne: _handleTapPersonne,
            ),
            size: const Size(2000, 2000),
          ),
        ),
      ),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    final tapPosition = details.localPosition;
    final personneProche = _trouverPersonneLaPlusProche(tapPosition);
    
    if (personneProche != null) {
      _handleTapPersonne(personneProche);
    }
  }

  void _handleTapPersonne(String personneId) {
    final personne = _allPersonnes[personneId];
    if (personne != null) {
      Navigator.pushNamed(
        context,
        '/person/detail',
        arguments: personneId,
      );
    }
  }

  String? _trouverPersonneLaPlusProche(Offset position) {
    String? personneLaPlusProche;
    double distanceMin = double.infinity;
    
    for (final entry in _positions.entries) {
      final personnePos = entry.value;
      final distance = (position - personnePos).distance;
      
      if (distance < distanceMin && distance < 60.0) {
        distanceMin = distance;
        personneLaPlusProche = entry.key;
      }
    }
    
    return personneLaPlusProche;
  }

  void _zoomer() {
    final newScale = (_scale * 1.3).clamp(0.1, 5.0);
    _transformationController.value = Matrix4.identity()
      ..translate(_panOffset.dx, _panOffset.dy)
      ..scale(newScale, newScale, 1.0);
    _scale = newScale;
  }

  void _dezoomer() {
    final newScale = (_scale / 1.3).clamp(0.1, 5.0);
    _transformationController.value = Matrix4.identity()
      ..translate(_panOffset.dx, _panOffset.dy)
      ..scale(newScale, newScale, 1.0);
    _scale = newScale;
  }

  void _reinitialiserVue() {
    _transformationController.value = Matrix4.identity();
    _scale = 1.0;
    _panOffset = Offset.zero;
    
    Future.delayed(const Duration(milliseconds: 100), () {
      _centrerSurRacine();
    });
  }

  void _centrerSurRacine() {
    if (_positions.isEmpty) return;
    
    final racinePos = _positions[widget.racineId];
    if (racinePos != null) {
      // Calculer le centre du canvas (2000x2000)
      final canvasCenter = const Offset(1000, 1000);
      
      // Calculer le décalage pour centrer la racine
      final offset = canvasCenter - racinePos;
      
      _transformationController.value = Matrix4.identity()
        ..translate(offset.dx, offset.dy)
        ..scale(1.0, 1.0, 1.0);
      
      _scale = 1.0;
      _panOffset = offset;
    }
  }

  void _navigateToLivret() {
    Navigator.pushNamed(context, '/livret');
  }

  Future<void> _changerRacine() async {
    final personnes = _allPersonnes.values.toList();
    if (personnes.isEmpty) return;
    
    final personneSelectionnee = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer de racine'),
        content: SizedBox(
          width: 400,
          height: 500,
          child: ListView.builder(
            itemCount: personnes.length,
            itemBuilder: (context, index) {
              final personne = personnes[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: personne.sexe == 'M' ? Colors.blue[300] : Colors.pink[300],
                  child: Icon(
                    personne.sexe == 'M' ? Icons.man : Icons.woman,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text('${personne.prenoms} ${personne.nomUsage ?? personne.nomNaissance}'),
                subtitle: personne.datesAffichage.isNotEmpty 
                    ? Text(personne.datesAffichage)
                    : null,
                onTap: () {
                  Navigator.of(context).pop(personne.id);
                },
              );
            },
          ),
        ),
      ),
    );

    if (personneSelectionnee != null && personneSelectionnee != widget.racineId) {
      Navigator.pushReplacementNamed(
        context,
        '/tree',
        arguments: personneSelectionnee,
      );
    }
  }
}

class ArbreGenealogiquePainter extends CustomPainter {
  final Map<String, Offset> positions;
  final Map<String, Personne> personnes;
  final Map<String, List<String>> relationsParentsEnfants;
  final Map<String, List<String>> relationsEnfantsParents;
  final Function(String personneId)? onTapPersonne;
  
  const ArbreGenealogiquePainter({
    required this.positions,
    required this.personnes,
    required this.relationsParentsEnfants,
    required this.relationsEnfantsParents,
    this.onTapPersonne,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dessiner les liens parent-enfant
    _dessinerLiensParentEnfant(canvas);
    
    // 2. Dessiner les personnes
    _dessinerPersonnes(canvas);
  }
  
  void _dessinerLiensParentEnfant(Canvas canvas) {
    // Dessiner les liens parents -> enfants avec des courbes douces
    for (final entry in relationsParentsEnfants.entries) {
      final parentId = entry.key;
      final parentPos = positions[parentId];
      if (parentPos == null) continue;
      
      for (final enfantId in entry.value) {
        final enfantPos = positions[enfantId];
        if (enfantPos == null) continue;
        
        _dessinerLienCourbe(canvas, parentPos, enfantPos);
      }
    }
  }
  
  void _dessinerLienCourbe(Canvas canvas, Offset source, Offset cible) {
    final paint = Paint()
      ..color = Colors.grey[700]!
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Ombre du lien
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    path.moveTo(source.dx, source.dy);
    
    // Calculer les points de contrôle pour une courbe naturelle
    final distance = (cible - source).distance;
    final controlDistance = distance * 0.3;
    
    final controlPoint1 = Offset(source.dx, source.dy + controlDistance);
    final controlPoint2 = Offset(cible.dx, cible.dy - controlDistance);
    
    path.cubicTo(
      controlPoint1.dx, controlPoint1.dy,
      controlPoint2.dx, controlPoint2.dy,
      cible.dx, cible.dy,
    );
    
    // Dessiner l'ombre
    canvas.drawPath(path, shadowPaint);
    // Dessiner le lien principal
    canvas.drawPath(path, paint);
  }
  
  void _dessinerPersonnes(Canvas canvas) {
    for (final entry in personnes.entries) {
      final personneId = entry.key;
      final personne = entry.value;
      final pos = positions[personneId];
      if (pos == null) continue;
      
      _dessinerPersonne(canvas, pos, personne);
    }
  }
  
  void _dessinerPersonne(Canvas canvas, Offset pos, Personne personne) {
    // Couleur selon le sexe avec dégradé
    final couleurBase = personne.sexe == 'M' ? Colors.blue[400]! : 
                       personne.sexe == 'F' ? Colors.pink[400]! : 
                       Colors.grey[400]!;
    
    // Ombre de la carte
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    final shadowRect = RRect.fromLTRBR(
      pos.dx - 65,
      pos.dy - 35,
      pos.dx + 65,
      pos.dy + 35,
      const Radius.circular(12),
    );
    canvas.drawRRect(shadowRect, shadowPaint);
    
    // Rectangle principal avec dégradé
    final paint = Paint()
      ..color = couleurBase
      ..style = PaintingStyle.fill;
    
    final rect = RRect.fromLTRBR(
      pos.dx - 60,
      pos.dy - 30,
      pos.dx + 60,
      pos.dy + 30,
      const Radius.circular(10),
    );
    
    canvas.drawRRect(rect, paint);
    
    // Bordure lumineuse
    final borderPaint = Paint()
      ..color = couleurBase.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawRRect(rect, borderPaint);
    
    // Icône selon le sexe
    final iconPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    
    final icon = personne.sexe == 'M' ? Icons.man : Icons.woman;
    _dessinerIcone(canvas, pos, icon, iconPaint);
    
    // Texte
    _dessinerTextePersonne(canvas, pos, personne);
  }
  
  void _dessinerIcone(Canvas canvas, Offset pos, IconData icon, Paint paint) {
    // Dessiner une icône simple (cercle avec symbole)
    final center = Offset(pos.dx, pos.dy - 5);
    canvas.drawCircle(center, 8, paint);
    
    // Ajouter le texte de l'icône
    final textPainter = TextPainter(
      text: TextSpan(
        text: icon == Icons.man ? 'M' : 'F',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - 3, center.dy - 5));
  }
  
  void _dessinerTextePersonne(Canvas canvas, Offset pos, Personne personne) {
    final prenoms = personne.prenoms?.split(' ').take(2).join(' ') ?? '';
    final nom = personne.nomUsage?.isNotEmpty == true ? 
                personne.nomUsage! : 
                personne.nomNaissance ?? '';
    
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: prenoms,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          if (nom.isNotEmpty)
            TextSpan(
              text: '\n$nom',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
        ],
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout(maxWidth: 100);
    
    final textOffset = Offset(
      pos.dx - textPainter.width / 2,
      pos.dy + 8,
    );
    
    textPainter.paint(canvas, textOffset);
  }
  
  @override
  bool shouldRepaint(ArbreGenealogiquePainter oldDelegate) => true;
}
