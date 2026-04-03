import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/union.dart';
import '../models/personne.dart';
import '../models/date_partielle.dart';
import '../database/union_repository.dart';
import '../database/personne_repository.dart';
import '../widgets/date_partielle_picker.dart';
import '../widgets/multi_select_chip.dart';
import '../services/notification_service.dart';

class UnionFormScreen extends StatefulWidget {
  final String? personneIdInitiale;
  final Union? union;

  const UnionFormScreen({
    super.key,
    this.personneIdInitiale,
    this.union,
  });

  @override
  State<UnionFormScreen> createState() => _UnionFormScreenState();
}

class _UnionFormScreenState extends State<UnionFormScreen> {
  final UnionRepository _unionRepo = UnionRepository();
  final PersonneRepository _personneRepo = PersonneRepository();
  final Uuid _uuid = const Uuid();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _lieuDebutController;
  late TextEditingController _lieuFinController;
  late TextEditingController _notesController;

  String? _type;
  DatePartielle? _dateDebut;
  DatePartielle? _dateFin;
  List<Personne> _toutesLesPersonnes = [];
  List<Personne> _participants = [];
  bool _isLoading = false;

  // Types d'unions
  static const List<String> _typesUnions = [
    'mariage',
    'pacs', 
    'union_libre',
    'adoption',
    'polygamie',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadPersonnes();
  }

  void _initializeControllers() {
    final union = widget.union;
    
    _lieuDebutController = TextEditingController(text: union?.lieuDebut ?? '');
    _lieuFinController = TextEditingController(text: union?.lieuFin ?? '');
    _notesController = TextEditingController(text: union?.notes ?? '');
    
    _type = union?.type;
    _dateDebut = union?.dateDebut;
    _dateFin = union?.dateFin;
    
    // Si personneIdInitiale est fourni, l'ajouter aux participants par défaut
    if (widget.personneIdInitiale != null) {
      // On chargera la personne après avoir chargé toutes les personnes
    }
  }

  Future<void> _loadPersonnes() async {
    try {
      final personnes = await _personneRepo.getAll();
      setState(() {
        _toutesLesPersonnes = personnes;
        
        // Ajouter la personne initiale si fournie
        if (widget.personneIdInitiale != null) {
          final personneInitiale = personnes.firstWhere(
            (p) => p.id == widget.personneIdInitiale,
            orElse: () => personnes.first,
          );
          _participants.add(personneInitiale);
        }
        
        // Si mode édition, charger les participants de l'union
        if (widget.union != null) {
          _loadParticipants();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadParticipants() async {
    try {
      final participants = await _unionRepo.getParticipants(widget.union!.id);
      setState(() {
        _participants = participants;
      });
    } catch (e) {
      print('Erreur lors du chargement des participants: $e');
    }
  }

  @override
  void dispose() {
    _lieuDebutController.dispose();
    _lieuFinController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.union == null ? 'Nouvelle union' : 'Modifier l\'union'),
        actions: [
          if (widget.union != null)
            IconButton(
              onPressed: _deleteUnion,
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
                    // Type d'union
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Type d\'union',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _type,
                      items: _typesUnions.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_getTypeDisplay(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _type = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Date de début
                    DatePartiellePicker(
                      initialValue: _dateDebut,
                      onChanged: (date) {
                        setState(() {
                          _dateDebut = date;
                        });
                      },
                      hintText: 'Date de début',
                    ),
                    const SizedBox(height: 16),
                    
                    // Lieu de début
                    TextFormField(
                      controller: _lieuDebutController,
                      decoration: const InputDecoration(
                        labelText: 'Lieu de début',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Date de fin
                    DatePartiellePicker(
                      initialValue: _dateFin,
                      onChanged: (date) {
                        setState(() {
                          _dateFin = date;
                        });
                      },
                      hintText: 'Date de fin (optionnel)',
                    ),
                    const SizedBox(height: 16),
                    
                    // Lieu de fin
                    TextFormField(
                      controller: _lieuFinController,
                      decoration: const InputDecoration(
                        labelText: 'Lieu de fin (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Participants
                    MultiSelectChip<Personne>(
                      items: _toutesLesPersonnes,
                      displayName: (personne) => personne.nomComplet,
                      selected: _participants,
                      onChanged: (selected) {
                        setState(() {
                          _participants = selected;
                        });
      },
                      label: 'Participants (conjoints)',
                      allowEmptySelection: false,
                    ),
                    const SizedBox(height: 24),
                    
                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
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
                            onPressed: _saveUnion,
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

  String _getTypeDisplay(String type) {
    switch (type) {
      case 'mariage':
        return 'Mariage';
      case 'pacs':
        return 'PACS';
      case 'union_libre':
        return 'Union libre';
      case 'adoption':
        return 'Adoption';
      case 'polygamie':
        return 'Polygamie';
      default:
        return type;
    }
  }

  Future<void> _saveUnion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_participants.isEmpty) {
      NotificationService.showError('Veuillez sélectionner au moins un participant');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un participant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final union = Union(
        id: widget.union?.id ?? _uuid.v4(),
        type: _type,
        dateDebut: _dateDebut,
        lieuDebut: _lieuDebutController.text.trim().isEmpty 
            ? null 
            : _lieuDebutController.text.trim(),
        dateFin: _dateFin,
        lieuFin: _lieuFinController.text.trim().isEmpty 
            ? null 
            : _lieuFinController.text.trim(),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      if (widget.union == null) {
        // Création
        final unionId = await _unionRepo.insert(union);
        
        // Ajouter les participants
        for (int i = 0; i < _participants.length; i++) {
          await _unionRepo.ajouterParticipant(
            unionId,
            _participants[i].id,
            role: 'conjoint',
            ordre: i,
          );
        }
        NotificationService.showSuccess('Union créée avec succès !');
      } else {
        // Modification
        await _unionRepo.update(union);
        
        // Mettre à jour les participants (supprimer tous et recréer)
        for (final participant in _participants) {
          await _unionRepo.ajouterParticipant(
            union.id,
            participant.id,
            role: 'conjoint',
            ordre: _participants.indexOf(participant),
          );
        }
        NotificationService.showSuccess('Union mise à jour avec succès !');
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      NotificationService.showError('Erreur lors de la sauvegarde de l\'union: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteUnion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette union ? Cette action est irréversible.',
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

    if (confirmed == true && widget.union != null) {
      try {
        await _unionRepo.delete(widget.union!.id);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
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
