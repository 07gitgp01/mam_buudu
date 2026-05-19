import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../services/auth_local_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _codeAutoGenere = true;

  // Étape 1 — Famille
  final _nomFamilleCtrl = TextEditingController();
  final _codeUniqueCtrl = TextEditingController();
  final _lieuCtrl = TextEditingController();

  // Étape 2 — Administrateur
  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  String? _questionSecrete;
  final _reponseSecreteCtrl = TextEditingController();

  static const List<String> _questions = [
    'Quel est le nom de votre premier animal de compagnie ?',
    'Dans quelle ville êtes-vous né(e) ?',
    'Quel est le nom de votre professeur préféré ?',
    'Quelle est votre couleur préférée ?',
    'Quel est le plat préféré de votre enfance ?',
    "Quel est le nom de votre meilleure amie d'enfance ?",
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nomFamilleCtrl.dispose();
    _codeUniqueCtrl.dispose();
    _lieuCtrl.dispose();
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _telephoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _reponseSecreteCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (!_formKey1.currentState!.validate()) return;
    setState(() => _currentStep = 1);
    _pageController.animateToPage(1,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _prevStep() {
    setState(() => _currentStep = 0);
    _pageController.animateToPage(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _submit() async {
    if (!_formKey2.currentState!.validate()) return;
    if (_questionSecrete == null) {
      _showError('Veuillez choisir une question secrète');
      return;
    }

    setState(() => _isLoading = true);

    final serverOk = await ApiService.isServerReachable();
    String? error;

    if (serverOk) {
      error = await ApiService.register(
        nomFamille: _nomFamilleCtrl.text.trim(),
        codeUnique: _codeAutoGenere ? null : _codeUniqueCtrl.text.trim().toUpperCase(),
        lieu: _lieuCtrl.text.trim().isEmpty ? null : _lieuCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        telephone: _telephoneCtrl.text.trim().isEmpty ? null : _telephoneCtrl.text.trim(),
        password: _passwordCtrl.text,
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        questionSecrete: _questionSecrete!,
        reponseSecrete: _reponseSecreteCtrl.text.trim(),
      );
      // Sauvegarde locale aussi pour mode hors-ligne
      if (error == null) {
        final local = AuthLocalService();
        await local.register(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          nom: _nomCtrl.text.trim(),
          prenom: _prenomCtrl.text.trim(),
          questionSecrete: _questionSecrete!,
          reponseSecrete: _reponseSecreteCtrl.text.trim(),
        );
      }
    } else {
      final local = AuthLocalService();
      final registered = await local.register(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        questionSecrete: _questionSecrete!,
        reponseSecrete: _reponseSecreteCtrl.text.trim(),
      );
      if (!registered) {
        error = 'Impossible de créer le compte hors-ligne';
      } else {
        final loggedIn = await local.login(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
        if (!loggedIn) error = 'Erreur lors de la connexion hors-ligne';
      }
    }

    if (mounted) setState(() => _isLoading = false);
    if (error != null) { _showError(error); return; }
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep == 1
            ? IconButton(onPressed: _prevStep, icon: const Icon(Icons.arrow_back))
            : IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        title: Text(_currentStep == 0 ? 'Créer une famille' : 'Votre compte admin'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 2,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep1(theme),
          _buildStep2(theme),
        ],
      ),
    );
  }

  // ── Étape 1 : Informations famille ───────────────────────────────────────────

  Widget _buildStep1(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Votre famille',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Ces informations permettront aux membres de retrouver votre famille lors de la connexion.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 32),

            TextFormField(
              controller: _nomFamilleCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom de la famille *',
                hintText: 'Ex: Famille Traoré, Clan Diallo...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.family_restroom),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nom de famille requis' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _lieuCtrl,
              decoration: const InputDecoration(
                labelText: 'Lieu (ville, pays)',
                hintText: 'Ex: Ouagadougou, Burkina Faso',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),

            Text("Code d'accès famille",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Les membres utiliseront ce code pour se connecter à votre famille.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildToggleButton(
                    label: 'Auto-généré',
                    icon: Icons.auto_fix_high,
                    selected: _codeAutoGenere,
                    onTap: () => setState(() => _codeAutoGenere = true),
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildToggleButton(
                    label: 'Je le choisis',
                    icon: Icons.edit_outlined,
                    selected: !_codeAutoGenere,
                    onTap: () => setState(() => _codeAutoGenere = false),
                    theme: theme,
                  ),
                ),
              ],
            ),

            if (!_codeAutoGenere) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeUniqueCtrl,
                decoration: InputDecoration(
                  labelText: 'Code personnalisé *',
                  hintText: 'Ex: TRAORE2024',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  helperText: 'Lettres et chiffres, 4 à 12 caractères',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.casino_outlined),
                    tooltip: 'Générer un code',
                    onPressed: _generateRandomCode,
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  _UpperCaseFormatter(),
                ],
                validator: (v) {
                  if (_codeAutoGenere) return null;
                  if (v == null || v.trim().length < 4) return 'Minimum 4 caractères';
                  if (v.trim().length > 12) return 'Maximum 12 caractères';
                  return null;
                },
              ),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Un code unique sera généré automatiquement et affiché après la création.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Continuer →'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Déjà un compte ? Se connecter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    final code = List.generate(6, (i) => chars[(now ~/ (i + 1)) % chars.length]).join();
    setState(() => _codeUniqueCtrl.text = code);
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Étape 2 : Compte administrateur ──────────────────────────────────────────

  Widget _buildStep2(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Votre compte',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Vous serez l\'administrateur de "${_nomFamilleCtrl.text}".',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prenomCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Prénom *', border: OutlineInputBorder()),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _nomCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nom *', border: OutlineInputBorder()),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email requis';
                if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim())) {
                  return 'Email invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _telephoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Téléphone (optionnel)',
                hintText: '+226 70 00 00 00',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _passwordCtrl,
              decoration: InputDecoration(
                labelText: 'Mot de passe *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                      _passwordVisible ? Icons.visibility_off : Icons.visibility),
                  onPressed: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                ),
              ),
              obscureText: !_passwordVisible,
              validator: (v) =>
                  (v == null || v.length < 8) ? 'Minimum 8 caractères' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _confirmPasswordCtrl,
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outlined),
              ),
              obscureText: true,
              validator: (v) => v != _passwordCtrl.text
                  ? 'Les mots de passe ne correspondent pas'
                  : null,
            ),
            const SizedBox(height: 24),

            Text('Sécurité du compte',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Question secrète *',
                border: OutlineInputBorder(),
              ),
              initialValue: _questionSecrete,
              isExpanded: true,
              items: _questions
                  .map((q) => DropdownMenuItem(
                      value: q,
                      child: Text(q,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() => _questionSecrete = v),
              validator: (v) => v == null ? 'Choisissez une question' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _reponseSecreteCtrl,
              decoration: const InputDecoration(
                labelText: 'Réponse secrète *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Réponse requise' : null,
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Créer la famille'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue current) {
    return current.copyWith(text: current.text.toUpperCase());
  }
}
