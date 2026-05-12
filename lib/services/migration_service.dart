import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/personne_repository.dart';
import '../database/union_repository.dart';
import '../database/filiation_repository.dart';
import '../services/firestore_service.dart';
import '../services/firebase_storage_service.dart';
import '../models/personne.dart';
import '../models/union.dart';

/// Service de migration des données locales vers Firebase
class MigrationService {
  static final MigrationService _instance = MigrationService._internal();
  factory MigrationService() => _instance;
  MigrationService._internal();

  final PersonneRepository _personneRepo = PersonneRepository();
  final UnionRepository _unionRepo = UnionRepository();
  final FiliationRepository _filiationRepo = FiliationRepository();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorageService _storageService = FirebaseStorageService();

  /// Vérifier si une migration est nécessaire
  Future<bool> needsMigration() async {
    try {
      // Vérifier si l'utilisateur est connecté
      if (!_firestoreService.isUserConnected) return false;

      // Vérifier s'il y a des données locales
      final localPersonnes = await _personneRepo.getAll();
      
      // Vérifier si les données existent déjà sur Firestore
      final remotePersonnes = await _firestoreService.getAllPersonnes();

      return localPersonnes.isNotEmpty && remotePersonnes.isEmpty;
    } catch (e) {
      print('Erreur lors de la vérification de migration: $e');
      return false;
    }
  }

  /// Migrer toutes les données locales vers Firebase
  Future<MigrationResult> migrateAllData({
    Function(int current, int total)? onProgress,
    Function(String)? onError,
  }) async {
    final result = MigrationResult();

    try {
      if (!_firestoreService.isUserConnected) {
        throw Exception('Utilisateur non connecté');
      }

      // 1. Migrer les personnes
      await _migratePersonnes(
        onProgress: (current, total) {
          result.personnesMigrated = current;
          onProgress?.call(current, total);
        },
        onError: onError,
      );

      // 2. Migrer les unions
      await _migrateUnions(
        onProgress: (current, total) {
          result.unionsMigrated = current;
          onProgress?.call(result.personnesMigrated + current, 
                           result.personnesMigrated + total);
        },
        onError: onError,
      );

      // 3. Migrer les filiations
      await _migrateFiliations(
        onProgress: (current, total) {
          result.filiationsMigrated = current;
          onProgress?.call(result.personnesMigrated + result.unionsMigrated + current,
                           result.personnesMigrated + result.unionsMigrated + total);
        },
        onError: onError,
      );

      result.success = true;
      result.message = 'Migration terminée avec succès';
    } catch (e) {
      result.success = false;
      result.message = 'Erreur lors de la migration: $e';
      onError?.call(result.message);
    }

    return result;
  }

  /// Migrer les personnes
  Future<void> _migratePersonnes({
    Function(int current, int total)? onProgress,
    Function(String)? onError,
  }) async {
    try {
      final personnes = await _personneRepo.getAll();
      int current = 0;

      for (final personne in personnes) {
        try {
          // Migrer la photo si elle existe localement
          if (personne.photoPath != null && File(personne.photoPath!).existsSync()) {
            final photoFile = File(personne.photoPath!);
            final photoUrl = await _storageService.uploadPersonPhoto(photoFile, personne.id);
            
            // Créer une nouvelle personne avec l'URL de la photo
            final personneWithCloudPhoto = Personne(
              id: personne.id,
              nomNaissance: personne.nomNaissance,
              nomUsage: personne.nomUsage,
              prenoms: personne.prenoms,
              sexe: personne.sexe,
              dateNaissance: personne.dateNaissance,
              lieuNaissance: personne.lieuNaissance,
              dateDeces: personne.dateDeces,
              lieuDeces: personne.lieuDeces,
              biographie: personne.biographie,
              notes: personne.notes,
              photoPath: photoUrl, // URL de Firebase Storage
              createdAt: personne.createdAt,
              updatedAt: DateTime.now(),
            );

            await _firestoreService.addPersonne(personneWithCloudPhoto);
          } else {
            // Migrer sans photo
            await _firestoreService.addPersonne(personne);
          }

          current++;
          onProgress?.call(current, personnes.length);
        } catch (e) {
          onError?.call('Erreur lors de la migration de ${personne.nomComplet}: $e');
          // Continuer avec les autres personnes
        }
      }
    } catch (e) {
      throw Exception('Erreur lors de la migration des personnes: $e');
    }
  }

