import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

/// Service Firebase Storage pour la gestion des fichiers de Mam Buudu
class FirebaseStorageService {
  static final FirebaseStorageService _instance = FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Récupérer l'ID de l'utilisateur actuel
  String? get currentUserId => _auth.currentUser?.uid;

  /// Vérifier si l'utilisateur est connecté
  bool get isUserConnected => _auth.currentUser != null;

  /// Dossiers de stockage
  static const String _profilePhotosFolder = 'profile_photos';
  static const String _personPhotosFolder = 'person_photos';
  static const String _familyDocumentsFolder = 'family_documents';
  static const String _gedcomFilesFolder = 'gedcom_files';

  // ============================================
  // GESTION DES PHOTOS DE PROFIL
  // ============================================

  /// Uploader une photo de profil
  Future<String> uploadProfilePhoto(File imageFile) async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      // Générer un nom de fichier unique
      final fileName = '${currentUserId}_profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('$_profilePhotosFolder/$fileName');

      // Uploader le fichier
      final uploadTask = await ref.putFile(imageFile);
      
      // Vérifier si l'upload a réussi
      if (uploadTask.state == TaskState.success) {
        return await ref.getDownloadURL();
      } else {
        throw Exception('Échec de l\'upload de la photo de profil');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'upload de la photo de profil: $e');
    }
  }

  /// Uploader une photo de profil depuis ImagePicker
  Future<String?> uploadProfilePhotoFromPicker() async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image == null) return null;

      final file = File(image.path);
      return await uploadProfilePhoto(file);
    } catch (e) {
      throw Exception('Erreur lors de la sélection de la photo: $e');
    }
  }

  /// Prendre une photo de profil avec l'appareil
  Future<String?> captureProfilePhoto() async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image == null) return null;

      final file = File(image.path);
      return await uploadProfilePhoto(file);
    } catch (e) {
      throw Exception('Erreur lors de la capture de la photo: $e');
    }
  }

  // ============================================
  // GESTION DES PHOTOS DE PERSONNES
  // ============================================

  /// Uploader une photo pour une personne
  Future<String> uploadPersonPhoto(File imageFile, String personneId) async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      // Générer un nom de fichier unique
      final fileName = '${personneId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('$_personPhotosFolder/$fileName');

      // Uploader le fichier
      final uploadTask = await ref.putFile(imageFile);
      
      // Vérifier si l'upload a réussi
      if (uploadTask.state == TaskState.success) {
        return await ref.getDownloadURL();
      } else {
        throw Exception('Échec de l\'upload de la photo');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'upload de la photo: $e');
    }
  }

  /// Uploader une photo pour une personne depuis ImagePicker
  Future<String?> uploadPersonPhotoFromPicker(String personneId) async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) return null;

      final file = File(image.path);
      return await uploadPersonPhoto(file, personneId);
    } catch (e) {
      throw Exception('Erreur lors de la sélection de la photo: $e');
    }
  }

  /// Prendre une photo pour une personne avec l'appareil
  Future<String?> capturePersonPhoto(String personneId) async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) return null;

      final file = File(image.path);
      return await uploadPersonPhoto(file, personneId);
    } catch (e) {
      throw Exception('Erreur lors de la capture de la photo: $e');
    }
  }

  // ============================================
  // GESTION DES DOCUMENTS FAMILIAUX
  // ============================================

  /// Uploader un document familial
  Future<String> uploadFamilyDocument(File file, String documentName) async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      // Récupérer l'extension du fichier
      final extension = file.path.split('.').last.toLowerCase();
      final fileName = '${currentUserId}_${documentName}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final ref = _storage.ref().child('$_familyDocumentsFolder/$fileName');

      // Uploader le fichier
      final uploadTask = await ref.putFile(file);
      
      // Vérifier si l'upload a réussi
      if (uploadTask.state == TaskState.success) {
        return await ref.getDownloadURL();
      } else {
        throw Exception('Échec de l\'upload du document');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'upload du document: $e');
    }
  }

  /// Uploader un document familial depuis FilePicker
  Future<String?> uploadFamilyDocumentFromPicker() async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      final FilePicker picker = FilePicker();
      final result = await picker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
      );

      if (result == null || result.files.isEmpty) return null;

      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      return await uploadFamilyDocument(file, fileName);
    } catch (e) {
      throw Exception('Erreur lors de la sélection du document: $e');
    }
  }

  // ============================================
  // GESTION DES FICHIERS GEDCOM
  // ============================================

  /// Uploader un fichier GEDCOM
  Future<String> uploadGedcomFile(File gedcomFile) async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      final fileName = '${currentUserId}_gedcom_${DateTime.now().millisecondsSinceEpoch}.ged';
      final ref = _storage.ref().child('$_gedcomFilesFolder/$fileName');

      // Uploader le fichier
      final uploadTask = await ref.putFile(gedcomFile);
      
      // Vérifier si l'upload a réussi
      if (uploadTask.state == TaskState.success) {
        return await ref.getDownloadURL();
      } else {
        throw Exception('Échec de l\'upload du fichier GEDCOM');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'upload du fichier GEDCOM: $e');
    }
  }

  /// Uploader un fichier GEDCOM depuis FilePicker
  Future<String?> uploadGedcomFileFromPicker() async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      final FilePicker picker = FilePicker();
      final result = await picker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ged'],
      );

      if (result == null || result.files.isEmpty) return null;

      final file = File(result.files.single.path!);
      return await uploadGedcomFile(file);
    } catch (e) {
      throw Exception('Erreur lors de la sélection du fichier GEDCOM: $e');
    }
  }

  // ============================================
  // GESTION DES FICHIERS
  // ============================================

  /// Supprimer un fichier par son URL
  Future<void> deleteFile(String fileUrl) async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du fichier: $e');
    }
  }

  /// Récupérer les métadonnées d'un fichier
  Future<FullMetadata> getFileMetadata(String fileUrl) async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      final ref = _storage.refFromURL(fileUrl);
      return await ref.getMetadata();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des métadonnées: $e');
    }
  }

  /// Lister les fichiers d'un dossier
  Future<ListResult> listFilesInFolder(String folderPath) async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      final ref = _storage.ref().child(folderPath);
      return await ref.listAll();
    } catch (e) {
      throw Exception('Erreur lors de la liste des fichiers: $e');
    }
  }

  /// Stream pour suivre la progression d'un upload
  Stream<TaskSnapshot> uploadWithProgress(File file, String filePath) async* {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    final ref = _storage.ref().child(filePath);
    final uploadTask = ref.putFile(file);
    
    yield* uploadTask.snapshotEvents;
  }

  /// Obtenir la taille de stockage utilisée par l'utilisateur
  Future<int> getUserStorageSize() async {
    if (!isUserConnected) throw Exception('Utilisateur non connecté');

    try {
      int totalSize = 0;
      
      // Calculer la taille des photos de profil
      final profilePhotos = await listFilesInFolder(_profilePhotosFolder);
      for (var item in profilePhotos.items) {
        if (item.name.contains(currentUserId!)) {
          final metadata = await item.getMetadata();
          totalSize += metadata.size ?? 0;
        }
      }

      // Calculer la taille des photos de personnes
      final personPhotos = await listFilesInFolder(_personPhotosFolder);
      for (var item in personPhotos.items) {
        if (item.name.contains(currentUserId!)) {
          final metadata = await item.getMetadata();
          totalSize += metadata.size ?? 0;
        }
      }

      // Calculer la taille des documents
      final documents = await listFilesInFolder(_familyDocumentsFolder);
      for (var item in documents.items) {
        if (item.name.contains(currentUserId!)) {
          final metadata = await item.getMetadata();
          totalSize += metadata.size ?? 0;
        }
      }

      return totalSize;
    } catch (e) {
      throw Exception('Erreur lors du calcul de la taille de stockage: $e');
    }
  }

  /// Formater la taille en octets en format lisible
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
