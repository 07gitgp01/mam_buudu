import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../services/auth_local_service.dart';
import '../../services/sync_service.dart';
import '../../services/biometric_service.dart';
import '../../widgets/phone_picker_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  final _familleCodeCtrl = TextEditingController();
  final _familleSearchCtrl = TextEditingController();
  FamilleInfo? _familleSelectionnee;
  List<FamilleInfo> _familleSuggestions = [];
  bool _isSearchingFamille = false;

  // Tab 0 — email
  final _emailCtrl = TextEditingController();
  final _pwEmailCtrl = TextEditingController();
  bool _showPwEmail = false;

  // Tab 1 — téléphone
  String _phoneNumber = '';
  final _pwPhoneCtrl = TextEditingController();
  bool _showPwPhone = false;

  // Tab 2 — username
  final _usernameCtrl = TextEditingController();
  final _pwUsernameCtrl = TextEditingController();
  bool _showPwUsername = false;

  bool _isLoading = false;
  bool _showFamilleStep = true; // étape 1 = famille, étape 2 = identifiants

  final _familyFormKey = GlobalKey<FormState>();
  final _credFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _familleCodeCtrl.dispose();
    _familleSearchCtrl.dispose();
    _emailCtrl.dispose();
    _pwEmailCtrl.dispose();
    _pwPhoneCtrl.dispose();
    _usernameCtrl.dispose();
    _pwUsernameCtrl.dispose();
    super.dispose();
  }

  // ── Famille ───────────────────────────────────────────────────────────────

  Future<void> _onSearchChanged(String value) async {
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

  void _selectFamille(FamilleInfo f, {String? code}) {
    HapticFeedback.lightImpact();
    setState(() {
      _familleSelectionnee = f;
      _familleSearchCtrl.text = f.nom;
      _familleSuggestions = [];
      if (code != null) _familleCodeCtrl.text = code;
    });
  }

  Future<void> _verifierCode() async {
    final code = _familleCodeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _isLoading = true);
    final f = await ApiService.getFamilleByCode(code);
    if (mounted) setState(() => _isLoading = false);
    if (f != null) {
      _selectFamille(f, code: code);
    } else {
      _showErr('Code de famille introuvable');
    }
  }

  Future<void> _goToCredentials() async {
    if (!_familyFormKey.currentState!.validate()) return;
    final code = _familleCodeCtrl.text.trim().toUpperCase();
    if (_familleSelectionnee == null && code.isNotEmpty) {
      setState(() => _isLoading = true);
      final f = await ApiService.getFamilleByCode(code);
      if (mounted) setState(() => _isLoading = false);
      if (f == null) { _showErr('Code de famille introuvable'); return; }
      _selectFamille(f, code: code);
    } else if (_familleSelectionnee == null) {
      _showErr('Veuillez sélectionner ou saisir le code de votre famille');
      return;
    }
    setState(() => _showFamilleStep = false);
  }

  // ── Connexion ─────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_credFormKey.currentState!.validate()) return;

    final familleCode = _familleCodeCtrl.text.trim().toUpperCase();
    final tab = _tabCtrl.index;

    setState(() => _isLoading = true);

    final serverOk = await ApiService.isServerReachable();
    String? error;

    if (serverOk) {
      if (tab == 0) {
        error = await ApiService.login(
          familleCode: familleCode,
          password: _pwEmailCtrl.text,
          email: _emailCtrl.text.trim(),
        );
      } else if (tab == 1) {
        if (_phoneNumber.isEmpty) {
          setState(() => _isLoading = false);
          _showErr('Numéro de téléphone requis');
          return;
        }
        error = await ApiService.login(
          familleCode: familleCode,
          password: _pwPhoneCtrl.text,
          telephone: _phoneNumber,
        );
      } else {
        error = await ApiService.login(
          familleCode: familleCode,
          password: _pwUsernameCtrl.text,
          username: _usernameCtrl.text.trim(),
        );
      }
    } else {
      // Fallback hors-ligne (email uniquement)
      final local = AuthLocalService();
      final identifiant = tab == 0
          ? _emailCtrl.text.trim()
          : tab == 1 ? _phoneNumber : _usernameCtrl.text.trim();
      final pw = tab == 0 ? _pwEmailCtrl.text : tab == 1 ? _pwPhoneCtrl.text : _pwUsernameCtrl.text;
      final ok = await local.login(identifiant, pw);
      if (!ok) error = 'Identifiant ou mot de passe incorrect (mode hors-ligne)';
    }

    if (mounted) setState(() => _isLoading = false);
    if (error != null) { _showErr(error); return; }

    // Viewonly → pas de pull, pas de biométrie
    final viewonly = await ApiService.isViewonly();
    if (serverOk && !viewonly) {
      if (mounted) {
        setState(() => _isLoading = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chargement de vos données...'), duration: Duration(seconds: 10)),
        );
      }
      await SyncService().pullChanges();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        setState(() => _isLoading = false);
      }
    }

    if (!mounted) return;

    // Profil non complété → rediriger vers completion
    final profileComplete = await ApiService.hasCompletedProfile();
    if (!profileComplete && mounted) {
      Navigator.pushReplacementNamed(context, '/complete_profile');
      return;
    }

    if (!viewonly) await _offerBiometric();
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _offerBiometric() async {
    if (!await BiometricService.isAvailable()) return;
    if (await BiometricService.isEnabled()) return;
    if (!mounted) return;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Connexion par empreinte'),
        content: const Text(
          "Voulez-vous activer la connexion par empreinte digitale pour les prochaines ouvertures ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Plus tard')),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.fingerprint),
            label: const Text('Activer'),
          ),
        ],
      ),
    );

    if (accepted == true) {
      final ok = await BiometricService.authenticate(reason: 'Confirmez votre empreinte');
      if (ok) {
        await BiometricService.setEnabled(true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connexion par empreinte activée'), backgroundColor: Colors.green),
          );
        }
      }
    }
  }

  void _showErr(String msg) {
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
        leading: _showFamilleStep
            ? IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
            : IconButton(
                onPressed: () => setState(() => _showFamilleStep = true),
                icon: const Icon(Icons.arrow_back)),
        title: Text(_showFamilleStep ? 'Trouver ma famille' : 'Se connecter'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _showFamilleStep ? 0.5 : 1.0,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      ),
      body: _showFamilleStep ? _buildFamilleStep(theme) : _buildCredStep(theme),
    );
  }

  // ── Étape 1 : Famille ─────────────────────────────────────────────────────

  Widget _buildFamilleStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _familyFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Votre famille',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Recherchez votre famille par nom ou saisissez le code unique.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 32),

            // Recherche par nom
            Text('Rechercher par nom',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
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
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)))
                    : _familleSearchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() {
                              _familleSearchCtrl.clear();
                              _familleSuggestions = [];
                              _familleSelectionnee = null;
                            }),
                          )
                        : null,
              ),
              onChanged: _onSearchChanged,
            ),

            if (_familleSuggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                ),
                child: Column(
                  children: _familleSuggestions
                      .map((f) => ListTile(
                            leading: const Icon(Icons.family_restroom),
                            title: Text(f.nom),
                            subtitle: f.lieu != null ? Text(f.lieu!) : null,
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () => _selectFamille(f),
                          ))
                      .toList(),
                ),
              ),

            if (_familleSelectionnee != null && _familleSuggestions.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_familleSelectionnee!.nom,
                          style: TextStyle(
                              color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
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
            Row(children: [
              Expanded(child: Divider(color: theme.colorScheme.outline.withValues(alpha: 0.4))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('ou',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
              ),
              Expanded(child: Divider(color: theme.colorScheme.outline.withValues(alpha: 0.4))),
            ]),
            const SizedBox(height: 24),

            // Code unique
            Text('Saisir le code de la famille',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
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
                    if (_familleSelectionnee != null) setState(() => _familleSelectionnee = null);
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifierCode,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20)),
                child: _isLoading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Vérifier'),
              ),
            ]),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _goToCredentials,
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

  // ── Étape 2 : Identifiants (3 onglets) ───────────────────────────────────

  Widget _buildCredStep(ThemeData theme) {
    return Column(
      children: [
        // Famille sélectionnée
        if (_familleSelectionnee != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(Icons.family_restroom, color: theme.colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_familleSelectionnee!.nom,
                    style: TextStyle(
                        color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: () => setState(() => _showFamilleStep = true),
                child: const Text('Changer', style: TextStyle(fontSize: 12)),
              ),
            ]),
          ),

        TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.email_outlined), text: 'Email'),
            Tab(icon: Icon(Icons.phone_outlined), text: 'Téléphone'),
            Tab(icon: Icon(Icons.person_outlined), text: 'Username'),
          ],
        ),

        Expanded(
          child: Form(
            key: _credFormKey,
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildEmailTab(theme),
                _buildPhoneTab(theme),
                _buildUsernameTab(theme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Email *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (_tabCtrl.index != 0) return null;
              if (v == null || v.trim().isEmpty) return 'Email requis';
              if (!v.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _passwordField(controller: _pwEmailCtrl, show: _showPwEmail,
              onToggle: () => setState(() => _showPwEmail = !_showPwEmail), tabIndex: 0),
          _forgotPasswordLink(),
          _submitButton(),
        ],
      ),
    );
  }

  Widget _buildPhoneTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          PhonePickerField(
            label: 'Téléphone *',
            required: _tabCtrl.index == 1,
            onChanged: (v) => _phoneNumber = v,
          ),
          const SizedBox(height: 16),
          _passwordField(controller: _pwPhoneCtrl, show: _showPwPhone,
              onToggle: () => setState(() => _showPwPhone = !_showPwPhone), tabIndex: 1),
          _forgotPasswordLink(),
          _submitButton(),
        ],
      ),
    );
  }

  Widget _buildUsernameTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          TextFormField(
            controller: _usernameCtrl,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Nom d\'utilisateur *',
              hintText: 'ex: famille.bado ou accès viewonly',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outlined),
            ),
            validator: (v) {
              if (_tabCtrl.index != 2) return null;
              if (v == null || v.trim().isEmpty) return 'Nom d\'utilisateur requis';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _passwordField(controller: _pwUsernameCtrl, show: _showPwUsername,
              onToggle: () => setState(() => _showPwUsername = !_showPwUsername), tabIndex: 2),
          _forgotPasswordLink(),
          _submitButton(),
        ],
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required bool show,
    required VoidCallback onToggle,
    required int tabIndex,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      decoration: InputDecoration(
        labelText: 'Mot de passe *',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
      validator: (v) {
        if (_tabCtrl.index != tabIndex) return null;
        if (v == null || v.isEmpty) return 'Mot de passe requis';
        return null;
      },
    );
  }

  Widget _forgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _showResetDialog,
        child: const Text('Mot de passe oublié ?', style: TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _submitButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          child: _isLoading
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Se connecter'),
        ),
      ),
    );
  }

  // ── Reset password ────────────────────────────────────────────────────────

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
        builder: (ctx, setS) => AlertDialog(
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
                    validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        labelText: 'Question secrète', border: OutlineInputBorder()),
                    isExpanded: true,
                    items: questions
                        .map((q) => DropdownMenuItem(
                            value: q,
                            child: Text(q,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (v) => setS(() => question = v),
                    validator: (v) => v == null ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: reponseCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Réponse', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPwCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nouveau mot de passe', border: OutlineInputBorder()),
                    obscureText: true,
                    validator: (v) =>
                        (v == null || v.length < 8) ? 'Minimum 8 car.' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
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
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue current) =>
      current.copyWith(text: current.text.toUpperCase());
}
