import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/family_connect_theme.dart';
import '../models/timeline_event.dart';
import '../services/timeline_service.dart';
import '../widgets/timeline_widgets.dart';

/// Écran principal de la timeline familiale
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen>
    with TickerProviderStateMixin {
  final TimelineService _timelineService = TimelineService();
  List<TimelineEvent> _events = [];
  List<TimelineEvent> _filteredEvents = [];
  bool _isLoading = true;
  TimelineFilter _currentFilter = TimelineFilter.none;
  
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  late AnimationController _filterController;
  late Animation<double> _filterAnimation;
  
  bool _showFilters = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeTimeline();
    _initAnimations();
  }

  void _initAnimations() {
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeOut),
    );
    
    _filterController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _filterController, curve: Curves.easeOut),
    );
    
    _fabController.forward();
  }

  Future<void> _initializeTimeline() async {
    try {
      await _timelineService.initialize();
      
      _timelineService.eventsStream.listen((events) {
        if (mounted) {
          setState(() {
            _events = events;
            _filteredEvents = _timelineService.filterEvents(_currentFilter);
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement de la timeline: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const TimelineLoadingIndicator()
          : _buildTimelineContent(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Timeline Familiale'),
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _toggleFilters,
          icon: AnimatedIcon(
            icon: AnimatedIcons.search_ellipsis,
            progress: _filterAnimation,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        IconButton(
          onPressed: _showStats,
          icon: const Icon(Icons.bar_chart),
        ),
      ],
    );
  }

  Widget _buildTimelineContent() {
    return Column(
      children: [
        // Filtres
        AnimatedBuilder(
          animation: _filterAnimation,
          builder: (context, child) {
            return SizeTransition(
              sizeFactor: _filterAnimation,
              child: _buildFilterSection(),
            );
          },
        ),
        
        // Contenu principal
        Expanded(
          child: _filteredEvents.isEmpty
              ? _buildEmptyState()
              : _buildTimelineList(),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres',
            style: FamilyConnectTheme.h4.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          
          // Filtres par type
          Text(
            'Type d\'événement',
            style: FamilyConnectTheme.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TimelineEventType.values.map((type) {
              final isSelected = _currentFilter.eventTypes?.contains(type) ?? false;
              return TimelineFilterChip(
                label: _getEventTypeLabel(type),
                isSelected: isSelected,
                onTap: () => _toggleEventTypeFilter(type),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Filtres par importance
          Text(
            'Importance',
            style: FamilyConnectTheme.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TimelineEventImportance.values.map((importance) {
              final isSelected = _currentFilter.importanceLevels?.contains(importance) ?? false;
              return TimelineFilterChip(
                label: _getImportanceLabel(importance),
                isSelected: isSelected,
                onTap: () => _toggleImportanceFilter(importance),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Effacer les filtres'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineList() {
    return RefreshIndicator(
      onRefresh: _refreshTimeline,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: _filteredEvents.length,
        itemBuilder: (context, index) {
          final event = _filteredEvents[index];
          return TimelineEventCard(
            event: event,
            onTap: () => _viewEventDetails(event),
            onReact: (eventId) => _addReaction(eventId),
            onComment: (eventId) => _showComments(eventId),
            onEdit: () => _editEvent(event),
            onDelete: () => _deleteEvent(event),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timeline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _currentFilter.isEmpty 
                ? 'Aucun événement dans la timeline'
                : 'Aucun événement trouvé avec ces filtres',
            style: FamilyConnectTheme.h4.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentFilter.isEmpty
                ? 'Soyez le premier à ajouter un événement !'
                : 'Essayez d\'ajuster les filtres',
            style: FamilyConnectTheme.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (_currentFilter.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createEvent,
              icon: const Icon(Icons.add),
              label: const Text('Créer un événement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: _createEvent,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Événement'),
            elevation: 4,
          ),
        );
      },
    );
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
    
    if (_showFilters) {
      _filterController.forward();
    } else {
      _filterController.reverse();
    }
  }

  void _toggleEventTypeFilter(TimelineEventType type) {
    final currentTypes = _currentFilter.eventTypes ?? [];
    final updatedTypes = List<TimelineEventType>.from(currentTypes);
    
    if (updatedTypes.contains(type)) {
      updatedTypes.remove(type);
    } else {
      updatedTypes.add(type);
    }
    
    setState(() {
      _currentFilter = _currentFilter.copyWith(eventTypes: updatedTypes);
    });
  }

  void _toggleImportanceFilter(TimelineEventImportance importance) {
    final currentImportances = _currentFilter.importanceLevels ?? [];
    final updatedImportances = List<TimelineEventImportance>.from(currentImportances);
    
    if (updatedImportances.contains(importance)) {
      updatedImportances.remove(importance);
    } else {
      updatedImportances.add(importance);
    }
    
    setState(() {
      _currentFilter = _currentFilter.copyWith(importanceLevels: updatedImportances);
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredEvents = _timelineService.filterEvents(_currentFilter);
    });
    _toggleFilters();
  }

  void _clearFilters() {
    setState(() {
      _currentFilter = TimelineFilter.none;
      _filteredEvents = _events;
    });
  }

  void _createEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateEventScreen(),
      ),
    );
  }

  void _viewEventDetails(TimelineEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(event: event),
      ),
    );
  }

  void _addReaction(String eventId) async {
    // Pour l'instant, on utilise un emoji par défaut
    final success = await _timelineService.addReaction(eventId, '\u2764\ufe0f');
    if (success) {
      HapticFeedback.lightImpact();
    }
  }

  void _showComments(String eventId) {
    final event = _events.firstWhere((e) => e.id == eventId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventCommentsScreen(event: event),
      ),
    );
  }

  void _editEvent(TimelineEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventScreen(event: event),
      ),
    );
  }

  void _deleteEvent(TimelineEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'événement'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${event.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _timelineService.deleteEvent(event.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Événement supprimé'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showStats() {
    final stats = _timelineService.getTimelineStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques de la Timeline'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total événements: ${stats['totalEvents']}'),
              Text('Avec médias: ${stats['eventsWithMedia']}'),
              Text('Réactions totales: ${stats['totalReactions']}'),
              Text('Commentaires totaux: ${stats['totalComments']}'),
              Text('Vues totales: ${stats['totalViews']}'),
              const SizedBox(height: 16),
              Text(
                'Moyennes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Réactions/événement: ${stats['averageReactionsPerEvent'].toStringAsFixed(1)}'),
              Text('Commentaires/événement: ${stats['averageCommentsPerEvent'].toStringAsFixed(1)}'),
              Text('Vues/événement: ${stats['averageViewsPerEvent'].toStringAsFixed(1)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshTimeline() async {
    // Forcer le rechargement
    setState(() {
      _isLoading = true;
    });
    
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _isLoading = false;
    });
  }

  String _getEventTypeLabel(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.birth:
        return 'Naissance';
      case TimelineEventType.marriage:
        return 'Mariage';
      case TimelineEventType.death:
        return 'Décès';
      case TimelineEventType.anniversary:
        return 'Anniversaire';
      case TimelineEventType.graduation:
        return 'Diplôme';
      case TimelineEventType.career:
        return 'Carrière';
      case TimelineEventType.travel:
        return 'Voyage';
      case TimelineEventType.achievement:
        return 'Réussite';
      case TimelineEventType.familyGathering:
        return 'Réunion';
      case TimelineEventType.custom:
        return 'Personnalisé';
    }
  }

  String _getImportanceLabel(TimelineEventImportance importance) {
    switch (importance) {
      case TimelineEventImportance.low:
        return 'Faible';
      case TimelineEventImportance.medium:
        return 'Moyenne';
      case TimelineEventImportance.high:
        return 'Haute';
      case TimelineEventImportance.critical:
        return 'Critique';
    }
  }

  @override
  void dispose() {
    _fabController.dispose();
    _filterController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

/// Écran de création d'événement
class CreateEventScreen extends StatefulWidget {
  final TimelineEvent? event; // Pour l'édition

  const CreateEventScreen({super.key, this.event});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final TimelineService _timelineService = TimelineService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagsController = TextEditingController();
  
  TimelineEventType _selectedType = TimelineEventType.custom;
  TimelineEventImportance _selectedImportance = TimelineEventImportance.medium;
  TimelineEventVisibility _selectedVisibility = TimelineEventVisibility.public;
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedEndDate;
  List<String> _selectedMedia = [];
  List<String> _selectedTags = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _initializeFromEvent();
    }
  }

  void _initializeFromEvent() {
    final event = widget.event!;
    _titleController.text = event.title;
    _descriptionController.text = event.description;
    _locationController.text = event.location ?? '';
    _selectedType = event.type;
    _selectedImportance = event.importance;
    _selectedVisibility = event.visibility;
    _selectedDate = event.eventDate;
    _selectedEndDate = event.endDate;
    _selectedMedia = List.from(event.mediaUrls);
    _selectedTags = List.from(event.tags);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.event != null ? 'Modifier l\'événement' : 'Créer un événement'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          else
            TextButton(
              onPressed: _saveEvent,
              child: Text(
                'Enregistrer',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type d'événement
            _buildSectionTitle('Type d\'événement'),
            _buildEventTypeSelector(),
            
            const SizedBox(height: 24),
            
            // Informations de base
            _buildSectionTitle('Informations'),
            _buildTextField(
              controller: _titleController,
              label: 'Titre',
              required: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _locationController,
              label: 'Localisation',
              icon: Icons.location_on,
            ),
            
            const SizedBox(height: 24),
            
            // Dates
            _buildSectionTitle('Dates'),
            _buildDateSelector(),
            
            const SizedBox(height: 24),
            
            // Importance et visibilité
            _buildSectionTitle('Paramètres'),
            _buildImportanceSelector(),
            const SizedBox(height: 16),
            _buildVisibilitySelector(),
            
            const SizedBox(height: 24),
            
            // Médias
            _buildSectionTitle('Médias'),
            _buildMediaSection(),
            
            const SizedBox(height: 24),
            
            // Tags
            _buildSectionTitle('Tags'),
            _buildTagsSection(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: FamilyConnectTheme.h4.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildEventTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TimelineEventType.values.map((type) {
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _getEventTypeLabel(type),
              style: FamilyConnectTheme.bodySmall.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool required = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      children: [
        // Date de début
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Date de l\'événement'),
          subtitle: Text(_formatDate(_selectedDate)),
          trailing: const Icon(Icons.chevron_right),
          onTap: _selectStartDate,
        ),
        
        // Date de fin (optionnelle)
        ListTile(
          leading: const Icon(Icons.event),
          title: const Text('Date de fin (optionnel)'),
          subtitle: Text(_selectedEndDate != null ? _formatDate(_selectedEndDate!) : 'Non définie'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _selectEndDate,
        ),
      ],
    );
  }

  Widget _buildImportanceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Importance',
          style: FamilyConnectTheme.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: TimelineEventImportance.values.map((importance) {
            final isSelected = _selectedImportance == importance;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedImportance = importance),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _getImportanceColor(importance)
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? _getImportanceColor(importance)
                          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _getImportanceLabel(importance),
                    style: FamilyConnectTheme.bodySmall.copyWith(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVisibilitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visibilité',
          style: FamilyConnectTheme.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: TimelineEventVisibility.values.map((visibility) {
            final isSelected = _selectedVisibility == visibility;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedVisibility = visibility),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _getVisibilityLabel(visibility),
                    style: FamilyConnectTheme.bodySmall.copyWith(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMediaSection() {
    return Column(
      children: [
        // Médias existants
        if (_selectedMedia.isNotEmpty)
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedMedia.length,
              itemBuilder: (context, index) {
                final mediaUrl = _selectedMedia[index];
                return Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.surfaceVariant,
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildMediaWidget(mediaUrl),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMedia.removeAt(index)),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        
        const SizedBox(height: 12),
        
        // Bouton d'ajout
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addPhotoFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Photo'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addPhotoFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Galerie'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      children: [
        // Tags existants
        if (_selectedTags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _selectedTags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#$tag',
                      style: FamilyConnectTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() => _selectedTags.remove(tag)),
                      child: Icon(
                        Icons.close,
                        size: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        
        const SizedBox(height: 12),
        
        // Champ d'ajout de tags
        TextField(
          controller: _tagsController,
          decoration: InputDecoration(
            labelText: 'Ajouter un tag',
            prefixText: '#',
            suffixIcon: IconButton(
              onPressed: _addTag,
              icon: const Icon(Icons.add),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (_) => _addTag(),
        ),
      ],
    );
  }

  Widget _buildMediaWidget(String mediaUrl) {
    if (mediaUrl.startsWith('http')) {
      return Image.network(
        mediaUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Icon(
              Icons.broken_image,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        },
      );
    } else {
      return Image.file(
        File(mediaUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Icon(
              Icons.broken_image,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        },
      );
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? _selectedDate,
      firstDate: _selectedDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    
    if (date != null) {
      setState(() {
        _selectedEndDate = date;
      });
    }
  }

  Future<void> _addPhotoFromCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedMedia.add(photo.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _addPhotoFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedMedia.add(photo.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
        _tagsController.clear();
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le titre est obligatoire'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      
      if (widget.event != null) {
        // Mise à jour
        success = await _timelineService.updateEvent(
          widget.event!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _selectedType,
          eventDate: _selectedDate,
          endDate: _selectedEndDate,
          location: _locationController.text.trim().isEmpty 
              ? null 
              : _locationController.text.trim(),
          mediaUrls: _selectedMedia,
          tags: _selectedTags,
          importance: _selectedImportance,
          visibility: _selectedVisibility,
        );
      } else {
        // Création
        final event = await _timelineService.createEvent(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _selectedType,
          eventDate: _selectedDate,
          endDate: _selectedEndDate,
          location: _locationController.text.trim().isEmpty 
              ? null 
              : _locationController.text.trim(),
          mediaUrls: _selectedMedia,
          tags: _selectedTags,
          importance: _selectedImportance,
          visibility: _selectedVisibility,
        );
        success = event != null;
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.event != null 
                ? 'Événement mis à jour !' 
                : 'Événement créé !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getEventTypeLabel(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.birth:
        return 'Naissance';
      case TimelineEventType.marriage:
        return 'Mariage';
      case TimelineEventType.death:
        return 'Décès';
      case TimelineEventType.anniversary:
        return 'Anniversaire';
      case TimelineEventType.graduation:
        return 'Diplôme';
      case TimelineEventType.career:
        return 'Carrière';
      case TimelineEventType.travel:
        return 'Voyage';
      case TimelineEventType.achievement:
        return 'Réussite';
      case TimelineEventType.familyGathering:
        return 'Réunion';
      case TimelineEventType.custom:
        return 'Personnalisé';
    }
  }

  String _getImportanceLabel(TimelineEventImportance importance) {
    switch (importance) {
      case TimelineEventImportance.low:
        return 'Faible';
      case TimelineEventImportance.medium:
        return 'Moyenne';
      case TimelineEventImportance.high:
        return 'Haute';
      case TimelineEventImportance.critical:
        return 'Critique';
    }
  }

  String _getVisibilityLabel(TimelineEventVisibility visibility) {
    switch (visibility) {
      case TimelineEventVisibility.public:
        return 'Public';
      case TimelineEventVisibility.private:
        return 'Privé';
      case TimelineEventVisibility.custom:
        return 'Personnalisé';
    }
  }

  Color _getImportanceColor(TimelineEventImportance importance) {
    switch (importance) {
      case TimelineEventImportance.low:
        return Colors.grey;
      case TimelineEventImportance.medium:
        return Colors.blue;
      case TimelineEventImportance.high:
        return Colors.orange;
      case TimelineEventImportance.critical:
        return Colors.red;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}

/// Écran de détails d'événement
class EventDetailsScreen extends StatelessWidget {
  final TimelineEvent event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(event.title),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Médias
            if (event.mediaUrls.isNotEmpty)
              Container(
                height: 200,
                child: PageView.builder(
                  itemCount: event.mediaUrls.length,
                  itemBuilder: (context, index) {
                    final mediaUrl = event.mediaUrls[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildMediaWidget(mediaUrl),
                      ),
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Informations principales
            Text(
              event.title,
              style: FamilyConnectTheme.h4.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              event.description,
              style: FamilyConnectTheme.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Métadonnées
            _buildMetadataItem(
              context,
              'Type',
              _getEventTypeLabel(event.type),
              Icons.category,
            ),
            
            _buildMetadataItem(
              context,
              'Date',
              _formatDate(event.eventDate),
              Icons.calendar_today,
            ),
            
            if (event.location != null)
              _buildMetadataItem(
                context,
                'Localisation',
                event.location!,
                Icons.location_on,
              ),
            
            _buildMetadataItem(
              context,
              'Importance',
              _getImportanceLabel(event.importance),
              Icons.priority_high,
            ),
            
            const SizedBox(height: 24),
            
            // Tags
            if (event.tags.isNotEmpty) ...[
              Text(
                'Tags',
                style: FamilyConnectTheme.h4.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: event.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: event.color?.withValues(alpha: 0.1) ?? 
                             event.defaultColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#$tag',
                      style: FamilyConnectTheme.bodySmall.copyWith(
                        color: event.color ?? event.defaultColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
            
            // Statistiques
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Réactions',
                    event.reactions.length.toString(),
                    Icons.favorite,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Commentaires',
                    event.comments.length.toString(),
                    Icons.chat_bubble,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Vues',
                    event.viewCount.toString(),
                    Icons.visibility,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: FamilyConnectTheme.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  value,
                  style: FamilyConnectTheme.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: FamilyConnectTheme.h4.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: FamilyConnectTheme.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaWidget(String mediaUrl) {
    if (mediaUrl.startsWith('http')) {
      return Image.network(
        mediaUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Icon(
              Icons.broken_image,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        },
      );
    } else {
      return Image.file(
        File(mediaUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Icon(
              Icons.broken_image,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        },
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getEventTypeLabel(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.birth:
        return 'Naissance';
      case TimelineEventType.marriage:
        return 'Mariage';
      case TimelineEventType.death:
        return 'Décès';
      case TimelineEventType.anniversary:
        return 'Anniversaire';
      case TimelineEventType.graduation:
        return 'Diplôme';
      case TimelineEventType.career:
        return 'Carrière';
      case TimelineEventType.travel:
        return 'Voyage';
      case TimelineEventType.achievement:
        return 'Réussite';
      case TimelineEventType.familyGathering:
        return 'Réunion';
      case TimelineEventType.custom:
        return 'Personnalisé';
    }
  }

  String _getImportanceLabel(TimelineEventImportance importance) {
    switch (importance) {
      case TimelineEventImportance.low:
        return 'Faible';
      case TimelineEventImportance.medium:
        return 'Moyenne';
      case TimelineEventImportance.high:
        return 'Haute';
      case TimelineEventImportance.critical:
        return 'Critique';
    }
  }
}

/// Écran des commentaires d'événement
class EventCommentsScreen extends StatefulWidget {
  final TimelineEvent event;

  const EventCommentsScreen({super.key, required this.event});

  @override
  State<EventCommentsScreen> createState() => _EventCommentsScreenState();
}

class _EventCommentsScreenState extends State<EventCommentsScreen> {
  final TimelineService _timelineService = TimelineService();
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('Commentaires (${widget.event.comments.length})'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Liste des commentaires
          Expanded(
            child: widget.event.comments.isEmpty
                ? Center(
                    child: Text(
                      'Soyez le premier à commenter !',
                      style: FamilyConnectTheme.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.event.comments.length,
                    itemBuilder: (context, index) {
                      final comment = widget.event.comments[index];
                      return _buildCommentCard(comment);
                    },
                  ),
          ),
          
          // Champ d'ajout de commentaire
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Ajouter un commentaire...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : _addComment,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(TimelineComment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du commentaire
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: comment.userAvatar != null
                    ? ClipOval(
                        child: Image.file(
                          File(comment.userAvatar!),
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.userName,
                      style: FamilyConnectTheme.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      comment.timeAgo,
                      style: FamilyConnectTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Contenu du commentaire
          Text(
            comment.content,
            style: FamilyConnectTheme.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          
          // Réponses
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...comment.replies.map((reply) => _buildReplyCard(reply)),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyCard(TimelineComment reply) {
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                child: reply.userAvatar != null
                    ? ClipOval(
                        child: Image.file(
                          File(reply.userAvatar!),
                          fit: BoxFit.cover,
                          width: 32,
                          height: 32,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply.userName,
                      style: FamilyConnectTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      reply.timeAgo,
                      style: FamilyConnectTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            reply.content,
            style: FamilyConnectTheme.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _timelineService.addComment(widget.event.id, content);
      if (success && mounted) {
        _commentController.clear();
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
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

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
