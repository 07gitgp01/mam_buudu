import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/personne.dart';
import '../models/union.dart';
import '../database/personne_repository.dart';
import '../database/union_repository.dart';
import '../database/filiation_repository.dart';
import '../utils/uuid_generator.dart';
import 'person_form_screen.dart';

class WizardScreen extends StatefulWidget {
  const WizardScreen({super.key});

  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  final PersonneRepository _personneRepo = PersonneRepository();
  final UnionRepository _unionRepo = UnionRepository();
  final FiliationRepository _filiationRepo = FiliationRepository();
  
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Données collectées
  Personne? _moi;
  Personne? _pere;
  Personne? _mere;
  Union? _unionParents;
  List<Personne> _freresSoeurs = [];
  Personne? _conjoint;
  Union? _unionConjoint;
  List<Personne> _enfants = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Assistant de création'),
            Text(
              'Étape ${_currentStep + 1}/5',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: _currentStep,
              onStepContinue: _nextStep,
              onStepCancel: _previousStep,
              onStepTapped: (step) => setState(() => _currentStep = step),
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Précédent'),
                        ),
                      const Spacer(),
                      if (_currentStep < 4)
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: const Text('Suivant'),
                        ),
                      if (_currentStep == 4)
                        ElevatedButton(
                          onPressed: _finishWizard,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Terminer'),
                        ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Qui es-tu ?'),
                  content: _buildMoiStep(),
                  isActive: _currentStep >= 0,
                  state: _getStepState(0),
                ),
                Step(
                  title: const Text('Tes parents'),
                  content: _buildParentsStep(),
                  isActive: _currentStep >= 1,
                  state: _getStepState(1),
                ),
                Step(
                  title: const Text('Tes frères et sœurs'),
                  content: _buildFreresSoeursStep(),
                  isActive: _currentStep >= 2,
                  state: _getStepState(2),
                ),
                Step(
                  title: const Text('Ton/Va conjoint(e)'),
                  content: _buildConjointStep(),
                  isActive: _currentStep >= 3,
                  state: _getStepState(3),
                ),
                Step(
                  title: const Text('Tes enfants'),
                  content: _buildEnfantsStep(),
                  isActive: _currentStep >= 4,
                  state: _getStepState(4),
                ),
              ],
            ),
    );
  }

  StepState _getStepState(int step) {
    if (_currentStep > step) return StepState.complete;
    if (_currentStep == step) return StepState.indexed;
    return StepState.disabled;
  }

  Widget _buildMoiStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Commençons par toi ! Qui es-tu ?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_moi == null)
          ElevatedButton.icon(
            onPressed: _addMoi,
            icon: const Icon(Icons.person_add),
            label: const Text('Ajouter mes informations'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          )
        else
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(_moi!.nomComplet),
              subtitle: Text(_moi!.datesAffichage),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _editMoi,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildParentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Qui sont tes parents ?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Card(
                child: Column(
                  children: [
                    const Icon(Icons.man, size: 48),
                    const Text('Père'),
                    const SizedBox(height: 8),
                    if (_pere == null)
                      ElevatedButton(
                        onPressed: _addPere,
                        child: const Text('Ajouter'),
                      )
                    else
                      Column(
                        children: [
                          Text(_pere!.nomComplet),
                          TextButton(
                            onPressed: _editPere,
                            child: const Text('Modifier'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                child: Column(
                  children: [
                    const Icon(Icons.woman, size: 48),
                    const Text('Mère'),
                    const SizedBox(height: 8),
                    if (_mere == null)
                      ElevatedButton(
                        onPressed: _addMere,
                        child: const Text('Ajouter'),
                      )
                    else
                      Column(
                        children: [
                          Text(_mere!.nomComplet),
                          TextButton(
                            onPressed: _editMere,
                            child: const Text('Modifier'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFreresSoeursStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'As-tu des frères ou sœurs ?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _addFrereSoeur,
          icon: const Icon(Icons.person_add),
          label: const Text('Ajouter un frère/une sœur'),
        ),
        const SizedBox(height: 16),
        ..._freresSoeurs.map((personne) => Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(personne.nomComplet),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editFrereSoeur(personne),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteFrereSoeur(personne),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildConjointStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Es-tu en couple ?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_conjoint == null)
          ElevatedButton.icon(
            onPressed: _addConjoint,
            icon: const Icon(Icons.favorite),
            label: const Text('Ajouter mon/ma conjoint(e)'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          )
        else
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.favorite)),
              title: Text(_conjoint!.nomComplet),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _editConjoint,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEnfantsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'As-tu des enfants ?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _addEnfant,
          icon: const Icon(Icons.child_care),
          label: const Text('Ajouter un enfant'),
        ),
        const SizedBox(height: 16),
        ..._enfants.map((personne) => Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.child_care)),
            title: Text(personne.nomComplet),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editEnfant(personne),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteEnfant(personne),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _finishWizard() async {
    setState(() => _isLoading = true);
    
    try {
      // Sauvegarder toutes les données
      await _saveAllData();
      
      // Marquer le wizard comme terminé
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('wizard_completed', true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arbre généalogique créé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Rediriger vers HomeScreen
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAllData() async {
    // Sauvegarder moi
    if (_moi != null) {
      await _personneRepo.insert(_moi!);
    }
    
    // Sauvegarder parents et leur union
    if (_pere != null && _mere != null) {
      await _personneRepo.insert(_pere!);
      await _personneRepo.insert(_mere!);
      
      _unionParents = Union(
        id: generateUuid(),
        type: 'mariage',
        dateDebut: null,
        lieuDebut: null,
        dateFin: null,
        lieuFin: null,
        notes: 'Parents de ${_moi!.nomComplet}',
      );
      await _unionRepo.insert(_unionParents!);
      
      // Lier les parents à l'union
      await _unionRepo.ajouterParticipant(_unionParents!.id, _pere!.id, role: 'conjoint', ordre: 1);
      await _unionRepo.ajouterParticipant(_unionParents!.id, _mere!.id, role: 'conjointe', ordre: 2);
      
      // Lier moi à l'union des parents
      if (_moi != null) {
        await _filiationRepo.ajouterEnfantAUnion(_moi!.id, _unionParents!.id, typeLien: 'biologique', ordre: 1);
      }
    }
    
    // Sauvegarder frères et sœurs
    for (int i = 0; i < _freresSoeurs.length; i++) {
      final frereSoeur = _freresSoeurs[i];
      await _personneRepo.insert(frereSoeur);
      
      if (_unionParents != null) {
        await _filiationRepo.ajouterEnfantAUnion(frereSoeur.id, _unionParents!.id, typeLien: 'biologique', ordre: i + 2);
      }
    }
    
    // Sauvegarder conjoint et union
    if (_conjoint != null && _moi != null) {
      await _personneRepo.insert(_conjoint!);
      
      _unionConjoint = Union(
        id: generateUuid(),
        type: 'mariage',
        dateDebut: null,
        lieuDebut: null,
        dateFin: null,
        lieuFin: null,
        notes: 'Union de ${_moi!.nomComplet}',
      );
      await _unionRepo.insert(_unionConjoint!);
      
      // Lier moi et conjoint à l'union
      await _unionRepo.ajouterParticipant(_unionConjoint!.id, _moi!.id, role: 'conjoint', ordre: 1);
      await _unionRepo.ajouterParticipant(_unionConjoint!.id, _conjoint!.id, role: 'conjointe', ordre: 2);
    }
    
    // Sauvegarder enfants
    for (int i = 0; i < _enfants.length; i++) {
      final enfant = _enfants[i];
      await _personneRepo.insert(enfant);
      
      if (_unionConjoint != null) {
        await _filiationRepo.ajouterEnfantAUnion(enfant.id, _unionConjoint!.id, typeLien: 'biologique', ordre: i + 1);
      }
    }
  }

  // Méthodes pour ajouter/modifier les personnes
  Future<void> _addMoi() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PersonFormScreen()),
    );
    if (result != null && result is Personne) {
      setState(() => _moi = result);
    }
  }

  Future<void> _editMoi() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PersonFormScreen(personne: _moi)),
    );
    if (result != null && result is Personne) {
      setState(() => _moi = result);
    }
  }

  Future<void> _addPere() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PersonFormScreen()),
    );
    if (result != null && result is Personne) {
      setState(() => _pere = result);
    }
  }

  Future<void> _editPere() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PersonFormScreen(personne: _pere)),
    );
    if (result != null && result is Personne) {
      setState(() => _pere = result);
    }
  }

  Future<void> _addMere() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PersonFormScreen()),
    );
    if (result != null && result is Personne) {
      setState(() => _mere = result);
    }
  }

  Future<void> _editMere() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PersonFormScreen(personne: _mere)),
    );
    if (result != null && result is Personne) {
      setState(() => _mere = result);
    }
  }

  Future<void> _addFrereSoeur() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PersonFormScreen()),
    );
    if (result != null && result is Personne) {
      setState(() => _freresSoeurs.add(result));
    }
  }

  Future<void> _editFrereSoeur(Personne personne) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PersonFormScreen(personne: personne)),
    );
    if (result != null && result is Personne) {
      final index = _freresSoeurs.indexOf(personne);
      if (index != -1) {
        setState(() => _freresSoeurs[index] = result);
      }
    }
  }

  void _deleteFrereSoeur(Personne personne) {
    setState(() => _freresSoeurs.remove(personne));
  }

  Future<void> _addConjoint() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PersonFormScreen()),
    );
    if (result != null && result is Personne) {
      setState(() => _conjoint = result);
    }
  }

  Future<void> _editConjoint() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PersonFormScreen(personne: _conjoint)),
    );
    if (result != null && result is Personne) {
      setState(() => _conjoint = result);
    }
  }

  Future<void> _addEnfant() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PersonFormScreen()),
    );
    if (result != null && result is Personne) {
      setState(() => _enfants.add(result));
    }
  }

  Future<void> _editEnfant(Personne personne) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PersonFormScreen(personne: personne)),
    );
    if (result != null && result is Personne) {
      final index = _enfants.indexOf(personne);
      if (index != -1) {
        setState(() => _enfants[index] = result);
      }
    }
  }

  void _deleteEnfant(Personne personne) {
    setState(() => _enfants.remove(personne));
  }
}
