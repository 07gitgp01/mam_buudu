import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/personne_repository.dart';
import '../database/union_repository.dart';
import '../models/personne.dart';
import '../models/union.dart';
import 'api_service.dart';

class SyncService {
  static const int _batchSize = 100;

  static String _syncKey(String familleId) => 'last_sync_at_$familleId';

  final PersonneRepository _personneRepo = PersonneRepository();
  final UnionRepository _unionRepo = UnionRepository();

  // ── Migration initiale : envoie TOUTES les données locales vers le serveur ──

  Future<SyncResult> migrateLocalData() async {
    final personnes = await _personneRepo.getAll();
    final unions = await _unionRepo.getAll();
    return _push(personnes, unions, operation: 'create');
  }

  // ── Push incrémental (utilise updatedAt pour détecter les changements) ──────

  Future<SyncResult> pushChanges() async {
    final personnes = await _personneRepo.getAll();
    final unions = await _unionRepo.getAll();
    return _push(personnes, unions, operation: 'update');
  }

  // ── Pull : récupère les changements distants et fusionne localement ─────────

  Future<PullResult> pullChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final familleId = prefs.getString('api_famille_id') ?? '';
    final lastSync = familleId.isNotEmpty ? prefs.getString(_syncKey(familleId)) : null;
    final since = lastSync ?? DateTime(2000).toIso8601String();

    final response = await ApiService.get(
      '/api/sync/pull?since=${Uri.encodeQueryComponent(since)}',
    );

    if (response.statusCode != 200) {
      return PullResult(personnesAdded: 0, unionsAdded: 0, error: 'Erreur serveur ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final serverTime = body['serverTime'] as String?;

    int personnesAdded = 0;
    int unionsAdded = 0;

    final serverPersonnes = (body['personnes'] as List? ?? []).cast<Map<String, dynamic>>();
    for (final p in serverPersonnes) {
      try {
        final localMap = _serverPersonneToLocal(p);
        final existing = await _personneRepo.getById(localMap['id'] as String);
        final personne = Personne.fromMap(localMap);
        if (existing == null) {
          await _personneRepo.insert(personne);
        } else {
          await _personneRepo.update(personne);
        }
        personnesAdded++;
      } catch (_) {}
    }

    final serverUnions = (body['unions'] as List? ?? []).cast<Map<String, dynamic>>();
    for (final u in serverUnions) {
      try {
        final localMap = _serverUnionToLocal(u);
        final parentIds = (u['parentIds'] as List? ?? []).cast<String>();
        final enfantIds = (u['enfantIds'] as List? ?? []).cast<String>();
        final union = Union.fromMap(localMap, parentIds: parentIds, enfantIds: enfantIds);

        final existing = await _unionRepo.getById(union.id);
        if (existing == null) {
          await _unionRepo.insert(union);
          for (int i = 0; i < parentIds.length; i++) {
            await _unionRepo.ajouterParticipant(union.id, parentIds[i], ordre: i);
          }
        } else {
          await _unionRepo.update(union);
          await _unionRepo.retirerTousParticipants(union.id);
          for (int i = 0; i < parentIds.length; i++) {
            await _unionRepo.ajouterParticipant(union.id, parentIds[i], ordre: i);
          }
        }
        unionsAdded++;
      } catch (_) {}
    }

    if (serverTime != null && familleId.isNotEmpty) {
      await prefs.setString(_syncKey(familleId), serverTime);
    }

    return PullResult(personnesAdded: personnesAdded, unionsAdded: unionsAdded);
  }

  // ── Push/delete individuels (fire-and-forget après chaque CRUD local) ────────

  Future<void> pushPersonne(Personne p, {String operation = 'create'}) async {
    final token = await ApiService.getToken();
    if (token == null) return;
    try {
      await ApiService.post('/api/sync/push', {'items': [_personneToItem(p, operation)]});
    } catch (_) {}
  }

  Future<void> deletePersonne(String id) async {
    final token = await ApiService.getToken();
    if (token == null) return;
    try {
      await ApiService.post('/api/sync/push', {
        'items': [{'entityType': 'personne', 'entityId': id, 'operation': 'delete'}],
      });
    } catch (_) {}
  }

  Future<void> pushUnion(Union u, {String operation = 'create'}) async {
    final token = await ApiService.getToken();
    if (token == null) return;
    try {
      await ApiService.post('/api/sync/push', {'items': [_unionToItem(u, operation)]});
    } catch (_) {}
  }

  Future<void> deleteUnion(String id) async {
    final token = await ApiService.getToken();
    if (token == null) return;
    try {
      await ApiService.post('/api/sync/push', {
        'items': [{'entityType': 'union', 'entityId': id, 'operation': 'delete'}],
      });
    } catch (_) {}
  }

  // ── Helpers de sérialisation ────────────────────────────────────────────────

  Map<String, dynamic> _personneToItem(Personne p, String operation) => {
    'entityType': 'personne',
    'entityId': p.id,
    'operation': operation,
    'payload': {
      'nomNaissance': p.nomNaissance,
      'nomUsage': p.nomUsage,
      'prenoms': p.prenoms,
      'sexe': p.sexe,
      'dateNaissance': p.dateNaissance?.toString(),
      'lieuNaissance': p.lieuNaissance,
      'dateDeces': p.dateDeces?.toString(),
      'lieuDeces': p.lieuDeces,
      'biographie': p.biographie,
      'notes': p.notes,
      'photoUrl': null,
    },
  };

  Map<String, dynamic> _unionToItem(Union u, String operation) => {
    'entityType': 'union',
    'entityId': u.id,
    'operation': operation,
    'payload': {
      'type': u.type,
      'dateDebut': u.dateDebut?.toStorage(),
      'lieuDebut': u.lieuDebut,
      'dateFin': u.dateFin?.toStorage(),
      'lieuFin': u.lieuFin,
      'notes': u.notes,
      'parentIds': u.parentIds,
      'enfantIds': u.enfantIds,
    },
  };

  // ── Envoi groupé avec batching ──────────────────────────────────────────────

  Future<SyncResult> _push(
    List<Personne> personnes,
    List<Union> unions, {
    required String operation,
  }) async {
    final items = <Map<String, dynamic>>[];
    for (final p in personnes) { items.add(_personneToItem(p, operation)); }
    for (final u in unions) { items.add(_unionToItem(u, operation)); }

    int synced = 0;
    int failed = 0;
    String? lastError;

    for (int i = 0; i < items.length; i += _batchSize) {
      final end = (i + _batchSize).clamp(0, items.length);
      final batch = items.sublist(i, end);
      try {
        final response = await ApiService.post('/api/sync/push', {'items': batch});
        if (response.statusCode == 200) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          final batchSynced = body['synced'] as int? ?? 0;
          synced += batchSynced;
          failed += batch.length - batchSynced;
          // Collecte les messages d'erreur des items individuels
          final results = body['results'] as List? ?? [];
          for (final r in results) {
            if (r['status'] == 'error') {
              lastError = '${r['entityId']}: ${r['message']}';
            }
          }
        } else {
          // Erreur HTTP (ex: 400 validation Zod)
          final err = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
          lastError = 'HTTP ${response.statusCode}: ${err['error'] ?? response.body}';
          failed += batch.length;
        }
      } catch (e) {
        lastError = e.toString();
        failed += batch.length;
      }
    }

    // Mémorise la date de dernière synchronisation (par famille)
    final prefs = await SharedPreferences.getInstance();
    final familleId = prefs.getString('api_famille_id') ?? '';
    if (familleId.isNotEmpty) {
      await prefs.setString(_syncKey(familleId), DateTime.now().toIso8601String());
    }

    return SyncResult(synced: synced, failed: failed, total: items.length, lastError: lastError);
  }

