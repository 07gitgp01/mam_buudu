import 'package:uuid/uuid.dart';
import '../models/personne.dart';
import 'database_helper.dart';

class FiliationRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  Future<String> ajouterEnfantAUnion(String enfantId, String unionId, {
    String typeLien = 'biologique',
    int ordre = 0
  }) async {
    final db = await _dbHelper.database;
    
    // Vérifier si la filiation n'existe pas déjà
    final existing = await db.query(
      'filiations',
      where: 'enfant_id = ? AND union_id = ?',
      whereArgs: [enfantId, unionId],
    );
    
    if (existing.isNotEmpty) {
      return existing.first['id'] as String;
    }
    
    final id = _uuid.v4();
    await db.insert('filiations', {
      'id': id,
      'enfant_id': enfantId,
      'union_id': unionId,
      'type_lien': typeLien,
      'ordre_naissance': ordre,
    });
    
    return id;
  }

  Future<void> retirerEnfantDeUnion(String enfantId, String unionId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'filiations',
      where: 'enfant_id = ? AND union_id = ?',
      whereArgs: [enfantId, unionId],
    );
  }

  Future<List<Personne>> getEnfantsByUnionId(String unionId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT p.* FROM personnes p
      INNER JOIN filiations f ON p.id = f.enfant_id
      WHERE f.union_id = ?
      ORDER BY f.ordre_naissance ASC, p.date_naissance ASC
    ''', [unionId]);
    
    return maps.map((map) => Personne.fromMap(map)).toList();
  }

  Future<List<Personne>> getParentsByEnfantId(String enfantId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT DISTINCT p.* FROM personnes p
      INNER JOIN union_participants up ON p.id = up.personne_id
      INNER JOIN filiations f ON up.union_id = f.union_id
      WHERE f.enfant_id = ?
      ORDER BY p.nom_naissance ASC, p.prenoms ASC
    ''', [enfantId]);
    
    return maps.map((map) => Personne.fromMap(map)).toList();
  }

  Future<List<String>> getUnionIdsByEnfantId(String enfantId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'filiations',
      columns: ['union_id'],
      where: 'enfant_id = ?',
      whereArgs: [enfantId],
    );
    
    return maps.map((map) => map['union_id'] as String).toList();
  }

  Future<List<Personne>> getFreresSoeurs(String personneId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT DISTINCT p.* FROM personnes p
      INNER JOIN filiations f1 ON p.id = f1.enfant_id
      INNER JOIN filiations f2 ON f1.union_id = f2.union_id
      WHERE f2.enfant_id = ? AND p.id != ?
      ORDER BY f1.ordre_naissance ASC, p.date_naissance ASC
    ''', [personneId, personneId]);
    
    return maps.map((map) => Personne.fromMap(map)).toList();
  }

  Future<List<Personne>> getDemiFreresSoeurs(String personneId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT DISTINCT p.* FROM personnes p
      INNER JOIN filiations f1 ON p.id = f1.enfant_id
      INNER JOIN filiations f2 ON f1.union_id = f2.union_id
      INNER JOIN union_participants up1 ON f1.union_id = up1.union_id
      INNER JOIN union_participants up2 ON f1.union_id = up2.union_id
      INNER JOIN filiations f3 ON up2.personne_id IN (
        SELECT DISTINCT up3.personne_id 
        FROM union_participants up3 
        INNER JOIN filiations f4 ON up3.union_id = f4.union_id 
        WHERE f4.enfant_id = ?
      )
      WHERE f2.enfant_id = ? 
        AND p.id != ?
        AND f1.union_id NOT IN (
          SELECT f5.union_id 
          FROM filiations f5 
          WHERE f5.enfant_id = ?
        )
      ORDER BY f1.ordre_naissance ASC, p.date_naissance ASC
    ''', [personneId, personneId, personneId, personneId]);
    
    return maps.map((map) => Personne.fromMap(map)).toList();
  }

  Future<List<Personne>> getAscendants(String personneId, {int generation = 1}) async {
    if (generation > 10) return []; // Limiter pour éviter les boucles infinies
    
    final parents = await getParentsByEnfantId(personneId);
    List<Personne> ascendants = List.from(parents);
    
    for (final parent in parents) {
      ascendants.addAll(await getAscendants(parent.id, generation: generation + 1));
    }
    
    return ascendants;
  }

  Future<List<Personne>> getDescendants(String personneId, {int generation = 1}) async {
    if (generation > 10) return []; // Limiter pour éviter les boucles infinies
    
    final unions = await _getUnionsByPersonneId(personneId);
    List<Personne> descendants = [];
    
    for (final union in unions) {
      final enfants = await getEnfantsByUnionId(union['id'] as String);
      descendants.addAll(enfants);
      
      for (final enfant in enfants) {
        descendants.addAll(await getDescendants(enfant.id, generation: generation + 1));
      }
    }
    
    return descendants;
  }

  Future<List<Map<String, dynamic>>> _getUnionsByPersonneId(String personneId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'unions',
      where: 'id IN (SELECT union_id FROM union_participants WHERE personne_id = ?)',
      whereArgs: [personneId],
    );
  }

  Future<void> updateOrdreNaissance(String enfantId, String unionId, int nouvelOrdre) async {
    final db = await _dbHelper.database;
    await db.update(
      'filiations',
      {'ordre_naissance': nouvelOrdre},
      where: 'enfant_id = ? AND union_id = ?',
      whereArgs: [enfantId, unionId],
    );
  }

  Future<Map<String, dynamic>?> getFiliation(String enfantId, String unionId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'filiations',
      where: 'enfant_id = ? AND union_id = ?',
      whereArgs: [enfantId, unionId],
      limit: 1,
    );
    
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllFiliations() async {
    final db = await _dbHelper.database;
    return await db.query('filiations', orderBy: 'union_id, ordre_naissance');
  }

  Future<List<Map<String, dynamic>>> getFiliationsByType(String typeLien) async {
    final db = await _dbHelper.database;
    return await db.query(
      'filiations',
      where: 'type_lien = ?',
      whereArgs: [typeLien],
      orderBy: 'union_id, ordre_naissance',
    );
  }

  Future<int> getNombreEnfantsByUnionId(String unionId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM filiations WHERE union_id = ?',
      [unionId],
    );
    return result.first['count'] as int;
  }

  Future<bool> estEnfantDe(String enfantId, String personneId) async {
    final parents = await getParentsByEnfantId(enfantId);
    return parents.any((parent) => parent.id == personneId);
  }

  Future<bool> estParentDe(String personneId, String enfantId) async {
    return await estEnfantDe(enfantId, personneId);
  }
}
