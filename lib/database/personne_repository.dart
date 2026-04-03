import '../models/personne.dart';
import '../models/date_partielle.dart';
import '../database/database_helper.dart';

class PersonneRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String> insert(Personne personne) async {
    final personneMap = personne.toMap();
    return await _dbHelper.insert('personnes', personneMap);
  }

  Future<void> update(Personne personne) async {
    final personneMap = personne.toMap();
    await _dbHelper.update('personnes', personneMap, personne.id);
  }

  Future<void> delete(String id) async {
    await _dbHelper.delete('personnes', id);
  }

  Future<Personne?> getById(String id) async {
    final map = await _dbHelper.getById('personnes', id);
    return map != null ? Personne.fromMap(map) : null;
  }

  Future<List<Personne>> getAll({String? searchQuery}) async {
    List<Map<String, dynamic>> maps;
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      maps = await _dbHelper.search('personnes', 'nom_naissance', searchQuery);
    } else {
      maps = await _dbHelper.getAll('personnes');
    }
    
    return maps.map((map) => Personne.fromMap(map)).toList();
  }

  Future<List<Personne>> getByNom(String nom) async {
    final maps = await _dbHelper.search('personnes', 'nom_naissance', nom);
    return maps.map((map) => Personne.fromMap(map)).toList();
  }

  Future<List<Personne>> getByPrenoms(String prenoms) async {
    final maps = await _dbHelper.search('personnes', 'prenoms', prenoms);
    return maps.map((map) => Personne.fromMap(map)).toList();
  }

  Future<List<Personne>> searchInAllFields(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT * FROM personnes 
      WHERE nom_naissance LIKE ? 
         OR nom_usage LIKE ? 
         OR prenoms LIKE ? 
         OR lieu_naissance LIKE ? 
         OR lieu_deces LIKE ? 
         OR biographie LIKE ?
      ORDER BY nom_naissance, prenoms
    ''', [
      '%$query%', '%$query%', '%$query%', '%$query%', '%$query%', '%$query%'
    ]);
    
    return maps.map((map) => Personne.fromMap(map)).toList();
  }

  Future<List<Personne>> getBySexe(String sexe) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'personnes',
      where: 'sexe = ?',
      whereArgs: [sexe],
      orderBy: 'nom_naissance, prenoms',
    );
    
    return maps.map((map) => Personne.fromMap(map)).toList();
  }

  Future<List<Personne>> getBornBetween(DatePartielle debut, DatePartielle fin) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'personnes',
      where: 'date_naissance >= ? AND date_naissance <= ?',
      whereArgs: [debut.toStorage(), fin.toStorage()],
      orderBy: 'date_naissance',
    );
    
    return maps.map((map) => Personne.fromMap(map)).toList();
  }

  Future<List<Personne>> getBornIn(String lieu) async {
    final maps = await _dbHelper.search('personnes', 'lieu_naissance', lieu);
    return maps.map((map) => Personne.fromMap(map)).toList();
  }

  Future<List<Personne>> getDiedIn(String lieu) async {
    final maps = await _dbHelper.search('personnes', 'lieu_deces', lieu);
    return maps.map((map) => Personne.fromMap(map)).toList();
  }

  Future<List<Personne>> getWithPhoto() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'personnes',
      where: 'photo_path IS NOT NULL AND photo_path != ""',
      orderBy: 'nom_naissance, prenoms',
    );
    
    return maps.map((map) => Personne.fromMap(map)).toList();
  }

  Future<int> getCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM personnes');
    return result.first['count'] as int;
  }

  Future<List<Personne>> getRecentlyAdded({int limit = 10}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'personnes',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    
    return maps.map((map) => Personne.fromMap(map)).toList();
  }

  Future<List<Personne>> getRecentlyUpdated({int limit = 10}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'personnes',
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    
    return maps.map((map) => Personne.fromMap(map)).toList();
  }

  Future<List<Personne>> getConjoints(String personneId) async {
    final db = await _dbHelper.database;
    
    // Récupérer toutes les unions où la personne est participant
    final unionMaps = await db.rawQuery('''
      SELECT DISTINCT u.* FROM unions u
      INNER JOIN union_participants up ON u.id = up.union_id
      WHERE up.personne_id = ?
    ''', [personneId]);
    
    List<Personne> conjoints = [];
    Set<String> conjointIds = {};
    
    // Pour chaque union, récupérer les autres participants
    for (final unionMap in unionMaps) {
      final unionId = unionMap['id'] as String;
      
      final participantMaps = await db.query(
        'union_participants',
        where: 'union_id = ? AND personne_id != ?',
        whereArgs: [unionId, personneId],
      );
      
      for (final participantMap in participantMaps) {
        final participantId = participantMap['personne_id'] as String;
        
        // Éviter les doublons
        if (!conjointIds.contains(participantId)) {
          conjointIds.add(participantId);
          
          final conjointMap = await db.query(
            'personnes',
            where: 'id = ?',
            whereArgs: [participantId],
            limit: 1,
          );
          
          if (conjointMap.isNotEmpty) {
            conjoints.add(Personne.fromMap(conjointMap.first));
          }
        }
      }
    }
    
    return conjoints;
  }
}