  // ── Conversion serveur (camelCase) → local SQLite (snake_case) ─────────────

  Map<String, dynamic> _serverPersonneToLocal(Map<String, dynamic> p) {
    return {
      'id': p['id'],
      'nom_naissance': p['nomNaissance'],
      'nom_usage': p['nomUsage'],
      'prenoms': p['prenoms'],
      'sexe': p['sexe'],
      'date_naissance': p['dateNaissance'],
      'lieu_naissance': p['lieuNaissance'],
      'date_deces': p['dateDeces'],
      'lieu_deces': p['lieuDeces'],
      'biographie': p['biographie'],
      'notes': p['notes'],
      'photo_path': null,
      'created_at': p['createdAt'],
      'updated_at': p['updatedAt'],
    };
  }

  Map<String, dynamic> _serverUnionToLocal(Map<String, dynamic> u) {
    return {
      'id': u['id'],
      'type': u['type'],
      'date_debut': u['dateDebut'],
      'lieu_debut': u['lieuDebut'],
      'date_fin': u['dateFin'],
      'lieu_fin': u['lieuFin'],
      'notes': u['notes'],
    };
  }
}

// ── Résultats ───────────────────────────────────────────────────────────────

class SyncResult {
  final int synced;
  final int failed;
  final int total;
  final String? lastError;

  const SyncResult({required this.synced, required this.failed, required this.total, this.lastError});

  bool get isSuccess => failed == 0 && total > 0;
  String get summary {
    if (total == 0) return 'Aucune donnee a synchroniser';
    final base = '$synced/$total elements envoyes';
    if (failed > 0 && lastError != null) return '$base ($failed echecs: $lastError)';
    if (failed > 0) return '$base ($failed echecs)';
    return base;
  }
}

class PullResult {
  final int personnesAdded;
  final int unionsAdded;
  final String? error;

  const PullResult({required this.personnesAdded, required this.unionsAdded, this.error});

  bool get hasError => error != null;
  String get summary => error ?? '$personnesAdded personnes et $unionsAdded unions récupérées';
}
