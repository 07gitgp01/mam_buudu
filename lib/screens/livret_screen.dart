import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/personne.dart';
import '../models/date_partielle.dart';
import '../services/html_generator.dart';
import '../services/livret_export_service.dart';

class LivretScreen extends StatefulWidget {
  const LivretScreen({super.key});

  @override
  State<LivretScreen> createState() => _LivretScreenState();
}

class _LivretScreenState extends State<LivretScreen> {
  List<Personne> _toutesPersonnes = [];
  Personne? _racineSelectionnee;
  bool _inclureArbre = true;
  bool _inclureFiches = true;
  bool _inclureIndex = true;
  bool _isLoading = false;
  String? _htmlGenere;
  
  @override
  void initState() {
    super.initState();
    _chargerPersonnes();
  }
  
  Future<void> _chargerPersonnes() async {
    try {
      // Simuler le chargement des personnes
      // En réalité, cela viendrait de la base de données
      setState(() {
        _isLoading = true;
      });
      
      // TODO: Implémenter le chargement réel depuis la base de données
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _isLoading = false;
        // Données de test pour la démo
        _toutesPersonnes = [
          Personne(
            id: '1',
            prenoms: 'Jean',
            nomNaissance: 'Dupont',
            dateNaissance: DatePartielle(annee: 1950, mois: 5, jour: 15),
            lieuNaissance: 'Paris',
            sexe: 'M',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Personne(
            id: '2',
            prenoms: 'Marie',
            nomNaissance: 'Durand',
            dateNaissance: DatePartielle(annee: 1952, mois: 8, jour: 20),
            lieuNaissance: 'Lyon',
            sexe: 'F',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Personne(
            id: '3',
            prenoms: 'Pierre',
            nomNaissance: 'Dupont',
            dateNaissance: DatePartielle(annee: 1975, mois: 3, jour: 10),
            lieuNaissance: 'Paris',
            sexe: 'M',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Personne(
            id: '4',
            prenoms: 'Sophie',
            nomNaissance: 'Durand',
            dateNaissance: DatePartielle(annee: 1978, mois: 11, jour: 25),
            lieuNaissance: 'Lyon',
            sexe: 'F',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        
        if (_toutesPersonnes.isNotEmpty) {
          _racineSelectionnee = _toutesPersonnes.first;
        }
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
  
  Future<void> _genererLivret() async {
    if (_racineSelectionnee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une racine')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Générer le HTML de base
      String htmlContent = HtmlGenerator.genererLivret(
        racine: _racineSelectionnee!,
        toutesPersonnes: _toutesPersonnes,
        unionsParPersonne: {}, // TODO: Implémenter les vraies unions
        enfantsParPersonne: {}, // TODO: Implémenter les vrais enfants
      );
      
      // Si on inclut l'arbre, capturer l'image et l'intégrer
      if (_inclureArbre) {
        // TODO: Capturer l'arbre depuis TreeScreen
        // final arbreImage = await LivretExportService.captureArbre(arbreKey);
        // htmlContent = await LivretExportService.genererHtmlAvecArbre(
        //   htmlBase: htmlContent,
        //   arbreImage: arbreImage,
        // );
      }
      
      _htmlGenere = htmlContent;
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur génération: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _previsualiserHtml() async {
    if (_htmlGenere == null) {
      await _genererLivret();
    }
    
    if (_htmlGenere != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LivretWebViewScreen(
            title: 'Prévisualisation du livret',
            htmlContent: _htmlGenere!,
          ),
        ),
      );
    }
  }
  
  Future<void> _exporterHtml() async {
    if (_htmlGenere == null) {
      await _genererLivret();
    }
    
    if (_htmlGenere != null) {
      await LivretExportService.exporterHtml(_htmlGenere!);
    }
  }
  
  Future<void> _exporterPdf() async {
    if (_htmlGenere == null) {
      await _genererLivret();
    }
    
    if (_htmlGenere != null) {
      await LivretExportService.exporterPdf(_htmlGenere!);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Générer un livret'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Génération du livret...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sélection de la racine
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personne racine',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _racineSelectionnee?.id,
                            decoration: const InputDecoration(
                              labelText: 'Sélectionner la racine',
                              border: OutlineInputBorder(),
                            ),
                            items: _toutesPersonnes.map((personne) {
                              final nomComplet = '${personne.prenoms} ${personne.nomUsage ?? personne.nomNaissance}';
                              return DropdownMenuItem(
                                value: personne.id,
                                child: Text(nomComplet),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _racineSelectionnee = _toutesPersonnes.firstWhere(
                                  (p) => p.id == value,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Options d'inclusion
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contenu à inclure',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            title: const Text('Inclure l\'arbre généalogique'),
                            value: _inclureArbre,
                            onChanged: (value) {
                              setState(() {
                                _inclureArbre = value!;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: const Text('Inclure les fiches individuelles'),
                            value: _inclureFiches,
                            onChanged: (value) {
                              setState(() {
                                _inclureFiches = value!;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: const Text('Inclure l\'index des noms'),
                            value: _inclureIndex,
                            onChanged: (value) {
                              setState(() {
                                _inclureIndex = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Boutons d'action
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _previsualiserHtml,
                          icon: const Icon(Icons.preview),
                          label: const Text('Prévisualiser HTML'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _exporterPdf,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Exporter PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Export HTML
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _exporterHtml,
                      icon: const Icon(Icons.share),
                      label: const Text('Partager HTML'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class LivretWebViewScreen extends StatelessWidget {
  final String title;
  final String htmlContent;
  
  const LivretWebViewScreen({
    super.key,
    required this.title,
    required this.htmlContent,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: WebViewWidget(
        controller: WebViewController()
          ..loadRequest(Uri.parse('data:text/html;charset=utf-8,${Uri.encodeComponent(htmlContent)}')),
      ),
    );
  }
}
