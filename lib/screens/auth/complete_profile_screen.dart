import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/phone_picker_field.dart';

/// Affiché lors de la première connexion d'un compte créé par l'admin.
/// Le membre saisit sa question secrète et sa réponse (obligatoire),
/// et peut optionnellement ajouter email ou téléphone manquants.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionCtrl = TextEditingController();
  final _reponseCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _showReponse = false;
  String _phoneNumber = '';
  bool _saving = false;

  @override
  void dispose() {
    _questionCtrl.dispose();
    _reponseCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final error = await ApiService.completeProfile(
      questionSecrete: _questionCtrl.text.trim(),
      reponseSecrete: _reponseCtrl.text.trim(),
      telephone: _phoneNumber.isNotEmpty ? _phoneNumber : null,
      email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compléter votre profil'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Explication
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bienvenue ! Avant de continuer, définissez une question secrète '
                        'pour pouvoir récupérer votre compte si vous oubliez votre mot de passe.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.8)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              _sectionLabel(theme, Icons.lock_outline, 'Question secrète (obligatoire)'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _questionCtrl,
                decoration: _deco('Ma question secrète *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Question requise' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _reponseCtrl,
                obscureText: !_showReponse,
                decoration: _deco('Ma réponse secrète *').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                        _showReponse ? Icons.visibility_off : Icons.visibility),
                    onPressed: () =>
                        setState(() => _showReponse = !_showReponse),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Réponse requise' : null,
              ),

              const SizedBox(height: 32),

              _sectionLabel(
                  theme, Icons.contact_phone_outlined, 'Coordonnées (optionnel)'),
              const SizedBox(height: 4),
              Text(
                'Ajoutez un email ou un autre numéro si vous souhaitez pouvoir vous '
                'connecter avec ces identifiants également.',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
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

              PhonePickerField(
                label: 'Téléphone supplémentaire (optionnel)',
                onChanged: (v) => _phoneNumber = v,
              ),

              const SizedBox(height: 40),

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
                      : const Text('Enregistrer et continuer',
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

  Widget _sectionLabel(ThemeData theme, IconData icon, String text) =>
      Row(children: [
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
