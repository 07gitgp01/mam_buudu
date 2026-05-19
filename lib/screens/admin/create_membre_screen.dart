import 'package:flutter/material.dart';
import '../../models/personne.dart';
import '../../services/api_service.dart';
import '../../widgets/phone_picker_field.dart';

class CreateMembreScreen extends StatefulWidget {
  /// Liste des personnes sans compte parmi lesquelles choisir.
  final List<Personne> sansCompte;

  const CreateMembreScreen({super.key, required this.sansCompte});

  @override
  State<CreateMembreScreen> createState() => _CreateMembreScreenState();
}

class _CreateMembreScreenState extends State<CreateMembreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  Personne? _selected;
  String _phoneNumber = '';
  String _role = 'membre';
  bool _saving = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner un membre'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Numéro de téléphone requis'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _saving = true);

    final p = _selected!;
    final nom = p.nomNaissance ?? p.nomUsage ?? '';
    final prenom = p.prenoms ?? '';

    final error = await ApiService.createMembre(
      telephone: _phoneNumber,
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      nom: nom,
      prenom: prenom,
      role: _role,
      personneId: p.id,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau compte')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Sélection du membre ──────────────────────────────────────
              _label(theme, Icons.person_outline, 'Choisir le membre'),
              const SizedBox(height: 10),
              _MemberSelector(
                personnes: widget.sansCompte,
                selected: _selected,
                onChanged: (p) => setState(() => _selected = p),
              ),

              const SizedBox(height: 24),

              // ── Rôle ────────────────────────────────────────────────────
              _label(theme, Icons.shield_outlined, 'Rôle initial'),
              const SizedBox(height: 10),
              _RoleSelector(value: _role, onChanged: (v) => setState(() => _role = v)),

              const SizedBox(height: 24),

              // ── Identifiants de connexion ────────────────────────────────
              _label(theme, Icons.login_outlined, 'Identifiants de connexion'),
              const SizedBox(height: 4),
              Text(
                'Le membre pourra compléter son profil après sa première connexion.',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),

              PhonePickerField(
                label: 'Téléphone *',
                required: true,
                onChanged: (v) => _phoneNumber = v,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _deco('Email (optionnel)'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (!v.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _passwordCtrl,
                obscureText: !_showPassword,
                decoration: _deco('Mot de passe *').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.length < 8) ? 'Minimum 8 caractères' : null,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Créer le compte',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(ThemeData theme, IconData icon, String text) => Row(children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(text,
            style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700)),
      ]);

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}

// ── Sélecteur de membre ───────────────────────────────────────────────────────

class _MemberSelector extends StatelessWidget {
  final List<Personne> personnes;
  final Personne? selected;
  final ValueChanged<Personne?> onChanged;

  const _MemberSelector({
    required this.personnes,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (personnes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Tous les membres ont déjà un compte.',
          style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      );
    }

    return DropdownButtonFormField<Personne>(
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintText: 'Sélectionner un membre',
      ),
      items: personnes
          .map((p) => DropdownMenuItem(
                value: p,
                child: Row(children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.12),
                    child: Text(
                      p.nomComplet.isNotEmpty
                          ? p.nomComplet[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(p.nomComplet,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis),
                        if (p.datesAffichage.isNotEmpty)
                          Text(p.datesAffichage,
                              style: theme.textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ]),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ── Sélecteur de rôle ────────────────────────────────────────────────────────

class _RoleSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _RoleSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(children: [
        _Option(
          label: 'Membre',
          desc: 'Consulte uniquement',
          icon: Icons.person_outline,
          role: 'membre',
          selected: value == 'membre',
          color: Theme.of(context).colorScheme.primary,
          onTap: () => onChanged('membre'),
        ),
        const SizedBox(width: 12),
        _Option(
          label: 'Gestionnaire',
          desc: 'Peut modifier',
          icon: Icons.manage_accounts_outlined,
          role: 'gestionnaire',
          selected: value == 'gestionnaire',
          color: Colors.orange.shade700,
          onTap: () => onChanged('gestionnaire'),
        ),
      ]);
}

class _Option extends StatelessWidget {
  final String label, desc, role;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _Option({
    required this.label,
    required this.desc,
    required this.icon,
    required this.role,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? color
                    : Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon,
                    size: 20,
                    color: selected
                        ? color
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4)),
                const SizedBox(height: 8),
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? color
                            : Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(desc,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6))),
              ],
            ),
          ),
        ),
      );
}
