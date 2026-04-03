import 'dart:io';
import 'package:flutter/material.dart';
import '../models/personne.dart';
import '../models/union.dart';
import '../database/personne_repository.dart';
import '../database/union_repository.dart';
import '../database/filiation_repository.dart';
import 'person_form_screen.dart';
import 'union_form_screen.dart';
import 'ajout_enfant_screen.dart';

class PersonDetailScreen extends StatefulWidget {
  final String personneId;

  const PersonDetailScreen({super.key, required this.personneId});

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  final PersonneRepository _personneRepo = PersonneRepository();
  final UnionRepository _unionRepo = UnionRepository();
  final FiliationRepository _filiationRepo = FiliationRepository();
  
  Personne? _personne;
  List<Union> _unions = [];
  List<Personne> _enfants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPersonne();
  }

  Future<void> _loadPersonne() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final personne = await _personneRepo.getById(widget.personneId);
      if (personne != null) {
        setState(() {
          _personne = personne;
        });
        // Charger les unions et enfants après avoir chargé la personne
        await _loadUnions();
        await _loadEnfants();
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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

  Future<void> _loadUnions() async {
    if (_personne == null) return;
    
    try {
      final unions = await _unionRepo.getByPersonneId(_personne!.id);
      setState(() {
        _unions = unions;
      });
    } catch (e) {
      print('Erreur lors du chargement des unions: $e');
    }
  }

  Future<void> _loadEnfants() async {
    if (_personne == null) return;
    
    try {
      // Récupérer tous les enfants de toutes les unions de la personne
      List<Personne> tousLesEnfants = [];
      
      for (final union in _unions) {
        final enfants = await _filiationRepo.getEnfantsByUnionId(union.id);
        tousLesEnfants.addAll(enfants);
      }
      
      // Supprimer les doublons
      final enfantIds = <String>{};
      final enfantsUniques = tousLesEnfants.where((enfant) {
        if (enfantIds.contains(enfant.id)) return false;
        enfantIds.add(enfant.id);
        return true;
      }).toList();
      
      setState(() {
        _enfants = enfantsUniques;
      });
    } catch (e) {
      print('Erreur lors du chargement des enfants: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_personne == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détail')),
        body: const Center(
          child: Text('Personne non trouvée'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_personne!.nomComplet),
        actions: [
          IconButton(
            onPressed: _editPersonne,
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier',
          ),
          IconButton(
            onPressed: _deletePersonne,
            icon: const Icon(Icons.delete),
            tooltip: 'Supprimer',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo et informations principales
            _buildPhotoSection(),
            const SizedBox(height: 24),
            
            // Informations générales
            _buildGeneralInfoCard(),
            const SizedBox(height: 16),
            
            // Biographie
            if (_personne!.biographie != null && _personne!.biographie!.isNotEmpty)
              _buildBiographyCard(),
            
            // Unions (placeholder pour l'étape 3)
            _buildUnionsCard(),
            
            // Enfants (placeholder pour l'étape 3)
            _buildChildrenCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[300],
            backgroundImage: _personne!.photoPath != null
                ? FileImage(File(_personne!.photoPath!)) as ImageProvider
                : null,
            child: _personne!.photoPath == null
                ? Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.grey[600],
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            _personne!.nomComplet,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (_personne!.ageActuel != null || _personne!.ageDeces != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _personne!.ageDeces ?? _personne!.ageActuel ?? '',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGeneralInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations générales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (_personne!.sexe != null)
              _buildInfoRow('Sexe', _getSexeDisplay(_personne!.sexe!)),
            
            if (_personne!.dateNaissance != null)
              _buildInfoRow('Date de naissance', _personne!.dateNaissance!.toString()),
            
            if (_personne!.lieuNaissance != null)
              _buildInfoRow('Lieu de naissance', _personne!.lieuNaissance!),
            
            if (_personne!.dateDeces != null)
              _buildInfoRow('Date de décès', _personne!.dateDeces!.toString()),
            
            if (_personne!.lieuDeces != null)
              _buildInfoRow('Lieu de décès', _personne!.lieuDeces!),
            
            if (_personne!.nomUsage != null && _personne!.nomUsage!.isNotEmpty)
              _buildInfoRow('Nom d\'usage', _personne!.nomUsage!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label :',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildBiographyCard() {
    return Card(
      child: ExpansionTile(
        title: const Text(
          'Biographie',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_personne!.biographie!),
          ),
        ],
      ),
    );
  }

  Widget _buildUnionsCard() {
    return Card(
      child: ExpansionTile(
        title: Row(
          children: [
            const Text(
              'Unions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${_unions.length}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        children: [
          if (_unions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Aucune union enregistrée',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addUnion,
                    icon: const Icon(Icons.add),
                    label: const Text('Créer votre première union'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[100],
                      foregroundColor: Colors.pink[800],
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ..._unions.map((union) => _buildUnionTile(union)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: _addUnion,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une union'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildUnionTile(Union union) {
    return FutureBuilder<List<Personne>>(
      future: _unionRepo.getParticipants(union.id),
      builder: (context, snapshot) {
        final participants = snapshot.data ?? [];
        final conjoints = participants
            .where((p) => p.id != _personne!.id)
            .toList();
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(
              '${_getUnionTypeDisplay(union.type ?? '')} - ${union.dateDebut?.toString() ?? 'Date inconnue'}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (conjoints.isNotEmpty)
                  Text('Conjoint(s): ${conjoints.map((c) => c.nomComplet).join(', ')}'),
                if (union.lieuDebut != null)
                  Text('Lieu: ${union.lieuDebut}'),
                if (union.estEnCours)
                  const Text(
                    'En cours',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'details':
                    // TODO: Implémenter les détails de l'union
                    break;
                  case 'add_child':
                    _addChildToUnion(union);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'details',
                  child: Text('Voir détails'),
                ),
                const PopupMenuItem(
                  value: 'add_child',
                  child: Text('Ajouter un enfant'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChildrenCard() {
    return Card(
      child: ExpansionTile(
        title: Row(
          children: [
            const Text(
              'Enfants',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${_enfants.length}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        children: [
          if (_enfants.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Aucun enfant enregistré',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addChildToAnyUnion,
                    icon: const Icon(Icons.child_care),
                    label: const Text('Ajouter votre premier enfant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[100],
                      foregroundColor: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _enfants.map((enfant) => _buildEnfantTile(enfant)).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: _addChildToAnyUnion,
                icon: const Icon(Icons.child_care),
                label: const Text('Ajouter un enfant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[100],
                  foregroundColor: Colors.blue[800],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildEnfantTile(Personne enfant) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[300],
        backgroundImage: enfant.photoPath != null
            ? FileImage(File(enfant.photoPath!)) as ImageProvider
            : null,
        child: enfant.photoPath == null
            ? Icon(
                Icons.person,
                size: 20,
                color: Colors.grey[600],
              )
            : null,
      ),
      title: Text(enfant.nomComplet),
      subtitle: enfant.datesAffichage.isNotEmpty
          ? Text(enfant.datesAffichage)
          : null,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PersonDetailScreen(personneId: enfant.id),
        ),
      ),
    );
  }

  String _getSexeDisplay(String sexe) {
    switch (sexe) {
      case 'M':
        return 'Masculin';
      case 'F':
        return 'Féminin';
      case 'X':
        return 'Autre';
      default:
        return sexe;
    }
  }

  String _getUnionTypeDisplay(String type) {
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

  Future<void> _addUnion() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnionFormScreen(
          personneIdInitiale: _personne!.id,
        ),
      ),
    );
    
    if (result == true) {
      _loadUnions();
      _loadEnfants(); // Recharger les enfants au cas où
    }
  }

  Future<void> _addChildToUnion(Union union) async {
    // Récupérer les participants de l'union
    final participants = await _unionRepo.getParticipants(union.id);
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjoutEnfantScreen(
          unionId: union.id,
          parents: participants,
        ),
      ),
    );
    
    if (result == true) {
      _loadEnfants();
    }
  }

  Future<void> _addChildToAnyUnion() async {
    if (_unions.isEmpty) {
      // Si aucune union, proposer d'en créer une première
      final createUnion = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Aucune union disponible'),
          content: const Text('Vous devez créer une union avant d\'ajouter un enfant. Voulez-vous créer une union maintenant ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Créer une union'),
            ),
          ],
        ),
      );
      
      if (createUnion == true) {
        _addUnion();
      }
      return;
    }
    
    // Si une seule union, ajouter directement
    if (_unions.length == 1) {
      await _addChildToUnion(_unions.first);
      return;
    }
    
    // Si plusieurs unions, demander laquelle choisir
    final selectedUnion = await showDialog<Union>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une union'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _unions.map((union) => RadioListTile<Union>(
            title: Text('${_getUnionTypeDisplay(union.type ?? '')} - ${union.dateDebut?.toString() ?? 'Date inconnue'}'),
            value: union,
            groupValue: null,
            onChanged: (value) {
              Navigator.pop(context, value);
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
    
    if (selectedUnion != null) {
      await _addChildToUnion(selectedUnion);
    }
  }

  Future<void> _editPersonne() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonFormScreen(personne: _personne),
      ),
    );
    
    if (result == true) {
      _loadPersonne();
    }
  }

  Future<void> _deletePersonne() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${_personne!.nomComplet} ? Cette action est irréversible.',
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

    if (confirmed == true) {
      try {
        await _personneRepo.delete(_personne!.id);
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
