import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CountryCode {
  final String flag;
  final String name;
  final String dial;
  const CountryCode({required this.flag, required this.name, required this.dial});
}

const List<CountryCode> kPhoneCountries = [
  CountryCode(flag: '🇧🇫', name: 'Burkina Faso', dial: '+226'),
  CountryCode(flag: '🇲🇱', name: 'Mali', dial: '+223'),
  CountryCode(flag: '🇳🇪', name: 'Niger', dial: '+227'),
  CountryCode(flag: '🇬🇦', name: 'Gabon', dial: '+241'),
  CountryCode(flag: '🇨🇦', name: 'Canada', dial: '+1'),
  CountryCode(flag: '🇹🇬', name: 'Togo', dial: '+228'),
];

/// Champ téléphone avec sélecteur de pays (BF, Mali, Niger, Gabon, Canada, Togo).
/// [onChanged] est appelé à chaque modification avec le numéro complet (indicatif + chiffres).
class PhonePickerField extends StatefulWidget {
  final String label;
  final bool required;
  final ValueChanged<String>? onChanged;
  final String? initialValue;

  const PhonePickerField({
    super.key,
    this.label = 'Téléphone',
    this.required = false,
    this.onChanged,
    this.initialValue,
  });

  @override
  State<PhonePickerField> createState() => _PhonePickerFieldState();
}

class _PhonePickerFieldState extends State<PhonePickerField> {
  CountryCode _country = kPhoneCountries.first;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _ctrl.text = widget.initialValue!;
    }
    _ctrl.addListener(_notifyParent);
  }

  void _notifyParent() {
    final digits = _ctrl.text.trim();
    final full = digits.isEmpty ? '' : '${_country.dial}$digits';
    widget.onChanged?.call(full);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_notifyParent);
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickCountry() async {
    final result = await showModalBottomSheet<CountryCode>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CountrySheet(selected: _country),
    );
    if (result != null && result.dial != _country.dial) {
      setState(() => _country = result);
      _notifyParent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: _ctrl,
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: widget.label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: GestureDetector(
          onTap: _pickCountry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_country.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 4),
                Text(_country.dial,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Icon(Icons.arrow_drop_down, size: 16),
              ],
            ),
          ),
        ),
      ),
      validator: widget.required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Téléphone requis' : null
          : null,
    );
  }
}

class _CountrySheet extends StatelessWidget {
  final CountryCode selected;
  const _CountrySheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Text('Sélectionner un pays',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...kPhoneCountries.map((c) => ListTile(
              leading: Text(c.flag, style: const TextStyle(fontSize: 26)),
              title: Text(c.name),
              trailing: Text(c.dial,
                  style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600)),
              selected: c.dial == selected.dial,
              selectedTileColor:
                  theme.colorScheme.primary.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              onTap: () => Navigator.pop(context, c),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}