  /// Migrer les unions
  Future<void> _migrateUnions({
    Function(int current, int total)? onProgress,
    Function(String)? onError,
  }) async {
    try {
      final unions = await _unionRepo.getAll();
      int current = 0;

      for (final union in unions) {
        try {
          await _firestoreService.addUnion(union);
          current++;
          onProgress?.call(current, unions.length);
        } catch (e) {
          onError?.call('Erreur lors de la migration de l\'union ${union.id}: $e');
        }
      }
    } catch (e) {
      throw Exception('Erreur lors de la migration des unions: $e');
    }
  }

  /// Migrer les filiations
  Future<void> _migrateFiliations({
    Function(int current, int total)? onProgress,
    Function(String)? onError,
  }) async {
    try {
      // TODO: Implémenter la migration des filiations
      // lorsque la structure dans Firestore sera prête
      print('Migration des filiations non implémentée encore');
    } catch (e) {
      throw Exception('Erreur lors de la migration des filiations: $e');
    }
  }

  /// Sauvegarder les données locales avant migration
  Future<void> backupLocalData() async {
    try {
      final personnes = await _personneRepo.getAll();
      final unions = await _unionRepo.getAll();
      
      // TODO: Implémenter la sauvegarde dans un fichier
      print('Backup des données locales: ${personnes.length} personnes, ${unions.length} unions');
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde des données: $e');
    }
  }

  /// Nettoyer les données locales après migration réussie
  Future<void> cleanupLocalData() async {
    try {
      // TODO: Implémenter le nettoyage optionnel des données locales
      // avec confirmation de l'utilisateur
      print('Nettoyage des données locales non implémenté encore');
    } catch (e) {
      throw Exception('Erreur lors du nettoyage des données: $e');
    }
  }

  /// Vérifier l'intégrité des données après migration
  Future<MigrationIntegrityReport> checkMigrationIntegrity() async {
    final report = MigrationIntegrityReport();

    try {
      // Comparer le nombre de personnes
      final localPersonnes = await _personneRepo.getAll();
      final remotePersonnes = await _firestoreService.getAllPersonnes();
      
      report.localPersonnesCount = localPersonnes.length;
      report.remotePersonnesCount = remotePersonnes.length;
      report.personnesMatch = localPersonnes.length == remotePersonnes.length;

      // Comparer le nombre d'unions
      final localUnions = await _unionRepo.getAll();
      final remoteUnions = await _firestoreService.getAllUnions();
      
      report.localUnionsCount = localUnions.length;
      report.remoteUnionsCount = remoteUnions.length;
      report.unionsMatch = localUnions.length == remoteUnions.length;

      // Vérifier les correspondances individuelles
      for (final personne in localPersonnes) {
        final remotePersonne = remotePersonnes.firstWhere(
          (p) => p.id == personne.id,
          orElse: () => throw Exception('Personne ${personne.id} non trouvée sur Firestore'),
        );

        // Vérifier les champs importants
        if (personne.nomComplet != remotePersonne.nomComplet) {
          report.addDiscrepancy('Personne ${personne.id}: nom différent');
        }

        if (personne.dateNaissance != remotePersonne.dateNaissance) {
          report.addDiscrepancy('Personne ${personne.id}: date de naissance différente');
        }
      }

      report.success = true;
    } catch (e) {
      report.success = false;
      report.addError('Erreur lors de la vérification: $e');
    }

    return report;
  }

  /// Annuler la migration (supprimer les données de Firestore)
  Future<void> rollbackMigration() async {
    try {
      // TODO: Implémenter l'annulation de migration
      // Attention: cette opération est irréversible
      print('Annulation de migration non implémentée encore');
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation de la migration: $e');
    }
  }
}

/// Résultat de la migration
class MigrationResult {
  bool success = false;
  String message = '';
  int personnesMigrated = 0;
  int unionsMigrated = 0;
  int filiationsMigrated = 0;
  List<String> errors = [];
  DateTime timestamp = DateTime.now();

  void addError(String error) {
    errors.add(error);
  }
}

/// Rapport d'intégrité de la migration
class MigrationIntegrityReport {
  bool success = false;
  int localPersonnesCount = 0;
  int remotePersonnesCount = 0;
  bool personnesMatch = false;
  int localUnionsCount = 0;
  int remoteUnionsCount = 0;
  bool unionsMatch = false;
  List<String> discrepancies = [];
  List<String> errors = [];
  DateTime timestamp = DateTime.now();

  void addDiscrepancy(String discrepancy) {
    discrepancies.add(discrepancy);
  }

  void addError(String error) {
    errors.add(error);
  }

  bool get isValid => success && personnesMatch && unionsMatch && discrepancies.isEmpty;
}
