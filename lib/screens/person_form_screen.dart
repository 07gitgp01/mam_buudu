import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../models/personne.dart';
import '../models/date_partielle.dart';
import '../database/personne_repository.dart';
import '../widgets/date_partielle_picker.dart';
import '../widgets/photo_picker.dart';
import '../services/notification_service.dart';
// import '../services/notification_local_service.dart';

class PersonFormScreen extends StatefulWidget {
  final Personne? personne;

  const PersonFormScreen({super.key, this.personne});

  @override
  State<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends State<PersonFormScreen> {
  final PersonneRepository _personneRepo = PersonneRepository();
  // final NotificationLocalService _notificationService = NotificationLocalService();
  final Uuid _uuid = const Uuid();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomNaissanceController;
  late TextEditingController _nomUsageController;
  late TextEditingController _prenomsController;
  late TextEditingController _lieuNaissanceController;
  late TextEditingController _lieuDecesController;
  late TextEditingController _biographieController;

  String? _sexe;
  DatePartielle? _dateNaissance;
  DatePartielle? _dateDeces;
  String? _photoPath;
  bool _isDecede = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final personne = widget.personne;
    
    _nomNaissanceController = TextEditingController(text: personne?.nomNaissance ?? '');
    _nomUsageController = TextEditingController(text: personne?.nomUsage ?? '');
    _prenomsController = TextEditingController(text: personne?.prenoms ?? '');
    _lieuNaissanceController = TextEditingController(text: personne?.lieuNaissance ?? '');
    _lieuDecesController = TextEditingController(text: personne?.lieuDeces ?? '');
    _biographieController = TextEditingController(text: personne?.biographie ?? '');
    
    _sexe = personne?.sexe;
    _dateNaissance = personne?.dateNaissance;
    _dateDeces = personne?.dateDeces;
    _photoPath = personne?.photoPath;
    _isDecede = personne?.dateDeces != null;
  }

