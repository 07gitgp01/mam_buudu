import 'dart:async';
import '../models/personne.dart';
import '../models/union.dart';
import '../database/personne_repository.dart';
import '../database/union_repository.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final PersonneRepository _personneRepo = PersonneRepository();
  final UnionRepository _unionRepo = UnionRepository();

  // Cache
  List<Personne>? _cachedPersonnes;
  List<Union>? _cachedUnions;
  DateTime? _lastPersonneUpdate;
  DateTime? _lastUnionUpdate;
  
  // Durée du cache en minutes
  static const int _cacheDuration = 5;

  Future<List<Personne>> getPersonnes({bool forceRefresh = false}) async {
    final now = DateTime.now();
    
    // Vérifier si le cache est valide
    if (!forceRefresh && 
        _cachedPersonnes != null && 
        _lastPersonneUpdate != null && 
        now.difference(_lastPersonneUpdate!).inMinutes < _cacheDuration) {
      return _cachedPersonnes!;
    }

    // Rafraîchir le cache
    try {
      _cachedPersonnes = await _personneRepo.getAll();
      _lastPersonneUpdate = now;
      return _cachedPersonnes!;
    } catch (e) {
      // En cas d'erreur, retourner le cache existant si disponible
      if (_cachedPersonnes != null) {
        return _cachedPersonnes!;
      }
      rethrow;
    }
  }

  Future<List<Union>> getUnions({bool forceRefresh = false}) async {
    final now = DateTime.now();
    
    // Vérifier si le cache est valide
    if (!forceRefresh && 
        _cachedUnions != null && 
        _lastUnionUpdate != null && 
        now.difference(_lastUnionUpdate!).inMinutes < _cacheDuration) {
      return _cachedUnions!;
    }

    // Rafraîchir le cache
    try {
      _cachedUnions = await _unionRepo.getAll();
      _lastUnionUpdate = now;
      return _cachedUnions!;
    } catch (e) {
      // En cas d'erreur, retourner le cache existant si disponible
      if (_cachedUnions != null) {
        return _cachedUnions!;
      }
      rethrow;
    }
  }

  void invalidatePersonneCache() {
    _cachedPersonnes = null;
    _lastPersonneUpdate = null;
  }

  void invalidateUnionCache() {
    _cachedUnions = null;
    _lastUnionUpdate = null;
  }

  void invalidateAllCache() {
    invalidatePersonneCache();
    invalidateUnionCache();
  }

  // Méthodes pour ajouter/modifier/supprimer avec mise à jour du cache
  Future<String> addPersonne(Personne personne) async {
    final id = await _personneRepo.insert(personne);
    invalidatePersonneCache();
    return id;
  }

  Future<void> updatePersonne(Personne personne) async {
    await _personneRepo.update(personne);
    invalidatePersonneCache();
  }

  Future<void> deletePersonne(String id) async {
    await _personneRepo.delete(id);
    invalidatePersonneCache();
  }

  Future<String> addUnion(Union union) async {
    final id = await _unionRepo.insert(union);
    invalidateUnionCache();
    return id;
  }

  Future<void> updateUnion(Union union) async {
    await _unionRepo.update(union);
    invalidateUnionCache();
  }

  Future<void> deleteUnion(String id) async {
    await _unionRepo.delete(id);
    invalidateUnionCache();
  }

  // Statistiques du cache
  CacheStats getStats() {
    return CacheStats(
      personneCacheValid: _cachedPersonnes != null && _lastPersonneUpdate != null,
      unionCacheValid: _cachedUnions != null && _lastUnionUpdate != null,
      personneCount: _cachedPersonnes?.length ?? 0,
      unionCount: _cachedUnions?.length ?? 0,
      lastPersonneUpdate: _lastPersonneUpdate,
      lastUnionUpdate: _lastUnionUpdate,
    );
  }
}

class CacheStats {
  final bool personneCacheValid;
  final bool unionCacheValid;
  final int personneCount;
  final int unionCount;
  final DateTime? lastPersonneUpdate;
  final DateTime? lastUnionUpdate;

  CacheStats({
    required this.personneCacheValid,
    required this.unionCacheValid,
    required this.personneCount,
    required this.unionCount,
    this.lastPersonneUpdate,
    this.lastUnionUpdate,
  });
}
