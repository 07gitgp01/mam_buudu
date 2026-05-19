import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../services/auth_local_service.dart';
import '../../services/sync_service.dart';
import '../../services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isSearchingFamille = false;
  bool _passwordVisible = false;

  // Étape 1 — Famille
  final _familleCodeCtrl = TextEditingController();
  final _familleSearchCtrl = TextEditingController();
  FamilleInfo? _familleSelectionnee;
  List<FamilleInfo> _familleSuggestions = [];

  // Étape 2 — Identifiants
  final _identifiantCtrl = TextEditingController(); // email ou tel
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _familleCodeCtrl.dispose();
    _familleSearchCtrl.dispose();
    _identifiantCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Recherche famille ─────────────────────────────────────────────────────

  Future<void> _onSearchFamilleChanged(String value) async {
    if (value.trim().length < 2) {
      setState(() => _familleSuggestions = []);
      return;
    }
    setState(() => _isSearchingFamille = true);
    final results = await ApiService.searchFamilles(value.trim());
    if (mounted) {
      setState(() {
        _familleSuggestions = results;
        _isSearchingFamille = false;
      });
    }
  }

  Future<void> _onVerifierCode() async {
    final code = _familleCodeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _isLoading = true);
    final famille = await ApiService.getFamilleByCode(code);
    if (mounted) setState(() => _isLoading = false);
    if (famille != null) {
      _selectFamille(famille, code: code);
    } else {
      _showError('Code de famille introuvable');
    }
  }

  void _selectFamille(FamilleInfo famille, {String? code}) {
    HapticFeedback.lightImpact();
    setState(() {
      _familleSelectionnee = famille;
      _familleSearchCtrl.text = famille.nom;
      _familleSuggestions = [];
      if (code != null) _familleCodeCtrl.text = code;
    });
  }

  // ── Navigation entre étapes ───────────────────────────────────────────────

  Future<void> _nextStep() async {
    if (!_formKey1.currentState!.validate()) return;

    // Si code saisi mais famille pas encore vérifiée
    final code = _familleCodeCtrl.text.trim().toUpperCase();
    if (_familleSelectionnee == null && code.isNotEmpty) {
      setState(() => _isLoading = true);
      final famille = await ApiService.getFamilleByCode(code);
      if (mounted) setState(() => _isLoading = false);
      if (famille == null) {
        _showError('Code de famille introuvable');
        return;
      }
      _selectFamille(famille, code: code);
    } else if (_familleSelectionnee == null) {
      _showError('Veuillez sélectionner ou saisir le code de votre famille');
      return;
    }

    setState(() => _currentStep = 1);
    _pageController.animateToPage(1,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _prevStep() {
    setState(() => _currentStep = 0);
    _pageController.animateToPage(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  // ── Connexion ─────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey2.currentState!.validate()) return;
    if (_familleSelectionnee == null && _familleCodeCtrl.text.trim().isEmpty) {
      _prevStep();
      return;
    }

    setState(() => _isLoading = true);

    final familleCode = _familleCodeCtrl.text.trim().toUpperCase();
    final identifiant = _identifiantCtrl.text.trim();
    final password = _passwordCtrl.text;

    final serverOk = await ApiService.isServerReachable();
    String? error;

    if (serverOk) {
      error = await ApiService.login(
        familleCode: familleCode,
        identifiant: identifiant,
        password: password,
      );
    } else {
      // Fallback hors-ligne (connexion locale par email)
      final local = AuthLocalService();
      final ok = await local.login(identifiant, password);
      if (!ok) error = 'Identifiant ou mot de passe incorrect (mode hors-ligne)';
    }

    if (mounted) setState(() => _isLoading = false);
    if (error != null) { _showError(error); return; }

    // Pull des données de la famille depuis le serveur avant d'afficher l'app
    if (serverOk) {
      if (mounted) {
        setState(() => _isLoading = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chargement de vos données...'),
            duration: Duration(seconds: 10),
          ),
        );
      }
      await SyncService().pullChanges();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        setState(() => _isLoading = false);
      }
    }

    if (!mounted) return;
    await _offerBiometricIfAvailable();
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  /// Propose d'activer la connexion par empreinte si disponible et pas encore activée
  Future<void> _offerBiometricIfAvailable() async {
    final available = await BiometricService.isAvailable();
    if (!available) return;

    final alreadyEnabled = await BiometricService.isEnabled();
    if (alreadyEnabled) return;

    if (!mounted) return;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Connexion par empreinte'),
        content: const Text(
          'Voulez-vous activer la connexion par empreinte digitale pour les prochaines ouvertures de l\'application ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Plus tard'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.fingerprint),
            label: const Text('Activer'),
          ),
        ],
      ),
    );

    if (accepted == true) {
      // Vérifier que ça marche vraiment avant d'activer
      final verified = await BiometricService.authenticate(
        reason: 'Confirmez votre empreinte pour activer cette fonctionnalité',
      );
      if (verified) {
        await BiometricService.setEnabled(true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connexion par empreinte activée'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
            : IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close)),
        title: Text(_currentStep == 0 ? 'Trouver ma famille' : 'Se connecter'),
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

  // ── Étape 1 : Rechercher / saisir le code famille ─────────────────────────

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
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Recherchez votre famille par son nom ou saisissez le code unique.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 32),

            // ── Recherche par nom ───────────────────────────────────────────
            Text('Rechercher par nom',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _familleSearchCtrl,
              decoration: InputDecoration(
                hintText: 'Nom de la famille...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearchingFamille
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : (_familleSearchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _familleSearchCtrl.clear();
                              setState(() {
                                _familleSuggestions = [];
                                _familleSelectionnee = null;
                              });
                            },
                          )
                        : null),
              ),
              onChanged: _onSearchFamilleChanged,
            ),

            // Suggestions
            if (_familleSuggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8)
                  ],
                ),
                child: Column(
                  children: _familleSuggestions
                      .map((f) => ListTile(
                            leading: const Icon(Icons.family_restroom),
                            title: Text(f.nom),
                            subtitle: f.lieu != null ? Text(f.lieu!) : null,
                            trailing: const Icon(Icons.arrow_forward_ios,
                                size: 14),
                            onTap: () => _selectFamille(f),
                          ))
                      .toList(),
                ),
              ),

            // Famille sélectionnée
            if (_familleSelectionnee != null && _familleSuggestions.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_familleSelectionnee!.nom,
                              style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600)),
                          if (_familleSelectionnee!.lieu != null)
                            Text(_familleSelectionnee!.lieu!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() {
                        _familleSelectionnee = null;
                        _familleSearchCtrl.clear();
                        _familleCodeCtrl.clear();
                      }),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Divider(color: theme.colorScheme.outline.withValues(alpha: 0.4))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('ou',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5))),
                ),
                Expanded(child: Divider(color: theme.colorScheme.outline.withValues(alpha: 0.4))),
              ],
            ),
            const SizedBox(height: 24),

            // ── Code unique ─────────────────────────────────────────────────
            Text('Saisir le code de la famille',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _familleCodeCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ex: TRAORE2024',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                      _UpperCaseFormatter(),
                    ],
                    onChanged: (_) {
                      if (_familleSelectionnee != null) {
                        setState(() => _familleSelectionnee = null);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _onVerifierCode,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20)),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Vérifier'),
                ),
              ],
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Continuer →'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                child: const Text('Créer une nouvelle famille'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Étape 2 : Identifiants ────────────────────────────────────────────────

  Widget _buildStep2(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Récap famille
            if (_familleSelectionnee != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.family_restroom,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _familleSelectionnee!.nom,
                        style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: _prevStep,
                      child: const Text('Changer'),
                    ),
                  ],
                ),
              ),

            Text('Vos identifiants',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Email ou numéro de téléphone associé à votre compte.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 32),

            TextFormField(
              controller: _identifiantCtrl,
              decoration: const InputDecoration(
                labelText: 'Email ou Téléphone *',
                hintText: 'exemple@mail.com ou +226 70 00 00 00',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Email ou téléphone requis';
                }
                return null;
              },
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
                  (v == null || v.isEmpty) ? 'Mot de passe requis' : null,
            ),
            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showResetDialog,
                child: const Text('Mot de passe oublié ?'),
              ),
            ),
            const SizedBox(height: 32),

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
                    : const Text('Se connecter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Réinitialisation mot de passe ─────────────────────────────────────────

  void _showResetDialog() {
    final emailCtrl = TextEditingController();
    String? question;
    final reponseCtrl = TextEditingController();
    final newPwCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    const questions = [
      'Quel est le nom de votre premier animal de compagnie ?',
      'Dans quelle ville êtes-vous né(e) ?',
      'Quel est le nom de votre professeur préféré ?',
      'Quelle est votre couleur préférée ?',
      'Quel est le plat préféré de votre enfance ?',
      "Quel est le nom de votre meilleure amie d'enfance ?",
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Réinitialiser le mot de passe'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Email', border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        labelText: 'Question secrète',
                        border: OutlineInputBorder()),
                    initialValue: question,
                    isExpanded: true,
                    items: questions
                        .map((q) => DropdownMenuItem(
                            value: q,
                            child: Text(q,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (v) => setDialogState(() => question = v),
                    validator: (v) => v == null ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: reponseCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Réponse', border: OutlineInputBorder()),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPwCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nouveau mot de passe',
                        border: OutlineInputBorder()),
                    obscureText: true,
                    validator: (v) =>
                        (v == null || v.length < 8) ? 'Minimum 8 car.' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate() || question == null) return;
                Navigator.pop(ctx);
                final err = await ApiService.resetPassword(
                  email: emailCtrl.text.trim(),
                  questionSecrete: question!,
                  reponseSecrete: reponseCtrl.text.trim(),
                  newPassword: newPwCtrl.text,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(err ?? 'Mot de passe réinitialisé'),
                    backgroundColor: err != null ? Colors.red : Colors.green,
                  ));
                }
              },
              child: const Text('Réinitialiser'),
            ),
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
