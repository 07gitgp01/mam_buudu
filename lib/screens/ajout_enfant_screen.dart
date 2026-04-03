import 'package:flutter/material.dart';
import '../models/personne.dart';
import '../database/personne_repository.dart';
import '../database/filiation_repository.dart';
import '../widgets/multi_select_chip.dart';
import '../services/notification_service.dart';
import 'person_form_screen.dart';

class AjoutEnfantScreen extends StatefulWidget {
  final String unionId;
  final List<Personne> parents;

  const AjoutEnfantScreen({
    super.key,
    required this.unionId,
    required this.parents,
  });

  @override
  State<AjoutEnfantScreen> createState() => _AjoutEnfantScreenState();
}

class _AjoutEnfantScreenState extends State<AjoutEnfantScreen> {
  final PersonneRepository _personneRepo = PersonneRepository();
  final FiliationRepository _filiationRepo = FiliationRepository();

  List<Personne> _personnesExistantes = [];
  List<Personne> _selectedPersonne = [];
  bool _isLoading = false;
  bool _createNewPerson = false;

  @override
  void initState() {
    super.initState();
    _loadPersonnes();
  }

  Future<void> _loadPersonnes() async {
    try {
      final personnes = await _personneRepo.getAll();
      
      // Exclure les parents déjà dans l'union
      final parentIds = widget.parents.map((p) => p.id).toSet();
      final personnesDisponibles = personnes
          .where((p) => !parentIds.contains(p.id))
          .toList();
      
      setState(() {
        _personnesExistantes = personnesDisponibles;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un enfant'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations sur l'union
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Parents',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...widget.parents.map((parent) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text('• ${parent.nomComplet}'),
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Options
                  const Text(
                    'Comment ajouter l\'enfant ?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Option 1: Choisir une personne existante
                  RadioListTile<bool>(
                    title: const Text('Choisir une personne existante'),
                    subtitle: Text(
                      'Parmi ${_personnesExistantes.length} personnes disponibles',
                    ),
                    value: false,
                    groupValue: _createNewPerson,
                    onChanged: (value) {
                      setState(() {
                        _createNewPerson = value ?? false;
                      });
                    },
                  ),
                  
                  if (!_createNewPerson) ...[
                    const SizedBox(height: 16),
                    MultiSelectChip<Personne>(
                      items: _personnesExistantes,
                      displayName: (personne) => personne.nomComplet,
                      selected: _selectedPersonne,
                      onChanged: (selected) {
                        setState(() {
                          _selectedPersonne = selected;
                        });
                      },
                      label: 'Sélectionner la personne',
                      allowEmptySelection: false,
                    ),
                  ],
                  
                  // Option 2: Créer une nouvelle personne
                  RadioListTile<bool>(
                    title: const Text('Créer une nouvelle personne'),
                    subtitle: const Text('Remplir un formulaire pour créer un nouvel enfant'),
                    value: true,
                    groupValue: _createNewPerson,
                    onChanged: (value) {
                      setState(() {
                        _createNewPerson = value ?? false;
                      });
                    },
                  ),
                  
                  const Spacer(),
                  
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
                          onPressed: _canSave ? _saveEnfant : null,
                          child: const Text('Ajouter'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  bool get _canSave {
    if (_createNewPerson) return true;
    return _selectedPersonne.isNotEmpty;
  }

  Future<void> _saveEnfant() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String enfantId;
      
      if (_createNewPerson) {
        // Créer une nouvelle personne
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PersonFormScreen(
              // On pourrait passer des informations prédéfinies ici
            ),
          ),
        );
        
        if (result == null || result != true) {
          // L'utilisateur a annulé la création
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        // Récupérer la dernière personne créée (simple approximation)
        final personnes = await _personneRepo.getRecentlyAdded(limit: 1);
        if (personnes.isEmpty) {
          throw Exception('Impossible de récupérer la personne créée');
        }
        enfantId = personnes.first.id;
      } else {
        // Utiliser une personne existante
        enfantId = _selectedPersonne.first.id;
      }
      
      // Ajouter la filiation
      await _filiationRepo.ajouterEnfantAUnion(
        enfantId,
        widget.unionId,
        typeLien: 'biologique',
        ordre: 0, // Pourrait être amélioré avec un ordre automatique
      );
      
      NotificationService.showSuccess('Enfant ajouté avec succès !');
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      NotificationService.showError('Erreur lors de l\'ajout de l\'enfant: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout: $e'),
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
}

// Widget simplifié pour l'ajout rapide d'enfant
class AjoutEnfantDialog extends StatelessWidget {
  final String unionId;
  final List<Personne> parents;

  const AjoutEnfantDialog({
    super.key,
    required this.unionId,
    required this.parents,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: AjoutEnfantScreen(
          unionId: unionId,
          parents: parents,
        ),
      ),
    );
  }
}
