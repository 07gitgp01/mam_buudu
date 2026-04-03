import 'package:flutter/material.dart';

class MultiSelectChip<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) displayName;
  final List<T> selected;
  final Function(List<T>) onChanged;
  final String? label;
  final bool allowEmptySelection;

  const MultiSelectChip({
    super.key,
    required this.items,
    required this.displayName,
    required this.selected,
    required this.onChanged,
    this.label,
    this.allowEmptySelection = true,
  });

  @override
  State<MultiSelectChip<T>> createState() => _MultiSelectChipState<T>();
}

class _MultiSelectChipState<T> extends State<MultiSelectChip<T>> {
  late List<T> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selected);
  }

  @override
  void didUpdateWidget(MultiSelectChip<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      setState(() {
        _selectedItems = List.from(widget.selected);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Affichage des chips sélectionnés
        if (_selectedItems.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _selectedItems.map((item) {
              return Chip(
                label: Text(widget.displayName(item)),
                onDeleted: widget.allowEmptySelection
                    ? () => _removeItem(item)
                    : null,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                deleteIcon: widget.allowEmptySelection
                    ? const Icon(Icons.close, size: 18)
                    : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        
        // Bouton pour ajouter/voir tous les items
        ActionChip(
          avatar: const Icon(Icons.add),
          label: Text(_selectedItems.isEmpty 
              ? 'Sélectionner' 
              : 'Modifier la sélection (${_selectedItems.length})'),
          onPressed: _showSelectionDialog,
        ),
        
        // Message d'erreur si aucune sélection
        if (!widget.allowEmptySelection && _selectedItems.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Veuillez sélectionner au moins un élément',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  void _removeItem(T item) {
    setState(() {
      _selectedItems.remove(item);
    });
    widget.onChanged(_selectedItems);
  }

  void _showSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => _SelectionDialog<T>(
        items: widget.items,
        displayName: widget.displayName,
        selected: _selectedItems,
        allowEmptySelection: widget.allowEmptySelection,
        onSelectionChanged: (selected) {
          setState(() {
            _selectedItems = selected;
          });
          widget.onChanged(selected);
        },
      ),
    );
  }
}

class _SelectionDialog<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) displayName;
  final List<T> selected;
  final bool allowEmptySelection;
  final Function(List<T>) onSelectionChanged;

  const _SelectionDialog({
    required this.items,
    required this.displayName,
    required this.selected,
    required this.allowEmptySelection,
    required this.onSelectionChanged,
  });

  @override
  State<_SelectionDialog<T>> createState() => _SelectionDialogState<T>();
}

class _SelectionDialogState<T> extends State<_SelectionDialog<T>> {
  late List<T> _selectedItems;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selected);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<T> get _filteredItems {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return widget.items;
    
    return widget.items.where((item) {
      final name = widget.displayName(item).toLowerCase();
      return name.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.selected.isEmpty ? 'Sélectionner' : 'Modifier la sélection'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // Barre de recherche
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Liste des items
            Expanded(
              child: ListView.builder(
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  final isSelected = _selectedItems.contains(item);
                  
                  return CheckboxListTile(
                    title: Text(widget.displayName(item)),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedItems.add(item);
                        } else {
                          _selectedItems.remove(item);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: widget.allowEmptySelection || _selectedItems.isNotEmpty
              ? () {
                  widget.onSelectionChanged(_selectedItems);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