  @override
  void dispose() {
    _nomNaissanceController.dispose();
    _nomUsageController.dispose();
    _prenomsController.dispose();
    _lieuNaissanceController.dispose();
    _lieuDecesController.dispose();
    _biographieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.personne == null ? 'Nouvelle personne' : 'Modifier une personne'),
        actions: [
          if (widget.personne != null)
            IconButton(
              onPressed: _deletePersonne,
              icon: const Icon(Icons.delete),
              tooltip: 'Supprimer',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo
                    Center(
                      child: PhotoPicker(
                        initialImagePath: _photoPath,
                        onImageSelected: (path) {
                          setState(() {
                            _photoPath = path;
                          });
                        },
                        size: 120,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Nom de naissance
                    TextFormField(
                      controller: _nomNaissanceController,
                      decoration: InputDecoration(
                        labelText: 'Nom de naissance',
                        hintText: 'Obligatoire si pas de prénoms',
                        border: const OutlineInputBorder(),
                        helperText: 'Au moins le nom ou les prénoms doivent être renseignés',
                      ),
                      validator: (value) {
                        final prenoms = _prenomsController.text.trim();
                        final nom = value?.trim() ?? '';
                        
                        if ((nom.isEmpty) && (prenoms.isEmpty)) {
                          return 'Le nom ou les prénoms sont obligatoires';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Nom d'usage
                    TextFormField(
                      controller: _nomUsageController,
                      decoration: const InputDecoration(
                        labelText: 'Nom d\'usage',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Prénoms
                    TextFormField(
                      controller: _prenomsController,
                      decoration: InputDecoration(
                        labelText: 'Prénoms',
                        hintText: 'Obligatoire si pas de nom',
                        border: const OutlineInputBorder(),
                        helperText: 'Au moins le nom ou les prénoms doivent être renseignés',
                      ),
                      validator: (value) {
                        final nom = _nomNaissanceController.text.trim();
                        final prenoms = value?.trim() ?? '';
                        
                        if ((prenoms.isEmpty) && (nom.isEmpty)) {
                          return 'Le nom ou les prénoms sont obligatoires';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Sexe
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Sexe',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _sexe,
                      items: const [
                        DropdownMenuItem(value: 'M', child: Text('Masculin')),
                        DropdownMenuItem(value: 'F', child: Text('Féminin')),
                        DropdownMenuItem(value: 'X', child: Text('Autre')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sexe = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Date de naissance
                    DatePartiellePicker(
                      initialValue: _dateNaissance,
                      onChanged: (date) {
                        setState(() {
                          _dateNaissance = date;
                        });
                      },
                      hintText: 'Date de naissance',
                    ),
                    const SizedBox(height: 16),
                    
                    // Lieu de naissance
                    TextFormField(
                      controller: _lieuNaissanceController,
                      decoration: const InputDecoration(
                        labelText: 'Lieu de naissance',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Décès
                    const Text(
                      'Informations de décès',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    
                    CheckboxListTile(
                      title: const Text('Décédé(e)'),
                      value: _isDecede,
                      onChanged: (value) {
                        setState(() {
                          _isDecede = value ?? false;
                          if (!_isDecede) {
                            _dateDeces = null;
                            _lieuDecesController.clear();
                          }
                        });
                      },
                    ),
                    
                    if (_isDecede) ...[
                      const SizedBox(height: 8),
                      DatePartiellePicker(
                        initialValue: _dateDeces,
                        onChanged: (date) {
                          setState(() {
                            _dateDeces = date;
                          });
                        },
                        hintText: 'Date de décès',
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _lieuDecesController,
                        decoration: const InputDecoration(
                          labelText: 'Lieu de décès',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    
                    // Biographie
                    TextFormField(
                      controller: _biographieController,
                      decoration: const InputDecoration(
                        labelText: 'Biographie',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      minLines: 3,
                    ),
                    const SizedBox(height: 32),
                    
                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _savePersonne,
                            child: const Text('Sauvegarder'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _savePersonne() async {
    if (!_formKey.currentState!.validate()) {
      // Le formulaire est invalide, les messages d'erreur s'affichent automatiquement
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Validation supplémentaire
      if (_nomNaissanceController.text.trim().isEmpty && _prenomsController.text.trim().isEmpty) {
        throw Exception('Le nom de naissance ou les prénoms sont obligatoires');
      }

      final personne = Personne(
        id: widget.personne?.id ?? _uuid.v4(),
        nomNaissance: _nomNaissanceController.text.trim().isEmpty 
            ? null 
            : _nomNaissanceController.text.trim(),
        nomUsage: _nomUsageController.text.trim().isEmpty 
            ? null 
            : _nomUsageController.text.trim(),
        prenoms: _prenomsController.text.trim().isEmpty 
            ? null 
            : _prenomsController.text.trim(),
        sexe: _sexe,
        dateNaissance: _dateNaissance,
        lieuNaissance: _lieuNaissanceController.text.trim().isEmpty 
            ? null 
            : _lieuNaissanceController.text.trim(),
        dateDeces: _dateDeces,
        lieuDeces: _isDecede
            ? _lieuDecesController.text.trim().isEmpty 
                ? null 
                : _lieuDecesController.text.trim()
            : null,
        biographie: _biographieController.text.trim().isEmpty 
            ? null 
            : _biographieController.text.trim(),
        photoPath: _photoPath,
        createdAt: widget.personne?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.personne == null) {
        await _personneRepo.insert(personne);
        _showSuccessSnackBar('Personne créée avec succès !');
        
        // Planifier les notifications d'anniversaire si une date de naissance est définie
        // if (personne.dateNaissance != null) {
        //   try {
        //     await _notificationService.scheduleBirthdayNotifications();
        //     print('Notifications d\'anniversaire planifiées pour ${personne.nomComplet}');
        //   } catch (e) {
        //     print('Erreur lors de la planification des notifications: $e');
        //   }
        // }
      } else {
        await _personneRepo.update(personne);
        _showSuccessSnackBar('Personne mise à jour avec succès !');
        
        // Mettre à jour les notifications d'anniversaire si la date de naissance a changé
        // if (personne.dateNaissance != null) {
        //   try {
        //     await _notificationService.scheduleBirthdayNotifications();
        //     print('Notifications d\'anniversaire mises à jour pour ${personne.nomComplet}');
        //   } catch (e) {
        //     print('Erreur lors de la mise à jour des notifications: $e');
        //   }
        // }
      }

      if (mounted) {
        // Retourner l'ID de la personne créée/modifiée
        Navigator.pop(context, personne.id);
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sauvegarde: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  Future<void> _deletePersonne() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette personne ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.personne != null) {
      try {
        await _personneRepo.delete(widget.personne!.id);
        NotificationService.showSuccess('Personne supprimée avec succès !');
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        NotificationService.showError('Erreur lors de la suppression: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
