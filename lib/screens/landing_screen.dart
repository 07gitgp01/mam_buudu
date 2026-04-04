import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_local_service.dart';
import 'home_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  int _selectedGenerations = 5;
  final ScrollController _scrollController = ScrollController();
  bool _hasActiveSession = false;
  bool _hasCompletedWizard = false;
  bool _hasUsers = false;
  final AuthLocalService _authService = AuthLocalService();

  @override
  void initState() {
    super.initState();
    _checkUserState();
  }

  Future<void> _checkUserState() async {
    try {
      // Vérifier si une session est active
      final hasSession = await _authService.checkSession();
      
      // Vérifier si le wizard a été complété
      final prefs = await SharedPreferences.getInstance();
      final wizardCompleted = prefs.getBool('wizard_completed') ?? false;
      
      // Vérifier s'il y a des utilisateurs
      final users = await _authService.getAllUsers();
      
      if (mounted) {
        setState(() {
          _hasActiveSession = hasSession;
          _hasCompletedWizard = wizardCompleted;
          _hasUsers = users.isNotEmpty;
        });
      }
    } catch (e) {
      print('Erreur lors de la vérification de l\'état utilisateur: $e');
    }
  }

  Widget _buildActionButtons() {
    // Cas 1: Session active - bouton "Accéder à votre arbre"
    if (_hasActiveSession) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_tree, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Votre arbre',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  ),
                ),
              ],
          ),
        ),
      );
    }
    
    // Cas 2: Première fois (pas de wizard complété, pas d'utilisateurs) - bouton Commencer
    if (!_hasCompletedWizard && !_hasUsers) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/wizard');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Commencer',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
      );
    }
    
    // Cas 3: Wizard complété ou utilisateurs existent - boutons connexion/inscription
    return Column(
      children: [
        // Bouton principal - Connexion
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Se connecter',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Bouton secondaire - Inscription
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: const Color(0xFF2E7D32),
              width: 2,
            ),
          ),
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/register');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              side: const BorderSide(
                color: Color(0xFF2E7D32),
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add, size: 18),
                const SizedBox(width: 6),
                Text(
                  'S\'inscrire',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

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
            child: Column(
              children: [
                // Hero Section avec ancien dégradé
                Container(
                  height: MediaQuery.of(context).size.height * 0.65,
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo moderne
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFffffff), Color(0xFFf0f0f0)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: const Color(0xFF87CEEB).withOpacity(0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.family_restroom,
                          size: 60,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Titre avec Google Fonts
                      Text(
                        'Mam Buudu',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A237E),
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Connectez-vous à vos racines',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          color: const Color(0xFF424242),
                          fontWeight: FontWeight.w300,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Boutons d'action modernes
                      _buildActionButtons(),
                    ],
                  ),
                ),
                  
                // Features Section moderne
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
                  child: Column(
                    children: [
                      Text(
                        'Fonctionnalités puissantes',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A237E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      
                      Text(
                        'Tout ce dont vous avez besoin pour votre arbre généalogique',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: const Color(0xFF424242),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      
                      // Cartes de fonctionnalités modernes
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 800) {
                            // Desktop layout
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: _buildModernFeatureCards().map((card) => Expanded(child: card)).toList(),
                            );
                          } else {
                            // Mobile layout
                            return Column(
                              children: _buildModernFeatureCards(),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                  
                // Generation Section
                Container(
                  padding: const EdgeInsets.all(32.0),
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
                      Text(
                        'Visualisez votre héritage',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A237E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      
                      Text(
                        'Choisissez jusqu\'à combien de générations vous souhaitez explorer',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: const Color(0xFF424242),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      
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
                                style: GoogleFonts.lato(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Footer moderne
                Container(
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF1A237E).withOpacity(0.8),
                        const Color(0xFF1A237E),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            'Mentions légales',
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          Text(
                            'Contact',
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          Text(
                            'À propos',
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Text(
                        'Mam Buudu © 2024 - Votre histoire familiale, préservée',
                        style: GoogleFonts.lato(
                          color: Colors.white,
                          fontSize: 12,
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
    );
  }

  List<Widget> _buildModernFeatureCards() {
    final features = [
      {
        'icon': Icons.account_tree,
        'title': 'Arbre interactif',
        'description': 'Navigation fluide avec zoom et pan',
        'color': const Color(0xFF2E7D32),
        'bgColor': Colors.white,
      },
      {
        'icon': Icons.photo_library,
        'title': 'Photos & souvenirs',
        'description': 'Gérez vos souvenirs familiaux',
        'color': const Color(0xFF1976D2),
        'bgColor': Colors.white,
      },
      {
        'icon': Icons.people,
        'title': 'Multi-utilisateurs',
        'description': 'Chaque membre a son compte',
        'color': const Color(0xFF7B1FA2),
        'bgColor': Colors.white,
      },
    ];

    return features.map((feature) {
      return Container(
        width: 200,
        height: 250,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: feature['bgColor'] as Color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: (feature['color'] as Color).withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (feature['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  size: 30,
                  color: feature['color'] as Color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                feature['title'] as String,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                feature['description'] as String,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: const Color(0xFF424242),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
