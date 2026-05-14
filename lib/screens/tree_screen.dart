import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/personne.dart';
import '../models/union.dart';
import '../database/personne_repository.dart';
import '../database/union_repository.dart';
import '../theme/family_connect_theme.dart';

// ── Constantes de mise en page ──────────────────
const double _nodeW = 140.0;
const double _nodeH = 64.0;
const double _avatarR = 20.0; // rayon du cercle-photo
const double _coupleGap = 44.0;
const double _levelH = 160.0;
const double _hGap = 22.0;
const double _canvasPad = 80.0;

// ───────────────────────────────────────────────
class TreeScreen extends StatefulWidget {
  final String racineId;
  const TreeScreen({super.key, required this.racineId});

  @override
  State<TreeScreen> createState() => _TreeScreenState();
}

class _TreeScreenState extends State<TreeScreen> {
  final PersonneRepository _personneRepo = PersonneRepository();
  final UnionRepository _unionRepo = UnionRepository();

  Map<String, Personne> _personnes = {};
  List<Union> _unions = [];

  Map<String, List<Union>> _unionsByParent = {};
  Map<String, Union> _unionByChild = {};

  // Images préchargées : personId → dart:ui Image
  Map<String, ui.Image> _images = {};

  Map<String, Offset> _positions = {};
  double _canvasW = 2000;
  double _canvasH = 2000;
  bool _isLoading = true;

