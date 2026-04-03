import 'package:flutter/material.dart';
import '../models/personne.dart';
import '../models/union.dart';
import '../widgets/arbre_unions_multiples.dart';
import '../utils/constants.dart';

class ArbrePainter extends CustomPainter {
  final Map<String, Offset> positions;
  final Graphe graphe;
  final Map<String, Personne> personnes;
  final Map<String, Union> unions;
  final Function(String personneId)? onTapPersonne;
  
  const ArbrePainter({
    required this.positions,
    required this.graphe,
    required this.personnes,
    required this.unions,
    this.onTapPersonne,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dessiner les liens (bezier courbé)
    _dessinerLiens(canvas);
    
    // 2. Dessiner les nœuds selon leur type
    _dessinerNoeuds(canvas);
  }
  
  void _dessinerLiens(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    for (final entry in graphe.liensSortants.entries) {
      final sourceId = entry.key;
      final sourcePos = positions[sourceId];
      if (sourcePos == null) continue;
      
      for (final cibleId in entry.value) {
        final ciblePos = positions[cibleId];
        if (ciblePos == null) continue;
        
        _dessinerLien(canvas, sourcePos, ciblePos);
      }
    }
  }
  
  void _dessinerLien(Canvas canvas, Offset source, Offset cible) {
    final path = Path();
    path.moveTo(source.dx, source.dy);
    final midY = (source.dy + cible.dy) / 2;
    path.cubicTo(source.dx, midY, cible.dx, midY, cible.dx, cible.dy);
    canvas.drawPath(path, Paint()..color = Colors.grey[400]!..strokeWidth = 2..style = PaintingStyle.stroke);
  }
  
  void _dessinerNoeuds(Canvas canvas) {
    for (final entry in graphe.noeuds.entries) {
      final noeudId = entry.key;
      final noeud = entry.value;
      final pos = positions[noeudId];
      if (pos == null) continue;
      
      if (noeud is PersonNode) {
        _dessinerPersonne(canvas, pos, noeud.personne);
      } else if (noeud is UnionNode) {
        _dessinerUnion(canvas, pos, noeud.union);
      } else if (noeud is ChildGroupNode) {
        _dessinerGroupeEnfants(canvas, pos, noeud);
      }
    }
  }
  
  void _dessinerPersonne(Canvas canvas, Offset pos, Personne p) {
    // Rectangle arrondi, couleur selon sexe (M: bleu, F: rose, X: gris)
    final paint = Paint()
      ..color = p.sexe == 'M' ? Colors.blue[100]! : 
                p.sexe == 'F' ? Colors.pink[100]! : 
                Colors.grey[100]!
      ..style = PaintingStyle.fill;
    
    final rect = RRect.fromLTRBR(
      pos.dx - ARBRE_LARGEUR_PERSONNE / 2,
      pos.dy - ARBRE_HAUTEUR_PERSONNE / 2,
      pos.dx + ARBRE_LARGEUR_PERSONNE / 2,
      pos.dy + ARBRE_HAUTEUR_PERSONNE / 2,
      const Radius.circular(8),
    );
    
    canvas.drawRRect(rect, paint);
    
    // Texte : prénom + nom (2 lignes max)
    _dessinerTextePersonne(canvas, pos, p);
  }
  
  void _dessinerTextePersonne(Canvas canvas, Offset pos, Personne p) {
    final prenoms = p.prenoms?.split(' ') ?? [];
    final nom = p.nomUsage?.isNotEmpty == true ? p.nomUsage! : p.nomNaissance ?? '';
    
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: prenoms.take(2).join(' '),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (nom.isNotEmpty)
            TextSpan(
              text: '\n$nom',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
              ),
            ),
        ],
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout(
      maxWidth: ARBRE_LARGEUR_PERSONNE - 8,
    );
    
    final textOffset = Offset(
      pos.dx - textPainter.width / 2,
      pos.dy - textPainter.height / 2,
    );
    
    textPainter.paint(canvas, textOffset);
  }
  
  void _dessinerUnion(Canvas canvas, Offset pos, Union u) {
    // Losange jaune avec 💍 au centre
    final paint = Paint()
      ..color = Colors.amber[300]!
      ..style = PaintingStyle.fill;
    
    final size = ARBRE_LARGEUR_UNION;
    final path = Path();
    
    // Point supérieur
    path.moveTo(pos.dx, pos.dy - size / 2);
    // Point droit
    path.lineTo(pos.dx + size / 2, pos.dy);
    // Point inférieur
    path.lineTo(pos.dx, pos.dy + size / 2);
    // Point gauche
    path.lineTo(pos.dx - size / 2, pos.dy);
    // Retour au point supérieur
    path.lineTo(pos.dx, pos.dy - size / 2);
    
    path.close();
    canvas.drawPath(path, paint);
    
    // Icône 💍 au centre
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '💍',
        style: TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    final textOffset = Offset(
      pos.dx - textPainter.width / 2,
      pos.dy - textPainter.height / 2,
    );
    
    textPainter.paint(canvas, textOffset);
  }
  
  void _dessinerGroupeEnfants(Canvas canvas, Offset pos, ChildGroupNode g) {
    // Rectangle vert clair avec icône 👶 et nombre
    final paint = Paint()
      ..color = Colors.green[100]!
      ..style = PaintingStyle.fill;
    
    final rect = RRect.fromLTRBR(
      pos.dx - ARBRE_LARGEUR_UNION / 2,
      pos.dy - ARBRE_HAUTEUR_PERSONNE / 2,
      pos.dx + ARBRE_LARGEUR_UNION / 2,
      pos.dy + ARBRE_HAUTEUR_PERSONNE / 2,
      const Radius.circular(8),
    );
    
    canvas.drawRRect(rect, paint);
    
    // Icône 👶 et nombre d'enfants
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          const TextSpan(
            text: '👶',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          TextSpan(
            text: ' ${g.enfantIds.length}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    final textOffset = Offset(
      pos.dx - textPainter.width / 2,
      pos.dy - textPainter.height / 2,
    );
    
    textPainter.paint(canvas, textOffset);
  }
  
  @override
  bool shouldRepaint(ArbrePainter oldDelegate) => true;
}
