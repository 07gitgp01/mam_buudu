import '../models/union.dart';
import '../models/personne.dart';
import 'database_helper.dart';

class UnionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String> insert(Union union) async {
    print('📝 UnionRepository.insert - Union: ${union.id}, Type: ${union.type}');
    final unionMap = union.toMap();
    print('📝 Union map: $unionMap');
    final id = await _dbHelper.insert('unions', unionMap);
    print('✅ Union insérée avec ID: $id');
    return id;
  }

  Future<void> update(Union union) async {
    final unionMap = union.toMap();
    await _dbHelper.update('unions', unionMap, union.id);
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    
    // Supprimer d'abord les participants et les filiations associées
    await db.delete('union_participants', where: 'union_id = ?', whereArgs: [id]);
    await db.delete('filiations', where: 'union_id = ?', whereArgs: [id]);
    
    // Puis supprimer l'union
    await _dbHelper.delete('unions', id);
  }

  Future<Union?> getById(String id) async {
    final map = await _dbHelper.getById('unions', id);
    if (map == null) return null;
    
    // Récupérer les participants
    final parentIds = await getParticipantIds(id);
    
    // Récupérer les enfants
    final enfantIds = await getEnfantIds(id);
    
    return Union.fromMap(map, parentIds: parentIds, enfantIds: enfantIds);
  }

  Future<List<Union>> getAll() async {
    final maps = await _dbHelper.getAll('unions');
    List<Union> unions = [];
    
    for (final map in maps) {
      final unionId = map['id'] as String;
      final parentIds = await getParticipantIds(unionId);
      final enfantIds = await getEnfantIds(unionId);
      
      unions.add(Union.fromMap(map, parentIds: parentIds, enfantIds: enfantIds));
    }
    
    return unions;
  }

  Future<List<Union>> getByPersonneId(String personneId) async {
    print('=== DEBUG getByPersonneId ===');
    print('Recherche des unions pour personne: $personneId');
    
    final db = await _dbHelper.database;
    
    // D'abord vérifier si la personne existe bien dans union_participants
    final participantCheck = await db.query(
      'union_participants',
      where: 'personne_id = ?',
      whereArgs: [personneId],
    );
    print('Participant check: ${participantCheck.length} entrées trouvées');
    for (var entry in participantCheck) {
      print('  - Union: ${entry['union_id']}, Personne: ${entry['personne_id']}');
    }
    
    // Ensuite vérifier les unions
    final unionCheck = await db.query('unions');
    print('Union check: ${unionCheck.length} unions totales');
    for (var entry in unionCheck) {
      print('  - Union: ${entry['id']}, Type: ${entry['type']}');
    }
    
    final maps = await db.rawQuery('''
      SELECT u.* FROM unions u
      INNER JOIN union_participants up ON u.id = up.union_id
      WHERE up.personne_id = ?
      ORDER BY u.date_debut DESC
    ''', [personneId]);
    
    print('Requête JOIN result: ${maps.length} maps');
    for (var map in maps) {
      print('  - Map: ${map}');
    }
    
    print('=== FIN DEBUG getByPersonneId ===');
    
    List<Union> unions = [];
    
    for (final map in maps) {
      final unionId = map['id'] as String;
      print('  Processing union: $unionId');
      final parentIds = await getParticipantIds(unionId);
      final enfantIds = await getEnfantIds(unionId);
      
      final union = Union.fromMap(map, parentIds: parentIds, enfantIds: enfantIds);
      unions.add(union);
      print('  Union: ${union.type}, Participants: ${union.parentIds.length}, Enfants: ${union.enfantIds.length}');
    }
    
    print('Returning ${unions.length} unions for person $personneId');
    return unions;
  }

  Future<void> ajouterParticipant(String unionId, String personneId, {
    String role = 'conjoint',
    int ordre = 0
  }) async {
    print('👥 UnionRepository.ajouterParticipant - Union: $unionId, Personne: $personneId, Role: $role, Ordre: $ordre');
    final db = await _dbHelper.database;
    
    // Vérifier si la personne n'est pas déjà participant
    final existing = await db.query(
      'union_participants',
      where: 'union_id = ? AND personne_id = ?',
      whereArgs: [unionId, personneId],
    );
    
    if (existing.isEmpty) {
      print('✅ Ajout du participant');
      await db.insert('union_participants', {
        'union_id': unionId,
        'personne_id': personneId,
        'role': role,
        'ordre': ordre,
      });
      print('✅ Participant ajouté avec succès');
    } else {
      print('⚠️ Participant déjà existant, skip');
    }
  }

  Future<void> retirerParticipant(String unionId, String personneId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'union_participants',
      where: 'union_id = ? AND personne_id = ?',
      whereArgs: [unionId, personneId],
    );
  }

  Future<void> retirerTousParticipants(String unionId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'union_participants',
      where: 'union_id = ?',
      whereArgs: [unionId],
    );
  }

  Future<void> ajouterFiliation(String unionId, String enfantId, {int ordre = 0}) async {
    final db = await _dbHelper.database;
    final existing = await db.query(
      'filiations',
      where: 'union_id = ? AND enfant_id = ?',
      whereArgs: [unionId, enfantId],
    );
    if (existing.isEmpty) {
      await db.insert('filiations', {
        'union_id': unionId,
        'enfant_id': enfantId,
        'ordre_naissance': ordre,
      });
    }
  }

  Future<void> retirerToutesFiliations(String unionId) async {
    final db = await _dbHelper.database;
    await db.delete('filiations', where: 'union_id = ?', whereArgs: [unionId]);
  }

  Future<List<Personne>> getParticipants(String unionId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT p.* FROM personnes p
      INNER JOIN union_participants up ON p.id = up.personne_id
      WHERE up.union_id = ?
      ORDER BY up.ordre ASC, p.nom_naissance ASC, p.prenoms ASC
    ''', [unionId]);
    
    return maps.map((map) => Personne.fromMap(map)).toList();
  }

  Future<List<String>> getParticipantIds(String unionId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'union_participants',
      columns: ['personne_id'],
      where: 'union_id = ?',
      whereArgs: [unionId],
      orderBy: 'ordre ASC',
    );
    
    return maps.map((map) => map['personne_id'] as String).toList();
  }

  Future<List<String>> getEnfantIds(String unionId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'filiations',
      columns: ['enfant_id'],
      where: 'union_id = ?',
      whereArgs: [unionId],
      orderBy: 'ordre_naissance ASC',
    );
    
    return maps.map((map) => map['enfant_id'] as String).toList();
  }

  Future<List<Union>> getByType(String type) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'unions',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date_debut DESC',
    );
    
    List<Union> unions = [];
    
    for (final map in maps) {
      final unionId = map['id'] as String;
      final parentIds = await getParticipantIds(unionId);
      final enfantIds = await getEnfantIds(unionId);
      
      unions.add(Union.fromMap(map, parentIds: parentIds, enfantIds: enfantIds));
    }
    
    return unions;
  }

  Future<List<Union>> getUnionsEnCours() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'unions',
      where: 'date_fin IS NULL OR date_fin = ""',
      orderBy: 'date_debut DESC',
    );
    
    List<Union> unions = [];
    
    for (final map in maps) {
      final unionId = map['id'] as String;
      final parentIds = await getParticipantIds(unionId);
      final enfantIds = await getEnfantIds(unionId);
      
      unions.add(Union.fromMap(map, parentIds: parentIds, enfantIds: enfantIds));
    }
    
    return unions;
  }

  Future<List<Union>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT DISTINCT u.* FROM unions u
      LEFT JOIN union_participants up ON u.id = up.union_id
      LEFT JOIN personnes p ON up.personne_id = p.id
      WHERE u.type LIKE ? 
         OR u.lieu_debut LIKE ? 
         OR u.lieu_fin LIKE ? 
         OR u.notes LIKE ?
         OR p.nom_naissance LIKE ? 
         OR p.prenoms LIKE ?
      ORDER BY u.date_debut DESC
    ''', [
      '%$query%', '%$query%', '%$query%', '%$query%', '%$query%', '%$query%'
    ]);
    
    List<Union> unions = [];
    
    for (final map in maps) {
      final unionId = map['id'] as String;
      final parentIds = await getParticipantIds(unionId);
      final enfantIds = await getEnfantIds(unionId);
      
      unions.add(Union.fromMap(map, parentIds: parentIds, enfantIds: enfantIds));
    }
    
    return unions;
  }

  Future<int> getCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM unions');
    return result.first['count'] as int;
  }
}
