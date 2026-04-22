import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/family_connect_theme.dart';
import 'enhanced_search_bar.dart';

/// Écran de recherche moderne avec suggestions IA
class ModernSearchScreen extends StatefulWidget {
  const ModernSearchScreen({super.key});

  @override
  State<ModernSearchScreen> createState() => _ModernSearchScreenState();
}

class _ModernSearchScreenState extends State<ModernSearchScreen>
    with TickerProviderStateMixin {
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  List<String> _recentSearches = [
    'Marie Dupont',
    'Jean Martin',
    'Sophie Bernard',
  ];
  
  List<String> _suggestions = [
    'Rechercher par nom',
    'Rechercher par date',
    'Rechercher par lieu',
    'Rechercher par relation',
  ];
  
  bool _isSearching = false;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: FamilyConnectTheme.normalDuration,
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: FamilyConnectTheme.fastDuration,
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: FamilyConnectTheme.defaultCurve,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: FamilyConnectTheme.defaultCurve,
    ));
    
    _slideController.forward();
    _fadeController.forward();
    
    _searchFocusNode.requestFocus();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _isSearching = value.isNotEmpty;
    });
    
    // Simuler la recherche avec délai
    if (value.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            // Mettre à jour les suggestions basées sur la recherche
          });
        }
      });
    }
  }
  
  void _onSearchSubmitted(String value) {
    HapticFeedback.lightImpact();
    if (value.isNotEmpty) {
      _addToRecentSearches(value);
      // Effectuer la recherche
    }
  }
  
  void _addToRecentSearches(String query) {
    setState(() {
      if (_recentSearches.contains(query)) {
        _recentSearches.remove(query);
      }
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
    });
  }
  
  void _clearRecentSearches() {
    HapticFeedback.lightImpact();
    setState(() {
      _recentSearches.clear();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: FamilyConnectTheme.normalDuration,
                child: _isSearching ? _buildSearchResults() : _buildSearchSuggestions(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchHeader() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: EnhancedSearchBar(
                hintText: 'Rechercher une personne...',
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                onSubmitted: _onSearchSubmitted,
                autofocus: true,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: IconButton(
                    onPressed: _searchQuery.isNotEmpty ? _clearSearch : null,
                    icon: Icon(
                      Icons.clear,
                      color: _searchQuery.isNotEmpty 
                        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchSuggestions() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchFilters(),
            const SizedBox(height: 24),
            _buildRecentSearches(),
            const SizedBox(height: 24),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtres de recherche',
          style: FamilyConnectTheme.h4.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestions.map((suggestion) {
            return _buildFilterChip(suggestion);
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildFilterChip(String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _searchController.text = label;
          _onSearchSubmitted(label);
        },
        borderRadius: FamilyConnectTheme.radiusSm,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: FamilyConnectTheme.secondaryGradient,
            borderRadius: FamilyConnectTheme.radiusSm,
          ),
          child: Text(
            label,
            style: FamilyConnectTheme.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recherches récentes',
              style: FamilyConnectTheme.h4.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: _clearRecentSearches,
              child: Text(
                'Effacer',
                style: FamilyConnectTheme.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._recentSearches.map((search) {
          return _buildRecentSearchItem(search);
        }).toList(),
      ],
    );
  }
  
  Widget _buildRecentSearchItem(String search) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _searchController.text = search;
          _onSearchSubmitted(search);
        },
        borderRadius: FamilyConnectTheme.radiusSm,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: FamilyConnectTheme.radiusSm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.history,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  search,
                  style: FamilyConnectTheme.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: FamilyConnectTheme.h4.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildQuickActionCard(
              icon: Icons.family_restroom,
              label: 'Famille directe',
              color: FamilyConnectTheme.primaryGradient,
              onTap: () {
                HapticFeedback.mediumImpact();
                // Naviguer vers famille directe
              },
            ),
            _buildQuickActionCard(
              icon: Icons.public,
              label: 'Par lieu',
              color: FamilyConnectTheme.secondaryGradient,
              onTap: () {
                HapticFeedback.mediumImpact();
                // Naviguer vers recherche par lieu
              },
            ),
            _buildQuickActionCard(
              icon: Icons.calendar_today,
              label: 'Par date',
              color: FamilyConnectTheme.accentGradient,
              onTap: () {
                HapticFeedback.mediumImpact();
                // Naviguer vers recherche par date
              },
            ),
            _buildQuickActionCard(
              icon: Icons.star,
              label: 'Favoris',
              color: LinearGradient(
                colors: [
                  const Color(0xFFFFD700),
                  const Color(0xFFFFA500),
                ],
              ),
              onTap: () {
                HapticFeedback.mediumImpact();
                // Naviguer vers favoris
              },
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required LinearGradient color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: FamilyConnectTheme.radiusMd,
        child: Container(
          decoration: BoxDecoration(
            gradient: color,
            borderRadius: FamilyConnectTheme.radiusMd,
            boxShadow: FamilyConnectTheme.shadowSm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: FamilyConnectTheme.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSearchResults() {
    // Placeholder pour les résultats de recherche
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Recherche pour "$_searchQuery"',
            style: FamilyConnectTheme.h4.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun résultat trouvé',
                    style: FamilyConnectTheme.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _clearSearch() {
    HapticFeedback.lightImpact();
    _searchController.clear();
    _onSearchChanged('');
  }
}
