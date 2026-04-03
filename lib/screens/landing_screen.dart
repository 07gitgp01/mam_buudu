import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'wizard_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  int _selectedGenerations = 5;
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF87CEEB), // Bleu ciel
              Color(0xFFE0F2FE), // Bleu très clair
              Colors.white,
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Column(
                children: [
                  // Hero Section avec dégradé
                  Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF87CEEB), // Bleu ciel
                          Color(0xFFE0F2FE), // Bleu très clair
                          Colors.white,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Illustration
                          Container(
                            height: 200,
                            width: 200,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.family_restroom,
                              size: 100,
                              color: Color(0xFF2E7D32), // Vert forêt
                            ),
                          ),
                          const SizedBox(height: 40),
                          
                          // Titre
                          const Text(
                            'Découvrez vos racines',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E), // Bleu foncé
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          
                          // Sous-titre
                          const Text(
                            'Créez votre arbre généalogique gratuitement',
                            style: TextStyle(
                              fontSize: 20,
                              color: Color(0xFF424242), // Gris foncé
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),
                          
                          // Bouton principal
                          ElevatedButton(
                            onPressed: _handleStartButton,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32), // Vert forêt
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 8,
                              shadowColor: const Color(0xFF2E7D32).withOpacity(0.3),
                            ),
                            child: const Text(
                              'Commencer',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Features Section
                  Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Column(
                      children: [
                        const Text(
                          'Fonctionnalités principales',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        
                        // Cartes de fonctionnalités
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 800) {
                              // Desktop layout
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: _buildFeatureCards().map((card) => Expanded(child: card)).toList(),
                              );
                            } else {
                              // Mobile layout
                              return Column(
                                children: _buildFeatureCards(),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Generation Section
                  Container(
                    padding: const EdgeInsets.all(48.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFF3E5F5), // Violet très clair
                          const Color(0xFFE8F5E8), // Vert très clair
                          Colors.white,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Visualisez votre héritage',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        
                        const Text(
                          'Choisissez jusqu\'à combien de générations vous souhaitez explorer',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF424242),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        
                        // Slider de générations
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: const Color(0xFF2E7D32),
                                  inactiveTrackColor: const Color(0xFFE0E0E0),
                                  thumbColor: const Color(0xFF2E7D32),
                                  overlayColor: const Color(0xFF2E7D32).withOpacity(0.2),
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 12,
                                  ),
                                  trackHeight: 8,
                                ),
                                child: Slider(
                                  value: _selectedGenerations.toDouble(),
                                  min: 1,
                                  max: 10,
                                  divisions: 9,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGenerations = value.round();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Aperçu texte
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Afficher les $_selectedGenerations générations',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(32.0),
                    color: const Color(0xFF1A237E),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _FooterLink(title: 'Mentions légales', onTap: null),
                            _FooterLink(title: 'Contact', onTap: null),
                            _FooterLink(title: 'À propos', onTap: null),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        const Text(
                          'Mam Buudu © 2024 - Votre histoire familiale, préservée',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFeatureCards() {
    final features = [
      {
        'icon': Icons.account_tree,
        'title': 'Arbre interactif',
        'description': 'Navigation fluide avec zoom et pan',
        'color': const Color(0xFF2E7D32),
      },
      {
        'icon': Icons.photo_library,
        'title': 'Photos & souvenirs',
        'description': 'Ajoutez des images et biographies',
        'color': const Color(0xFF1976D2),
      },
      {
        'icon': Icons.picture_as_pdf,
        'title': 'Export PDF',
        'description': 'Générez un livret de famille',
        'color': const Color(0xFF7B1FA2),
      },
    ];

    return features.map((feature) => Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        height: 220, // Réduit de 250 à 220
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Réduit de 24 à 16
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12), // Réduit de 16 à 12
                decoration: BoxDecoration(
                  color: (feature['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12), // Réduit de 16 à 12
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  size: 36, // Réduit de 48 à 36
                  color: feature['color'] as Color,
                ),
              ),
              const SizedBox(height: 12), // Réduit de 20 à 12
              
              Text(
                feature['title'] as String,
                style: const TextStyle(
                  fontSize: 16, // Réduit de 20 à 16
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
                textAlign: TextAlign.center,
                maxLines: 2, // Ajout de maxLines
                overflow: TextOverflow.ellipsis, // Ajout d'overflow
              ),
              const SizedBox(height: 8), // Réduit de 12 à 8
              
              Text(
                feature['description'] as String,
                style: const TextStyle(
                  fontSize: 12, // Réduit de 14 à 12
                  color: Color(0xFF424242),
                  height: 1.3, // Réduit de 1.4 à 1.3
                ),
                textAlign: TextAlign.center,
                maxLines: 2, // Ajout de maxLines
                overflow: TextOverflow.ellipsis, // Ajout d'overflow
              ),
            ],
          ),
        ),
      ),
    )).toList();
  }

  Future<void> _handleStartButton() async {
    // Vérifier si l'utilisateur a déjà utilisé l'application
    final prefs = await SharedPreferences.getInstance();
    final hasUsedApp = prefs.getBool('wizard_completed') ?? false;
    
    if (mounted) {
      if (hasUsedApp) {
        // Utilisateur existant → Dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Nouvel utilisateur → Wizard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WizardScreen()),
        );
      }
    }
  }
}

class _FooterLink extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _FooterLink({
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
