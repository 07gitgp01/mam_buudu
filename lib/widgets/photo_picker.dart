import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PhotoPicker extends StatefulWidget {
  final String? initialImagePath;
  final ValueChanged<String?> onImageSelected;
  final double size;

  const PhotoPicker({
    super.key,
    this.initialImagePath,
    required this.onImageSelected,
    this.size = 100,
  });

  @override
  State<PhotoPicker> createState() => _PhotoPickerState();
}

class _PhotoPickerState extends State<PhotoPicker> {
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _imagePath = widget.initialImagePath;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image preview
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[200],
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _imagePath != null && _imagePath!.isNotEmpty
              ? ClipOval(
                  child: Image.file(
                    File(_imagePath!),
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder();
                    },
                  ),
                )
              : _buildPlaceholder(),
        ),
        const SizedBox(height: 8),
        
        // Action buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Camera button
            IconButton(
              onPressed: _pickFromCamera,
              icon: const Icon(Icons.camera_alt),
              tooltip: 'Prendre une photo',
            ),
            
            // Gallery button
            IconButton(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library),
              tooltip: 'Choisir depuis la galerie',
            ),
            
            // Remove button (only if image exists)
            if (_imagePath != null && _imagePath!.isNotEmpty)
              IconButton(
                onPressed: _removeImage,
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Supprimer la photo',
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Icon(
      Icons.person,
      size: widget.size * 0.5,
      color: Colors.grey[400],
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        final savedPath = await _saveImage(File(image.path));
        if (savedPath != null) {
          setState(() {
            _imagePath = savedPath;
          });
          widget.onImageSelected(savedPath);
        }
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        final savedPath = await _saveImage(File(image.path));
        if (savedPath != null) {
          setState(() {
            _imagePath = savedPath;
          });
          widget.onImageSelected(savedPath);
        }
      }
    } catch (e) {
      _showError('Erreur lors de la sélection d\'image: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _imagePath = null;
    });
    widget.onImageSelected(null);
  }

  Future<String?> _saveImage(File imageFile) async {
    try {
      // Créer le dossier medias s'il n'existe pas
      final directory = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(path.join(directory.path, 'medias'));
      
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }
      
      // Générer un nom de fichier unique
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'photo_$timestamp${path.extension(imageFile.path)}';
      final savedPath = path.join(mediaDir.path, fileName);
      
      // Copier le fichier
      final savedFile = await imageFile.copy(savedPath);
      return savedFile.path;
    } catch (e) {
      _showError('Erreur lors de la sauvegarde de l\'image: $e');
      return null;
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
