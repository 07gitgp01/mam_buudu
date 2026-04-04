import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../database/personne_repository.dart';
import '../models/personne.dart';
import '../services/auth_local_service.dart';
import 'person_form_screen.dart';
import 'union_form_screen.dart';
import 'person_detail_screen.dart';
import '../utils/gedcom_parser.dart';
import '../utils/gedcom_exporter.dart';
import 'landing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PersonneRepository _personneRepo = PersonneRepository();
  final AuthLocalService _authService = AuthLocalService();
  List<Personne> _personnes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPersonnes();
    // Ajouter un debounce pour la recherche
    _searchController.addListener(() {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _searchQuery = _searchController.text;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonnes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 Début du chargement des personnes...');
      // Utiliser Future.microtask pour éviter de bloquer le thread principal
      final personnes = await Future.microtask(() async {
        final result = await _personneRepo.getAll();
        print('✅ ${result.length} personnes chargées');
        return result;
      });
      
      setState(() {
        _personnes = personnes;
        _isLoading = false;
        print('✅ setState terminé - ${_personnes.length} personnes dans la liste');
      });
    } catch (e, stackTrace) {
      print('❌ Erreur lors du chargement: $e');
      print('📍 Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refresh() async {
    await _loadPersonnes();
  }

  void _navigateToLivret() {
    Navigator.pushNamed(context, '/livret');
  }

  Future<void> _importerGedcom() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowedExtensions: ['ged'],
        dialogTitle: 'Importer un fichier GEDCOM',
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.single.path!;
        final donnees = await GedcomParser.importer(
          filePath,
          onProgress: (avancement, message) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$message - $avancement%')),
              );
            }
          },
        );

        // Insérer les personnes dans la base de données
        for (final personneMap in donnees['personnes']) {
          final personne = Personne.fromMap(personneMap);
          await _personneRepo.insert(personne);
        }
        
        // TODO: Insérer les unions et filiations
        // for (final unionMap in donnees['unions']) { ... }
        // for (final filiationMap in donnees['filiations']) { ... }

        // Rafraîchir la liste
        await _loadPersonnes();

        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Importation terminée : ${donnees['personnes'].length} personnes ajoutées')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'import: $e')),
        );
      }
    }
  }

  Future<void> _exporterGedcom() async {
    try {
      // Récupérer toutes les données
      final personnes = await _personneRepo.getAll();
      // TODO: Récupérer les unions et filiations
      
      final contenuGedcom = await GedcomExporter.exporter(
        personnes: personnes,
        unions: [], // TODO: Remplacer par vraies unions
        filiations: [], // TODO: Remplacer par vraies filiations
      );

      await GedcomExporter.exporterVersFichier(contenuGedcom);

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exportation GEDCOM terminée avec succès')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'export: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LandingScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  List<Personne> get _filteredPersonnes {
    if (_searchQuery.isEmpty) return _personnes;
    
    // Optimisation : éviter de recréer la liste si la recherche est vide
    final query = _searchQuery.toLowerCase().trim();
    if (query.isEmpty) return _personnes;
    
    return _personnes.where((personne) {
      final nomComplet = personne.nomComplet.toLowerCase();
      return nomComplet.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LandingScreen()),
              (route) => false,
            );
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Arbre Généalogique'),
            if (_authService.currentUser != null)
              Text(
                'Connecté: ${_authService.currentUser!.nomComplet}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'import_gedcom') {
                _importerGedcom();
              } else if (value == 'export_gedcom') {
                _exporterGedcom();
              } else if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import_gedcom',
                child: Row(
                  children: [
                    Icon(Icons.upload_file),
                    SizedBox(width: 8),
                    Text('Importer GEDCOM'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_gedcom',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Exporter GEDCOM'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Se déconnecter', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une personne...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredPersonnes.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.builder(
                          itemCount: _filteredPersonnes.length,
                          itemBuilder: (context, index) {
                            final personne = _filteredPersonnes[index];
                            return _buildPersonneTile(personne);
                          },
                        ),
                      ),
                    ),
                    // Bouton pour créer une union même quand la liste n'est pas vide
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Bouton pour voir l'arbre généalogique
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _navigateToTree,
                              icon: const Icon(Icons.account_tree),
                              label: const Text('Voir l\'arbre généalogique'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[100],
                                foregroundColor: Colors.green[800],
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Bouton pour créer une union
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _navigateToAddUnion,
                              icon: const Icon(Icons.favorite),
                              label: const Text('Créer une union'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink[100],
                                foregroundColor: Colors.pink[800],
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToLivret,
                        icon: const Icon(Icons.book),
                        label: const Text('Générer un livret'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
    floatingActionButton: FloatingActionButton(
      onPressed: _navigateToAddPersonne,
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(Icons.person_add),
    ),
    );
  }

  Widget _buildEmptyState() {
    final isSearchActive = _searchQuery.isNotEmpty;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearchActive ? Icons.search_off : Icons.people_outline,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            isSearchActive
                ? 'Aucune personne trouvée pour "$_searchQuery"'
                : 'Aucune personne dans l\'arbre',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (!isSearchActive) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _navigateToAddPersonne,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Ajouter une personne'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _navigateToAddUnion,
                    icon: const Icon(Icons.favorite),
                    label: const Text('Créer une union'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[100],
                      foregroundColor: Colors.pink[800],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonneTile(Personne personne) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[300],
          backgroundImage: personne.photoPath != null
              ? FileImage(File(personne.photoPath!)) as ImageProvider
              : null,
          child: personne.photoPath == null
              ? Icon(
                  Icons.person,
                  color: Colors.grey[600],
                )
              : null,
        ),
        title: Text(
          personne.nomComplet,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: personne.datesAffichage.isNotEmpty
            ? Text(personne.datesAffichage)
            : null,
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _navigateToPersonneDetail(personne);
                break;
              case 'delete':
                _confirmDeletePersonne(personne);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _navigateToPersonneDetail(personne),
      ),
    );
  }

  Future<void> _confirmDeletePersonne(Personne personne) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir supprimer cette personne ?'),
            const SizedBox(height: 8),
            Text(
              personne.nomComplet,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cette action est irréversible et supprimera également toutes les relations associées.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deletePersonne(personne);
    }
  }

  Future<void> _deletePersonne(Personne personne) async {
    try {
      await _personneRepo.delete(personne.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${personne.nomComplet} a été supprimé(e)'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Annuler',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Implémenter la restauration si nécessaire
              },
            ),
          ),
        );
      }
      
      await _loadPersonnes();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToAddPersonne() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PersonFormScreen(),
      ),
    );
    
    if (result == true) {
      // Rafraîchir la liste
      await _refresh();
      
      // Message de confirmation
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personne ajoutée avec succès !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _navigateToTree() async {
    if (_personnes.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord ajouter des personnes à l\'arbre'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Utiliser la première personne comme racine par défaut
    final premierePersonne = _personnes.first;
    
    await Navigator.pushNamed(
      context,
      '/tree',
      arguments: premierePersonne.id,
    );
  }

  void _navigateToAddUnion() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UnionFormScreen(),
      ),
    );
    
    if (result == true) {
      // Rafraîchir la liste
      await _refresh();
      
      // Message de confirmation
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Union créée avec succès !'),
            backgroundColor: Colors.pink,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _navigateToPersonneDetail(Personne personne) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonDetailScreen(personneId: personne.id),
      ),
    );
    
    if (result == true) {
      // Rafraîchir la liste
      await _refresh();
      
      // Message de confirmation
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Modifications enregistrées avec succès !'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
