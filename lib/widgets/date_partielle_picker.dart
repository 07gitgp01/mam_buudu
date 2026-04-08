import 'package:flutter/material.dart';
import '../models/date_partielle.dart';

class DatePartiellePicker extends StatefulWidget {
  final DatePartielle? initialValue;
  final ValueChanged<DatePartielle?> onChanged;
  final String? hintText;

  const DatePartiellePicker({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.hintText,
  });

  @override
  State<DatePartiellePicker> createState() => _DatePartiellePickerState();
}

class _DatePartiellePickerState extends State<DatePartiellePicker> {
  late TextEditingController _controller;
  DatePartielle? _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _controller = TextEditingController(
      text: _currentValue?.toDisplayString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      readOnly: true,
      decoration: InputDecoration(
        hintText: widget.hintText ?? 'Sélectionner une date',
        suffixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
      ),
      onTap: () => _showDatePicker(context),
    );
  }

  void _showDatePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sélectionner une date'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Choisissez le mode de sélection :'),
                const SizedBox(height: 16),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showNativeDatePicker(context);
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Calendrier'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showManualDatePicker(context);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Manuel'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  void _showNativeDatePicker(BuildContext context) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _currentValue != null 
            ? DateTime(_currentValue!.annee, _currentValue!.mois ?? 1, _currentValue!.jour ?? 1)
            : DateTime.now(),
        firstDate: DateTime(1800),
        lastDate: DateTime.now().add(const Duration(days: 365 * 50)),
        locale: const Locale('fr', 'FR'),
        helpText: 'Sélectionner une date',
        cancelText: 'Annuler',
        confirmText: 'Valider',
        fieldLabelText: 'Date',
        fieldHintText: 'JJ/MM/AAAA',
      );

      if (picked != null) {
        final date = DatePartielle(
          annee: picked.year,
          mois: picked.month,
          jour: picked.day,
        );
        
        setState(() {
          _currentValue = date;
          _controller.text = date.toDisplayString();
        });
        widget.onChanged(date);
      }
    } catch (e) {
      print('Error in showDatePicker: $e');
      // Fallback vers le mode manuel si le DatePicker échoue
      _showManualDatePicker(context);
    }
  }

  void _showManualDatePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return DatePartielleDialog(
          initialValue: _currentValue,
          dialogContext: dialogContext,
          onDateSelected: (date) {
            // D'abord mettre à jour l'état local
            setState(() {
              _currentValue = date;
              _controller.text = date?.toDisplayString() ?? '';
            });
            // Ensuite appeler le callback du parent
            widget.onChanged(date);
            // Le dialogue sera fermé par le _validateDate
          },
        );
      },
    );
  }
}

class DatePartielleDialog extends StatefulWidget {
  final DatePartielle? initialValue;
  final ValueChanged<DatePartielle?> onDateSelected;
  final BuildContext? dialogContext;

  const DatePartielleDialog({
    super.key,
    this.initialValue,
    required this.onDateSelected,
    this.dialogContext,
  });

  @override
  State<DatePartielleDialog> createState() => _DatePartielleDialogState();
}

class _DatePartielleDialogState extends State<DatePartielleDialog> {
  late int _year;
  int? _month;
  int? _day;
  bool _yearOnly = false;
  bool _monthOnly = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _year = widget.initialValue!.annee;
      _month = widget.initialValue!.mois;
      _day = widget.initialValue!.jour;
      
      _yearOnly = (_month == null && _day == null);
      _monthOnly = (_month != null && _day == null);
    } else {
      _year = DateTime.now().year;
    }
  }

  List<int> get _daysInMonth {
    if (_month == null) return [];
    
    final year = _year;
    final month = _month!;
    
    if (month == 2) {
      // Vérifier année bissextile
      if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
        return List.generate(29, (index) => index + 1);
      } else {
        return List.generate(28, (index) => index + 1);
      }
    } else if ([4, 6, 9, 11].contains(month)) {
      return List.generate(30, (index) => index + 1);
    } else {
      return List.generate(31, (index) => index + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sélectionner une date'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Année
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Année',
                border: OutlineInputBorder(),
              ),
              initialValue: _year.toString(),
              onChanged: (value) {
                final year = int.tryParse(value);
                if (year != null && year > 0) {
                  setState(() {
                    _year = year;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Checkbox pour année seulement
            CheckboxListTile(
              title: const Text('Année seulement'),
              value: _yearOnly,
              onChanged: (value) {
                setState(() {
                  _yearOnly = value ?? false;
                  if (_yearOnly) {
                    _monthOnly = false;
                    _month = null;
                    _day = null;
                  }
                });
              },
            ),
            
            // Mois
            if (!_yearOnly) ...[
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Mois',
                  border: OutlineInputBorder(),
                ),
                initialValue: _month,
                items: List.generate(12, (index) {
                  final monthNames = [
                    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
                    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
                  ];
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text(monthNames[index]),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    _month = value;
                    if (value != null && _day != null && _day! > _daysInMonth.length) {
                      _day = _daysInMonth.length;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Checkbox pour mois seulement
              CheckboxListTile(
                title: const Text('Mois seulement'),
                value: _monthOnly,
                onChanged: (value) {
                  setState(() {
                    _monthOnly = value ?? false;
                    if (_monthOnly) {
                      _day = null;
                    }
                  });
                },
              ),
            ],
            
            // Jour
            if (!_yearOnly && _month != null && !_monthOnly) ...[
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Jour',
                  border: OutlineInputBorder(),
                ),
                initialValue: _day,
                items: _daysInMonth.map((day) {
                  return DropdownMenuItem(
                    value: day,
                    child: Text('$day'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _day = value;
                  });
                },
              ),
            ],
          ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: _clearDate,
          child: const Text('Effacer'),
        ),
        ElevatedButton(
          onPressed: _validateDate,
          child: const Text('Valider'),
        ),
      ],
    );
  }

  void _clearDate() {
    widget.onDateSelected(null);
    Navigator.of(context).pop();
  }

  void _validateDate() {
    print('=== VALIDATE DATE ===');
    print('Year: $_year, Month: $_month, Day: $_day');
    print('Year only: $_yearOnly, Month only: $_monthOnly');
    
    try {
      print('Creating DatePartielle...');
      final date = DatePartielle(
        annee: _year,
        mois: _month,
        jour: _day,
      );
      print('DatePartielle created successfully: $date');
      
      print('Calling onDateSelected...');
      widget.onDateSelected(date);
      print('onDateSelected called');
      
      print('Popping dialog...');
      if (widget.dialogContext != null) {
        Navigator.of(widget.dialogContext!).pop();
        print('Dialog popped with specific context');
      } else {
        Navigator.of(context).pop();
        print('Dialog popped with default context');
      }
    } catch (e) {
      print('ERROR in _validateDate: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
      // NE PAS faire Navigator.pop() en cas d'erreur
    }
    print('=== END VALIDATE DATE ===');
  }
}