  final TransformationController _tc = TransformationController();

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _tc.dispose();
    for (final img in _images.values) {
      img.dispose();
    }
    super.dispose();
  }

  // ── Chargement ──────────────────────────────────

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final personnes = await _personneRepo.getAll();
      _personnes = {for (final p in personnes) p.id: p};
      _unions = await _unionRepo.getAll();

      _unionsByParent = {};
      _unionByChild = {};
      for (final u in _unions) {
        for (final pid in u.parentIds) {
          _unionsByParent.putIfAbsent(pid, () => []).add(u);
        }
        for (final eid in u.enfantIds) {
          _unionByChild[eid] = u;
        }
      }

      _calculerPositions();
      await _chargerImages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement : $e')),
        );
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _centrer());
    }
  }

  // Charge les photos en dart:ui.Image (taille réduite pour les performances)
  Future<void> _chargerImages() async {
    final newImages = <String, ui.Image>{};
    for (final p in _personnes.values) {
      if (p.photoPath == null || p.photoPath!.isEmpty) continue;
      final img = await _loadUiImage(p.photoPath!);
      if (img != null) newImages[p.id] = img;
    }
    for (final old in _images.values) {
      old.dispose();
    }
    _images = newImages;
  }

  Future<ui.Image?> _loadUiImage(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 80,
        targetHeight: 80,
      );
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  // ── BFS bidirectionnel + layout ─────────────────

  void _calculerPositions() {
    if (_personnes.isEmpty) return;

    final startId = _personnes.containsKey(widget.racineId)
        ? widget.racineId
        : _personnes.keys.first;

    // BFS : génération 0 = racine, -1 = parents, +1 = enfants…
    final genMap = <String, int>{};
    final queue = Queue<String>();
    genMap[startId] = 0;
    queue.add(startId);

    while (queue.isNotEmpty) {
      final pid = queue.removeFirst();
      final gen = genMap[pid]!;

      // Vers le bas : conjoint (même gen) + enfants (gen+1)
      for (final u in (_unionsByParent[pid] ?? [])) {
        for (final spouseId in u.parentIds) {
          if (!genMap.containsKey(spouseId) && _personnes.containsKey(spouseId)) {
            genMap[spouseId] = gen;
            queue.add(spouseId);
          }
        }
        for (final childId in u.enfantIds) {
          if (!genMap.containsKey(childId) && _personnes.containsKey(childId)) {
            genMap[childId] = gen + 1;
            queue.add(childId);
          }
        }
      }

      // Vers le haut : parents (gen-1) + frères/sœurs (même gen)
      final parentUnion = _unionByChild[pid];
      if (parentUnion != null) {
        for (final parentId in parentUnion.parentIds) {
          if (!genMap.containsKey(parentId) && _personnes.containsKey(parentId)) {
            genMap[parentId] = gen - 1;
            queue.add(parentId);
          }
        }
        for (final sibId in parentUnion.enfantIds) {
          if (!genMap.containsKey(sibId) && _personnes.containsKey(sibId)) {
            genMap[sibId] = gen;
            queue.add(sibId);
          }
        }
      }
    }

    final byGen = <int, List<String>>{};
    for (final e in genMap.entries) {
      byGen.putIfAbsent(e.value, () => []).add(e.key);
    }
    if (byGen.isEmpty) return;

    final minGen = byGen.keys.reduce(min);
    final maxGen = byGen.keys.reduce(max);

    double maxRowW = 0;
    for (final people in byGen.values) {
      maxRowW = max(maxRowW, _calcRowWidth(people));
    }

    _canvasW = max(1200, maxRowW + _canvasPad * 2);
    _canvasH = max(800, (maxGen - minGen + 1) * _levelH + _canvasPad * 2);

    _positions = {};
    for (final entry in byGen.entries) {
      final y = _canvasPad + (entry.key - minGen) * _levelH + _nodeH / 2;
      _placeRow(entry.value, y);
    }
  }

  double _calcRowWidth(List<String> people) {
    final done = <String>{};
    double w = 0;
    int groups = 0;
    for (final pid in people) {
      if (done.contains(pid)) continue;
      done.add(pid);
      final spouse = _spouseIn(pid, people);
      if (spouse != null) {
        done.add(spouse);
        w += _nodeW * 2 + _coupleGap;
      } else {
        w += _nodeW;
      }
      groups++;
    }
    return w + max(0, groups - 1) * _hGap;
  }

  String? _spouseIn(String pid, List<String> people) {
    for (final u in (_unionsByParent[pid] ?? [])) {
      for (final sid in u.parentIds) {
        if (sid != pid && people.contains(sid)) return sid;
      }
    }
    return null;
  }

  void _placeRow(List<String> people, double y) {
    final rowW = _calcRowWidth(people);
    double x = _canvasW / 2 - rowW / 2;
    final done = <String>{};
    bool first = true;

    for (final pid in people) {
      if (done.contains(pid)) continue;
      done.add(pid);

      if (!first) x += _hGap;
      first = false;

      final spouse = _spouseIn(pid, people);
      if (spouse != null) {
        done.add(spouse);
        // Homme à gauche si possible
        final p = _personnes[pid];
        final s = _personnes[spouse];
        final leftId = (p?.sexe == 'M' || s?.sexe == 'F') ? pid : spouse;
        final rightId = leftId == pid ? spouse : pid;
        _positions[leftId] = Offset(x + _nodeW / 2, y);
        _positions[rightId] = Offset(x + _nodeW + _coupleGap + _nodeW / 2, y);
        x += _nodeW * 2 + _coupleGap;
      } else {
        _positions[pid] = Offset(x + _nodeW / 2, y);
        x += _nodeW;
      }
    }
  }

  // ── Centrage ────────────────────────────────────

  void _centrer() {
    if (!mounted) return;
    final pos = _positions[widget.racineId] ?? _positions.values.firstOrNull;
    if (pos == null) return;
    final s = MediaQuery.of(context).size;
    _tc.value = Matrix4.translationValues(
        s.width / 2 - pos.dx, s.height / 3 - pos.dy, 0);
  }

  void _reinitialiserVue() {
    _tc.value = Matrix4.identity();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centrer());
  }

  void _onTapDown(TapDownDetails d) {
    final tap = d.localPosition;
    String? best;
    double minDist = double.infinity;
    for (final e in _positions.entries) {
      final dist = (tap - e.value).distance;
      if (dist < 65 && dist < minDist) {
        minDist = dist;
        best = e.key;
      }
    }
    if (best != null && mounted) {
      Navigator.pushNamed(context, '/person/detail', arguments: best);
    }
  }

  Future<void> _changerRacine() async {
    final liste = _personnes.values.toList()
      ..sort((a, b) => a.nomComplet.compareTo(b.nomComplet));

    final id = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Changer de racine'),
        content: SizedBox(
          width: 340,
          height: 460,
          child: ListView.builder(
            itemCount: liste.length,
            itemBuilder: (ctx, i) {
              final p = liste[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: (p.photoPath?.isNotEmpty == true)
                      ? FileImage(File(p.photoPath!))
                      : null,
                  backgroundColor:
                      p.sexe == 'M' ? FamilyConnectTheme.secondaryColor : Colors.pink[300],
                  child: (p.photoPath?.isNotEmpty != true)
                      ? Text(
                          (p.prenoms?.isNotEmpty == true ? p.prenoms![0] : '?').toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                title: Text(p.nomComplet),
                subtitle: p.datesAffichage.isNotEmpty ? Text(p.datesAffichage) : null,
                onTap: () => Navigator.pop(ctx, p.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (id != null && mounted) {
      Navigator.pushReplacementNamed(context, '/tree', arguments: id);
    }
  }

  // ── Build ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: FamilyConnectTheme.primaryGradient),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Arbre${_personnes.isNotEmpty ? '  (${_personnes.length} pers.)' : ''}',
          style: FamilyConnectTheme.h4.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _reinitialiserVue,
            tooltip: 'Centrer',
          ),
          IconButton(
            icon: const Icon(Icons.person_search),
            onPressed: _changerRacine,
            tooltip: 'Changer racine',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _personnes.isEmpty
              ? _buildEmpty()
              : _buildArbre(),
      bottomNavigationBar: _buildLegende(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: FamilyConnectTheme.primaryGradient,
              borderRadius: FamilyConnectTheme.radiusFull,
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Construction de l\'arbre…',
            style: FamilyConnectTheme.bodyMedium
                .copyWith(color: FamilyConnectTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_tree, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Arbre vide',
              style: FamilyConnectTheme.h3.copyWith(color: Colors.grey[400])),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des membres et des unions\npour visualiser l\'arbre',
            style: FamilyConnectTheme.bodyMedium.copyWith(color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildArbre() {
    return InteractiveViewer(
      transformationController: _tc,
      minScale: 0.05,
      maxScale: 5.0,
      boundaryMargin: const EdgeInsets.all(400),
      child: GestureDetector(
        onTapDown: _onTapDown,
        child: SizedBox(
          width: _canvasW,
          height: _canvasH,
          child: CustomPaint(
            painter: _ArbrePainter(
              positions: _positions,
              personnes: _personnes,
              unions: _unions,
              images: _images,
              racineId: widget.racineId,
            ),
            size: Size(_canvasW, _canvasH),
          ),
        ),
      ),
    );
  }

  Widget _buildLegende() {
    return Container(
      height: 40,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendeItem(const Color(0xFF3B82F6), 'Homme'),
          const SizedBox(width: 20),
          _legendeItem(const Color(0xFFEC4899), 'Femme'),
          const SizedBox(width: 20),
          _legendeItem(const Color(0xFF6366F1), 'Racine'),
          const SizedBox(width: 20),
          _legendeItem(const Color(0xFF6B7280), 'Autre'),
        ],
      ),
    );
  }

  Widget _legendeItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: FamilyConnectTheme.caption.copyWith(color: Colors.grey[600])),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// PAINTER
// ──────────────────────────────────────────────

class _ArbrePainter extends CustomPainter {
  final Map<String, Offset> positions;
  final Map<String, Personne> personnes;
  final List<Union> unions;
  final Map<String, ui.Image> images;
  final String racineId;

  _ArbrePainter({
    required this.positions,
    required this.personnes,
    required this.unions,
    required this.images,
    required this.racineId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawConnections(canvas);
    _drawNodes(canvas);
  }

  // ── Fond à points ────────────────────────────

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6366F1).withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  Paint get _linePaint => Paint()
    ..color = const Color(0xFF6366F1).withValues(alpha: 0.5)
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  // ── Connexions ────────────────────────────────

  void _drawConnections(Canvas canvas) {
    for (final u in unions) {
      final parentPositions = u.parentIds
          .map((id) => positions[id])
          .whereType<Offset>()
          .toList();

      Offset anchor;

      if (parentPositions.length >= 2) {
        final sorted = [...parentPositions]..sort((a, b) => a.dx.compareTo(b.dx));
        final left = sorted.first;
        final right = sorted.last;

        canvas.drawLine(
          Offset(left.dx + _nodeW / 2, left.dy),
          Offset(right.dx - _nodeW / 2, right.dy),
          _linePaint,
        );

        final mid = Offset((left.dx + right.dx) / 2, left.dy);
        canvas.drawCircle(
            mid, 6, Paint()..color = const Color(0xFF6366F1)..style = PaintingStyle.fill);
        canvas.drawCircle(
            mid,
            6,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
        anchor = mid;
      } else if (parentPositions.length == 1) {
        anchor = parentPositions.first;
      } else {
        continue;
      }

      final childPositions = u.enfantIds
          .map((eid) => positions[eid])
          .whereType<Offset>()
          .toList();
      if (childPositions.isEmpty) continue;

      final fromY = anchor.dy + _nodeH / 2;
      final barY = childPositions.map((p) => p.dy).reduce(min) - _nodeH / 2 - 16;

      canvas.drawLine(
        Offset(anchor.dx, fromY),
        Offset(anchor.dx, barY),
        _linePaint,
      );

      if (childPositions.length > 1) {
        final minX = childPositions.map((p) => p.dx).reduce(min);
        final maxX = childPositions.map((p) => p.dx).reduce(max);
        canvas.drawLine(Offset(minX, barY), Offset(maxX, barY), _linePaint);
      }

      for (final cp in childPositions) {
        canvas.drawLine(
          Offset(cp.dx, barY),
          Offset(cp.dx, cp.dy - _nodeH / 2),
          _linePaint,
        );
      }
    }
  }

  // ── Nœuds ─────────────────────────────────────

  void _drawNodes(Canvas canvas) {
    // Racine dessinée en dernier (au premier plan)
    final entries = positions.entries.toList()
      ..sort((a, b) => a.key == racineId ? 1 : b.key == racineId ? -1 : 0);
    for (final e in entries) {
      final p = personnes[e.key];
      if (p != null) _drawPersonne(canvas, p, isRacine: e.key == racineId);
    }
  }

  void _drawPersonne(Canvas canvas, Personne p, {required bool isRacine}) {
    final pos = positions[p.id];
    if (pos == null) return;

    final l = pos.dx - _nodeW / 2;
    final t = pos.dy - _nodeH / 2;
    final r = pos.dx + _nodeW / 2;
    final b = pos.dy + _nodeH / 2;
    final rr = RRect.fromLTRBR(l, t, r, b, const Radius.circular(12));

    // Ombre portée
    canvas.drawRRect(
      rr.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );

    // Couleur de fond selon sexe/statut
    final Color fill;
    final Color border;
    if (isRacine) {
      fill = const Color(0xFF6366F1);
      border = const Color(0xFF4F46E5);
    } else if (p.sexe == 'M') {
      fill = const Color(0xFF3B82F6);
      border = const Color(0xFF2563EB);
    } else if (p.sexe == 'F') {
      fill = const Color(0xFFEC4899);
      border = const Color(0xFFDB2777);
    } else {
      fill = const Color(0xFF6B7280);
      border = const Color(0xFF4B5563);
    }

    canvas.drawRRect(rr, Paint()..color = fill..style = PaintingStyle.fill);
    canvas.drawRRect(
        rr,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = isRacine ? 3 : 2);

    // Halo lumineux pour la racine
    if (isRacine) {
      canvas.drawRRect(
        rr.inflate(4),
        Paint()
          ..color = const Color(0xFF6366F1).withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    // ── Avatar (cercle photo, côté gauche) ──────
    final avatarCenter = Offset(l + 8 + _avatarR, pos.dy);
    final avatarRect = Rect.fromCenter(
        center: avatarCenter, width: _avatarR * 2, height: _avatarR * 2);

    final img = images[p.id];
    if (img != null) {
      // Photo clippée en cercle
      canvas.save();
      canvas.clipRRect(
          RRect.fromRectAndRadius(avatarRect, const Radius.circular(_avatarR)));
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        avatarRect,
        Paint()..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
    } else {
      // Fallback : cercle semi-transparent + initiale
      canvas.drawCircle(
        avatarCenter,
        _avatarR,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill,
      );
      final initial =
          (p.prenoms?.isNotEmpty == true ? p.prenoms![0] : '?').toUpperCase();
      _text(
        canvas,
        initial,
        avatarCenter,
        const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
      );
    }

    // Bordure de l'avatar
    canvas.drawCircle(
      avatarCenter,
      _avatarR,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ── Texte (à droite de l'avatar) ────────────
    final textLeft = avatarCenter.dx + _avatarR + 6;
    final textMaxW = r - textLeft - 4;
    final textCx = textLeft + textMaxW / 2;

    final prenom = (p.prenoms?.split(' ').first ?? '').trim();
    final nom = (p.nomUsage?.isNotEmpty == true ? p.nomUsage! : p.nomNaissance ?? '').trim();

    _text(
      canvas,
      prenom,
      Offset(textCx, pos.dy - (nom.isNotEmpty ? 9 : 0)),
      const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1))],
      ),
      maxW: textMaxW,
    );

    if (nom.isNotEmpty) {
      _text(
        canvas,
        nom,
        Offset(textCx, pos.dy + 9),
        const TextStyle(
          color: Colors.white70,
          fontSize: 9.5,
          shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1))],
        ),
        maxW: textMaxW,
      );
    }

    // Année de naissance (coin bas-droit)
    if (p.dateNaissance != null) {
      _text(
        canvas,
        '${p.dateNaissance!.annee}',
        Offset(r - 6, b - 8),
        const TextStyle(color: Colors.white54, fontSize: 8),
        align: TextAlign.right,
        maxW: 40,
      );
    }
  }

  void _text(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style, {
    TextAlign align = TextAlign.center,
    double maxW = _nodeW - 8,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxW);
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_ArbrePainter old) =>
      old.positions != positions ||
      old.unions != unions ||
      old.images != images ||
      old.racineId != racineId;
}
