import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static DatabaseHelper get instance => _instance;

  Future<Database> get database async {
    print('=== DATABASE HELPER GET DATABASE ===');
    print('_database is null: ${_database == null}');
    if (_database != null) {
      print('Returning existing database instance');
      return _database!;
    }
    print('Initializing new database...');
    _database = await _initDatabase();
    print('Database initialized successfully');
    return _database!;
  }

  Future<Database> _initDatabase() async {
    print('=== INIT DATABASE ===');
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'family_tree.db');
      print('Database path: $path');
      
      final db = await openDatabase(
        path,
        version: 3, // Version incrémentée pour inclure les utilisateurs
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      print('Database opened successfully');
      return db;
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Création de la table utilisateurs
    await db.execute('''
      CREATE TABLE utilisateurs (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        mot_de_passe TEXT NOT NULL,
        nom TEXT,
        prenom TEXT,
        role TEXT DEFAULT 'member',
        est_connecte INTEGER DEFAULT 0,
        derniere_connexion INTEGER,
        created_at INTEGER NOT NULL,
        question_secrete TEXT,
        reponse_secrete TEXT
      )
    ''');

    // Création de la table personnes_utilisateurs
    await db.execute('''
      CREATE TABLE personnes_utilisateurs (
        personne_id TEXT,
        utilisateur_id TEXT,
        permission TEXT DEFAULT 'read',  -- 'read', 'write', 'admin'
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (personne_id, utilisateur_id),
        FOREIGN KEY (personne_id) REFERENCES personnes (id),
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs (id)
      )
    ''');

    // Création de la table personnes
    await db.execute('''
      CREATE TABLE personnes (
        id TEXT PRIMARY KEY,
        nom_naissance TEXT,
        nom_usage TEXT,
        prenoms TEXT,
        sexe TEXT,
        date_naissance TEXT,
        lieu_naissance TEXT,
        date_deces TEXT,
        lieu_deces TEXT,
        biographie TEXT,
        notes TEXT,
        photo_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Création de la table unions
    await db.execute('''
      CREATE TABLE unions (
        id TEXT PRIMARY KEY,
        type TEXT,
        date_debut TEXT,
        lieu_debut TEXT,
        date_fin TEXT,
        lieu_fin TEXT,
        notes TEXT,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''');

    // Création de la table union_participants
    await db.execute('''
      CREATE TABLE union_participants (
        union_id TEXT,
        personne_id TEXT,
        role TEXT,
        ordre INTEGER,
        created_at INTEGER,
        updated_at INTEGER,
        PRIMARY KEY (union_id, personne_id),
        FOREIGN KEY (union_id) REFERENCES unions (id),
        FOREIGN KEY (personne_id) REFERENCES personnes (id)
      )
    ''');

    // Création de la table filiations
    await db.execute('''
      CREATE TABLE filiations (
        id TEXT PRIMARY KEY,
        enfant_id TEXT,
        union_id TEXT,
        type_lien TEXT,
        ordre_naissance INTEGER,
        created_at INTEGER,
        updated_at INTEGER,
        FOREIGN KEY (enfant_id) REFERENCES personnes (id),
        FOREIGN KEY (union_id) REFERENCES unions (id)
      )
    ''');

    // Création de la table notifications_locales
    await db.execute('''
      CREATE TABLE notifications_locales (
        id TEXT PRIMARY KEY,
        utilisateur_id TEXT,
        type TEXT,  -- 'anniversaire', 'evenement', 'rappel'
        titre TEXT,
        message TEXT,
        date_notification INTEGER,  -- timestamp
        est_lue BOOLEAN DEFAULT FALSE,
        est_envoyee BOOLEAN DEFAULT FALSE,
        date_creation INTEGER,
        personne_id TEXT,
        created_at INTEGER,
        updated_at INTEGER,
        FOREIGN KEY (personne_id) REFERENCES personnes (id)
      )
    ''');

    // Création des autres tables
    await db.execute('''
      CREATE TABLE medias (
        id TEXT PRIMARY KEY,
        personne_id TEXT,
        union_id TEXT,
        file_path TEXT,
        description TEXT,
        date_prise TEXT,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE sources (
        id TEXT PRIMARY KEY,
        titre TEXT,
        reference TEXT,
        confidence INTEGER,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE metadonnees (
        id TEXT PRIMARY KEY,
        cle TEXT,
        valeur TEXT,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE preuves (
        id TEXT PRIMARY KEY,
        source_id TEXT,
        personne_id TEXT,
        union_id TEXT,
        fait_type TEXT,
        valeur TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Ajouter la table utilisateurs
      await db.execute('''
        CREATE TABLE IF NOT EXISTS utilisateurs (
          id TEXT PRIMARY KEY,
          email TEXT UNIQUE NOT NULL,
          mot_de_passe TEXT NOT NULL,
          nom TEXT,
          prenom TEXT,
          role TEXT DEFAULT 'member',
          est_connecte INTEGER DEFAULT 0,
          derniere_connexion INTEGER,
          created_at INTEGER NOT NULL,
          question_secrete TEXT,
          reponse_secrete TEXT
        )
      ''');

      // Ajouter la table personnes_utilisateurs
      await db.execute('''
        CREATE TABLE IF NOT EXISTS personnes_utilisateurs (
          personne_id TEXT,
          utilisateur_id TEXT,
          permission TEXT DEFAULT 'read',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          PRIMARY KEY (personne_id, utilisateur_id),
          FOREIGN KEY (personne_id) REFERENCES personnes (id),
          FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs (id)
        )
      ''');
    }

    if (oldVersion < 2) {
      // Ajouter la colonne notes à la table personnes
      await db.execute('ALTER TABLE personnes ADD COLUMN notes TEXT');
    }
  }

  // Méthodes CRUD génériques
  Future<String> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    
    // Si les données contiennent un ID, l'utiliser
    if (data.containsKey('id') && data['id'] != null) {
      final providedId = data['id'].toString();
      await db.insert(
        table, 
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return providedId;
    }
    
    // Sinon, utiliser l'ID auto-incrémenté
    final id = await db.insert(table, data);
    return id.toString();
  }

  Future<int> update(String table, Map<String, dynamic> data, String id) async {
    final db = await database;
    return await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, String id) async {
    final db = await database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getById(String table, String id) async {
    final db = await database;
    final result = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> search(String table, String query) async {
    final db = await database;
    return await db.rawQuery('SELECT * FROM $table WHERE $query');
  }

  Future<List<Map<String, dynamic>>> getAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  // Méthode de recherche avancée
  Future<List<Map<String, dynamic>>> searchInTable(
    String table, 
    String searchColumn, 
    String searchTerm
  ) async {
    final db = await database;
    return await db.query(
      table,
      where: '$searchColumn LIKE ?',
      whereArgs: ['%$searchTerm%'],
    );
  }

  // Fermeture de la base de données
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
