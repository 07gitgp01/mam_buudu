import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/personne.dart';
import '../models/union.dart';
import '../models/utilisateur.dart';
import '../models/date_partielle.dart';

/// Service Firestore pour la gestion des données de Mam Buudu
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collections Firestore
  static const String _usersCollection = 'utilisateurs';
  static const String _personsCollection = 'personnes';
  static const String _unionsCollection = 'unions';
  static const String _filiationsCollection = 'filiations';
  static const String _familiesCollection = 'familles';
  static const String _photosCollection = 'photos';
  static const String _documentsCollection = 'documents';

  /// Récupérer l'ID de l'utilisateur actuel
  String? get currentUserId => _auth.currentUser?.uid;

  /// Vérifier si l'utilisateur est connecté
  bool get isUserConnected => _auth.currentUser != null;

  // ============================================
  // GESTION DES UTILISATEURS
  // ============================================

  /// Créer ou mettre à jour un utilisateur
  Future<void> saveUser(Utilisateur utilisateur) async {
    try {
      await _db.collection(_usersCollection).doc(utilisateur.id).set({
        'id': utilisateur.id,
        'email': utilisateur.email,
        'nom_complet': utilisateur.nomComplet,
        'photo_url': utilisateur.photoUrl,
        'date_creation': Timestamp.fromDate(utilisateur.dateCreation),
        'derniere_connexion': Timestamp.fromDate(utilisateur.dernierConnexion),
        'est_verifie': utilisateur.estVerifie,
        'famille_id': utilisateur.familleId,
        'role': utilisateur.role,
        'preferences': utilisateur.preferences,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde de l\'utilisateur: $e');
    }
  }

  /// Récupérer un utilisateur par son ID
  Future<Utilisateur?> getUserById(String userId) async {
    try {
      final doc = await _db.collection(_usersCollection).doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return Utilisateur(
        id: data['id'],
        email: data['email'],
        nomComplet: data['nom_complet'],
        photoUrl: data['photo_url'],
        dateCreation: (data['date_creation'] as Timestamp).toDate(),
        dernierConnexion: (data['derniere_connexion'] as Timestamp).toDate(),
        estVerifie: data['est_verifie'] ?? false,
        familleId: data['famille_id'],
        role: data['role'] ?? 'membre',
        preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'utilisateur: $e');
    }
  }

  // ============================================
  // GESTION DES PERSONNES
  // ============================================

  /// Ajouter une personne
  Future<String> addPersonne(Personne personne, {String? familleId}) async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      final personneData = {
        'id': personne.id,
        'nom_naissance': personne.nomNaissance,
        'nom_usage': personne.nomUsage,
        'prenoms': personne.prenoms,
        'sexe': personne.sexe,
        'date_naissance': personne.dateNaissance?.toString(),
        'lieu_naissance': personne.lieuNaissance,
        'date_deces': personne.dateDeces?.toString(),
        'lieu_deces': personne.lieuDeces,
        'biographie': personne.biographie,
        'notes': personne.notes,
        'photo_path': personne.photoPath,
        'created_at': Timestamp.fromDate(personne.createdAt),
        'updated_at': Timestamp.fromDate(personne.updatedAt),
        'created_by': currentUserId,
        'famille_id': familleId ?? 'default',
      };

      await _db.collection(_personsCollection).doc(personne.id).set(personneData);
      return personne.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la personne: $e');
    }
  }

  /// Récupérer toutes les personnes d'une famille
  Future<List<Personne>> getAllPersonnes({String? familleId}) async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      Query query = _db.collection(_personsCollection);
      
      if (familleId != null) {
        query = query.where('famille_id', isEqualTo: familleId);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Personne(
          id: data['id'],
          nomNaissance: data['nom_naissance'],
          nomUsage: data['nom_usage'],
          prenoms: data['prenoms'],
          sexe: data['sexe'],
          dateNaissance: data['date_naissance'] != null 
              ? DatePartielle.fromString(data['date_naissance'])
              : null,
          lieuNaissance: data['lieu_naissance'],
          dateDeces: data['date_deces'] != null
              ? DatePartielle.fromString(data['date_deces'])
              : null,
          lieuDeces: data['lieu_deces'],
          biographie: data['biographie'],
          notes: data['notes'],
          photoPath: data['photo_path'],
          createdAt: (data['created_at'] as Timestamp).toDate(),
          updatedAt: (data['updated_at'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des personnes: $e');
    }
  }

  /// Mettre à jour une personne
  Future<void> updatePersonne(Personne personne) async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      final personneData = {
        'nom_naissance': personne.nomNaissance,
        'nom_usage': personne.nomUsage,
        'prenoms': personne.prenoms,
        'sexe': personne.sexe,
        'date_naissance': personne.dateNaissance?.toString(),
        'lieu_naissance': personne.lieuNaissance,
        'date_deces': personne.dateDeces?.toString(),
        'lieu_deces': personne.lieuDeces,
        'biographie': personne.biographie,
        'notes': personne.notes,
        'photo_path': personne.photoPath,
        'updated_at': Timestamp.fromDate(DateTime.now()),
        'updated_by': currentUserId,
      };

      await _db.collection(_personsCollection).doc(personne.id).update(personneData);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la personne: $e');
    }
  }

  /// Supprimer une personne
  Future<void> deletePersonne(String personneId) async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      await _db.collection(_personsCollection).doc(personneId).delete();
      
      // TODO: Supprimer également les filiations associées
      // await _db.collection(_filiationsCollection)
      //     .where('personne_id', isEqualTo: personneId)
      //     .get()
      //     .then((snapshot) => {
      //       for (var doc in snapshot.docs) {
      //         doc.reference.delete();
      //       }
      //     });
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la personne: $e');
    }
  }

  /// Rechercher des personnes
  Future<List<Personne>> searchPersonnes(String query, {String? familleId}) async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      Query queryBuilder = _db.collection(_personsCollection);
      
      if (familleId != null) {
        queryBuilder = queryBuilder.where('famille_id', isEqualTo: familleId);
      }

      // Firestore ne supporte pas la recherche textuelle native
      // On utilise une approche simple avec les noms
      final snapshot = await queryBuilder.get();
      
      final results = snapshot.docs.where((doc) {
        final data = doc.data();
        final nomComplet = '${data['prenoms'] ?? ''} ${data['nom_naissance'] ?? ''}'.toLowerCase();
        return nomComplet.contains(query.toLowerCase());
      }).toList();

      return results.map((doc) {
        final data = doc.data();
        return Personne(
          id: data['id'],
          nomNaissance: data['nom_naissance'],
          nomUsage: data['nom_usage'],
          prenoms: data['prenoms'],
          sexe: data['sexe'],
          dateNaissance: data['date_naissance'] != null 
              ? DatePartielle.fromString(data['date_naissance'])
              : null,
          lieuNaissance: data['lieu_naissance'],
          dateDeces: data['date_deces'] != null
              ? DatePartielle.fromString(data['date_deces'])
              : null,
          lieuDeces: data['lieu_deces'],
          biographie: data['biographie'],
          notes: data['notes'],
          photoPath: data['photo_path'],
          createdAt: (data['created_at'] as Timestamp).toDate(),
          updatedAt: (data['updated_at'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche des personnes: $e');
    }
  }

  // ============================================
  // GESTION DES UNIONS
  // ============================================

  /// Ajouter une union
  Future<String> addUnion(Union union) async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      final unionData = {
        'id': union.id,
        'personne1_id': union.personne1Id,
        'personne2_id': union.personne2Id,
        'type_union': union.typeUnion,
        'date_debut': union.dateDebut?.toString(),
        'lieu_debut': union.lieuDebut,
        'date_fin': union.dateFin?.toString(),
        'lieu_fin': union.lieuFin,
        'notes': union.notes,
        'created_at': Timestamp.fromDate(union.createdAt),
        'updated_at': Timestamp.fromDate(union.updatedAt),
        'created_by': currentUserId,
      };

      await _db.collection(_unionsCollection).doc(union.id).set(unionData);
      return union.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de l\'union: $e');
    }
  }

  /// Récupérer toutes les unions
  Future<List<Union>> getAllUnions() async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      final snapshot = await _db.collection(_unionsCollection).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Union(
          id: data['id'],
          personne1Id: data['personne1_id'],
          personne2Id: data['personne2_id'],
          typeUnion: data['type_union'],
          dateDebut: data['date_debut'] != null
              ? DatePartielle.fromString(data['date_debut'])
              : null,
          lieuDebut: data['lieu_debut'],
          dateFin: data['date_fin'] != null
              ? DatePartielle.fromString(data['date_fin'])
              : null,
          lieuFin: data['lieu_fin'],
          notes: data['notes'],
          createdAt: (data['created_at'] as Timestamp).toDate(),
          updatedAt: (data['updated_at'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des unions: $e');
    }
  }

  // ============================================
  // STATISTIQUES
  // ============================================

  /// Récupérer les statistiques d'une famille
  Future<Map<String, int>> getFamilyStats({String? familleId}) async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      final personnesSnapshot = await _db
          .collection(_personsCollection)
          .where('famille_id', isEqualTo: familleId ?? 'default')
          .get();

      final unionsSnapshot = await _db.collection(_unionsCollection).get();

      return {
        'Total personnes': personnesSnapshot.docs.length,
        'Générations': _calculateGenerations(personnesSnapshot.docs),
        'Unions': unionsSnapshot.docs.length,
        'Photos': _countPhotos(personnesSnapshot.docs),
        'Documents': 0, // TODO: Implémenter le comptage de documents
      };
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  /// Calculer le nombre de générations
  int _calculateGenerations(List<QueryDocumentSnapshot> personnes) {
    // TODO: Implémenter un vrai calcul de générations basé sur les filiations
    return 5; // Valeur par défaut pour l'instant
  }

  /// Compter les photos
  int _countPhotos(List<QueryDocumentSnapshot> personnes) {
    return personnes.where((doc) => doc.data()['photo_path'] != null).length;
  }

  /// Stream pour écouter les changements sur les personnes
  Stream<List<Personne>> getPersonnesStream({String? familleId}) {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    Query query = _db.collection(_personsCollection);
    if (familleId != null) {
      query = query.where('famille_id', isEqualTo: familleId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Personne(
          id: data['id'],
          nomNaissance: data['nom_naissance'],
          nomUsage: data['nom_usage'],
          prenoms: data['prenoms'],
          sexe: data['sexe'],
          dateNaissance: data['date_naissance'] != null 
              ? DatePartielle.fromString(data['date_naissance'])
              : null,
          lieuNaissance: data['lieu_naissance'],
          dateDeces: data['date_deces'] != null
              ? DatePartielle.fromString(data['date_deces'])
              : null,
          lieuDeces: data['lieu_deces'],
          biographie: data['biographie'],
          notes: data['notes'],
          photoPath: data['photo_path'],
          createdAt: (data['created_at'] as Timestamp).toDate(),
          updatedAt: (data['updated_at'] as Timestamp).toDate(),
        );
      }).toList();
    });
  }
}
