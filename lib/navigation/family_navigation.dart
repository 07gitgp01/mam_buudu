import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/family_connect_theme.dart';
import '../screens/tree_screen.dart';
import '../screens/person_form_screen.dart';
import '../screens/union_form_screen.dart';
import '../widgets/modern_home_screen.dart';
import '../widgets/modern_search_screen.dart';
import '../widgets/family_profile_screen.dart';
import '../stories/family_stories_screen.dart';
import '../screens/timeline_screen.dart';
import '../screens/family_games_screen.dart';
import '../services/auth_local_service.dart';

/// Élément de navigation pour la barre inférieure
class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
  });
}

/// Navigation moderne inspirée d'Instagram et TikTok
/// BottomNavigationBar avec animations fluides et badges
class FamilyNavigation extends StatefulWidget {
  const FamilyNavigation({super.key});

  @override
  State<FamilyNavigation> createState() => _FamilyNavigationState();
}

class _FamilyNavigationState extends State<FamilyNavigation> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  int _currentIndex = 0;
  bool _isAnimating = false;

  final AuthLocalService _authService = AuthLocalService();
  
  // Badges de notification
  final Map<int, bool> _badgeStates = {
    0: false, // Home
    1: true,  // Search (nouvelles suggestions)
    2: false, // Family
    3: true,  // Stories (nouveau)
    4: true,  // Timeline (nouveau)
  };
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _pageController = PageController(initialPage: 0, viewportFraction: 1.0);
    _animationController = AnimationController(
      duration: FamilyConnectTheme.normalDuration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: FamilyConnectTheme.bounceCurve,
    ));
    
    // Animation d'entrée initiale
    _animationController.forward();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshBadges();
    }
  }
  
  void _refreshBadges() {
    // Simuler la vérification des badges
    setState(() {
      _badgeStates[1] = true; // Search a de nouvelles suggestions
    });
  }
  
  void _onTabTapped(int index) {
    if (_isAnimating || index == _currentIndex) return;
    
    HapticFeedback.lightImpact();
    
    setState(() {
      _isAnimating = true;
      _currentIndex = index;
      
      // Marquer le badge comme vu
      if (_badgeStates[index] == true) {
        _badgeStates[index] = false;
      }
    });
    
    // Animation de transition
    _animationController.reset();
    _animationController.forward();
    
    _pageController.animateToPage(
      index,
      duration: FamilyConnectTheme.normalDuration,
      curve: FamilyConnectTheme.defaultCurve,
    ).then((_) {
      setState(() {
        _isAnimating = false;
      });
    });
  }
  
  void _onPageChanged(int index) {
    if (index != _currentIndex && !_isAnimating) {
      setState(() {
        _currentIndex = index;
      });
    }
  }
  
  /// Construire l'AppBar avec menu hamburger et profil
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Menu hamburger
          GestureDetector(
            onTap: _showMenuDrawer,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.menu,
                color: Theme.of(context).colorScheme.onSurface,
                size: 24,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Logo/Titre
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: FamilyConnectTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  'Family Connect',
                  style: FamilyConnectTheme.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Profil
          GestureDetector(
            onTap: _showProfileDrawer,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onSurface,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Afficher le menu drawer (gauche)
  void _showMenuDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                  const Expanded(
                    child: Text(
                      'Menu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            
            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildMenuItem(
                    icon: Icons.emoji_events,
                    title: 'Gamification',
                    subtitle: 'Points, badges et récompenses',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToScreen('gamification');
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  _buildMenuItem(
                    icon: Icons.person,
                    title: 'Profil',
                    subtitle: 'Gérer votre profil familial',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToScreen('profile');
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  _buildMenuItem(
                    icon: Icons.settings,
                    title: 'Paramètres',
                    subtitle: 'Préférences et configuration',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToScreen('settings');
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: 'Aide',
                    subtitle: 'Centre d\'aide et support',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToScreen('help');
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: 'À propos',
                    subtitle: 'Informations sur l\'application',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToScreen('about');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Afficher le profil drawer (droite)
  void _showProfileDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                  const Expanded(
                    child: Text(
                      'Profil',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            
            // Profil content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Avatar et infos
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: FamilyConnectTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Text(
                          'Utilisateur Test',
                          style: FamilyConnectTheme.h4.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          'temp_user_123',
                          style: FamilyConnectTheme.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Actions profil
                  _buildProfileAction(
                    icon: Icons.edit,
                    title: 'Modifier le profil',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToScreen('edit_profile');
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  _buildProfileAction(
                    icon: Icons.family_restroom,
                    title: 'Mon arbre généalogique',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToScreen('family_tree');
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  _buildProfileAction(
                    icon: Icons.logout,
                    title: 'Déconnexion',
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutDialog();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construire un item de menu
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FamilyConnectTheme.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: FamilyConnectTheme.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  /// Construire une action de profil
  Widget _buildProfileAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Text(
                title,
                style: FamilyConnectTheme.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  /// Naviguer vers un écran spécifique
  void _navigateToScreen(String screenName) {
    switch (screenName) {
      case 'gamification':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FamilyGamesScreen(),
          ),
        );
        break;
      case 'profile':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FamilyProfileScreen(),
          ),
        );
        break;
      case 'settings':
        // TODO: Créer SettingsScreen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paramètres bientôt disponibles')),
        );
        break;
      case 'help':
        // TODO: Créer HelpScreen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aide bientôt disponible')),
        );
        break;
      case 'about':
        // TODO: Créer AboutScreen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('À propos bientôt disponible')),
        );
        break;
      case 'edit_profile':
        // TODO: Créer EditProfileScreen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modification du profil bientôt disponible')),
        );
        break;
      case 'family_tree':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TreeScreen(racineId: 'root'),
          ),
        );
        break;
    }
  }

  /// Afficher la boîte de dialogue de déconnexion
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              nav.pop();
              await _authService.logout();
              if (mounted) {
                nav.pushNamedAndRemoveUntil('/landing', (route) => false);
              }
            },
            child: const Text('Se déconnecter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return ScaleTransition(
            scale: _scaleAnimation,
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildHomePage(),
                _buildSearchPage(),
                _buildFamilyPage(),
                _buildStoriesPage(),
                _buildTimelinePage(),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildModernBottomNavBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
  
  /// BottomNavigationBar moderne avec gradients et animations
  Widget _buildModernBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: FamilyConnectTheme.radiusLg,
            boxShadow: FamilyConnectTheme.shadowSm,
          ),
          child: ClipRRect(
            borderRadius: FamilyConnectTheme.radiusLg,
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedFontSize: 10,
              unselectedFontSize: 10,
              selectedLabelStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
              items: [
                _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Accueil',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.search_outlined,
                  activeIcon: Icons.search,
                  label: 'Rechercher',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  label: 'Famille',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.camera_alt_outlined,
                  activeIcon: Icons.camera_alt,
                  label: 'Stories',
                  index: 3,
                ),
                _buildNavItem(
                  icon: Icons.timeline_outlined,
                  activeIcon: Icons.timeline,
                  label: 'Timeline',
                  index: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Item de navigation personnalisé avec badge
  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final hasBadge = _badgeStates[index] == true;
    
    return BottomNavigationBarItem(
      icon: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: FamilyConnectTheme.radiusSm,
              color: isSelected 
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            ),
            child: Icon(
              icon,
              size: 24,
              color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (hasBadge && !isSelected)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
      activeIcon: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: FamilyConnectTheme.radiusSm,
              gradient: FamilyConnectTheme.primaryGradient,
            ),
            child: Icon(
              activeIcon,
              size: 24,
              color: Colors.white,
            ),
          ),
        ],
      ),
      label: label,
    );
  }
  
  /// FloatingActionButton moderne avec gradient
  Widget _buildFloatingActionButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: FamilyConnectTheme.primaryGradient,
        borderRadius: FamilyConnectTheme.radiusFull,
        boxShadow: FamilyConnectTheme.shadowLg,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: FamilyConnectTheme.radiusFull,
          onTap: () {
            HapticFeedback.mediumImpact();
            _showAddMenu();
          },
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
  
  /// Menu d'ajout rapide
  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddMenuSheet(),
    );
  }
  
  Widget _buildAddMenuSheet() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: FamilyConnectTheme.radiusLg,
        boxShadow: FamilyConnectTheme.shadowXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline,
              borderRadius: FamilyConnectTheme.radiusFull,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Ajouter à la famille',
                  style: FamilyConnectTheme.h4.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildAddOption(
                        icon: Icons.person_add,
                        label: 'Personne',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PersonFormScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildAddOption(
                        icon: Icons.favorite,
                        label: 'Union',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UnionFormScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAddOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: FamilyConnectTheme.radiusMd,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: FamilyConnectTheme.radiusMd,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: FamilyConnectTheme.secondaryGradient,
                  borderRadius: FamilyConnectTheme.radiusMd,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: FamilyConnectTheme.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Pages principales
  Widget _buildHomePage() {
    return const ModernHomeScreen();
  }
  
  Widget _buildSearchPage() {
    return const ModernSearchScreen();
  }
  
  Widget _buildFamilyPage() {
    return const FamilyProfileScreen();
  }
  
  Widget _buildStoriesPage() {
    return const FamilyStoriesScreen();
  }

  Widget _buildTimelinePage() {
    return const TimelineScreen();
  }
}
