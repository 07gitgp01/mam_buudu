import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/personne_repository.dart';
import '../../models/personne.dart';
import '../../services/api_service.dart';
import 'create_membre_screen.dart';

class MembresAdminScreen extends StatefulWidget {
  const MembresAdminScreen({super.key});

  @override
  State<MembresAdminScreen> createState() => _MembresAdminScreenState();
}

class _MembresAdminScreenState extends State<MembresAdminScreen> {
  final _repo = PersonneRepository();

  /// Membres avec compte login (depuis API)
  List<Map<String, dynamic>> _membres = [];
  /// Toutes les personnes de l'arbre (depuis SQLite)
  List<Personne> _personnes = [];

  bool _isLoading = true;
  String? _error;
  String _myUserId = '';
  String _myRole = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _isLoading = true; _error = null; });

    final prefs = await SharedPreferences.getInstance();
    _myUserId = prefs.getString('api_user_id') ?? '';
    _myRole   = prefs.getString('api_user_role') ?? '';

    try {
      final results = await Future.wait([
        ApiService.getFamilleMembers(),
        _repo.getAll(),
      ]);
      if (mounted) {
        setState(() {
          _membres   = results[0] as List<Map<String, dynamic>>;
          _personnes = (results[1] as List<Personne>)
            ..sort((a, b) => a.nomComplet.compareTo(b.nomComplet));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  bool get _canManage => _myRole == 'admin' || _myRole == 'gestionnaire';

  /// personneIds déjà liés à un compte
  Set<String> get _personnesWithAccount {
    final ids = <String>{};
    for (final m in _membres) {
      final pid = m['personneId'] as String?;
      if (pid != null) ids.add(pid);
    }
    return ids;
  }

  // ── Changer le rôle ──────────────────────────────────────────────────────────

  Future<void> _changeRole(Map<String, dynamic> membre) async {
    final rawUser = membre['user'];
    if (rawUser == null) return;
    final user   = Map<String, dynamic>.from(rawUser as Map);
    final userId = user['id'] as String;
    final role   = membre['role'] as String? ?? 'membre';
    final nom    = '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim();

    if (role == 'admin' || userId == _myUserId) return;

    final newRole  = role == 'gestionnaire' ? 'membre' : 'gestionnaire';
    final newLabel = newRole == 'gestionnaire' ? 'Gestionnaire' : 'Membre';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Changer le rôle'),
        content: Text(
          'Passer $nom en $newLabel ?\n\n'
          '${newRole == 'gestionnaire'
              ? 'Il/Elle pourra créer et modifier des données.'
              : 'Il/Elle ne pourra plus modifier les données.'}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Passer en $newLabel')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    final err = await ApiService.changeMemberRole(userId: userId, role: newRole);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
      setState(() => _isLoading = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$nom est maintenant $newLabel'), backgroundColor: Colors.green),
      );
      _load();
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Membres (${_personnes.length})'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(theme)
              : _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final withAccount    = _personnesWithAccount;
    final avecCompte     = _membres; // membres avec compte (certains liés à une personne)
    final sansCompte     = _personnes.where((p) => !withAccount.contains(p.id)).toList();

    final items = <Widget>[];

    // ── Section : comptes login ──────────────────────────────────────────────
    if (avecCompte.isNotEmpty) {
      items.add(_sectionHeader(theme, Icons.verified_user_outlined, 'Comptes actifs', avecCompte.length));
      for (final m in avecCompte) {
        // Trouver la Personne liée si disponible
        final pid      = m['personneId'] as String?;
        final personne = pid != null
            ? _personnes.where((p) => p.id == pid).firstOrNull
            : null;
        items.add(_buildMembreTile(theme, m, personne));
      }
    }

    // ── Section : membres sans compte ────────────────────────────────────────
    if (sansCompte.isNotEmpty) {
      items.add(_sectionHeader(theme, Icons.person_outline, 'Sans compte', sansCompte.length,
          subtitle: 'Créez un compte pour leur donner accès à l\'app'));
      for (final p in sansCompte) {
        items.add(_buildSansCompteTile(theme, p));
      }
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('Aucun membre dans l\'arbre', style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: items,
    );
  }

  Widget _sectionHeader(ThemeData theme, IconData icon, String title, int count, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text('$title ($count)',
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(width: 6),
            Expanded(child: Text(subtitle,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              overflow: TextOverflow.ellipsis)),
          ],
        ],
      ),
    );
  }

  // ── Tuile membre avec compte ─────────────────────────────────────────────────

  Widget _buildMembreTile(ThemeData theme, Map<String, dynamic> membre, Personne? personne) {
    final rawUser = membre['user'];
    if (rawUser == null) return const SizedBox.shrink();
    final user   = Map<String, dynamic>.from(rawUser as Map);
    final userId = user['id'] as String;
    final role   = membre['role'] as String? ?? 'membre';
    final nom    = personne?.nomComplet.isNotEmpty == true
        ? personne!.nomComplet
        : '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim();
    final email  = user['email'] as String? ?? '';
    final isMe   = userId == _myUserId;
    final isAdmin = role == 'admin';

    final initials = nom.isNotEmpty ? nom[0].toUpperCase() : '?';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
          child: Text(initials,
            style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        ),
        title: Row(children: [
          Expanded(child: Text(nom, style: const TextStyle(fontWeight: FontWeight.w600))),
          if (isMe) _Chip(label: 'Moi',
            bg: theme.colorScheme.secondary.withValues(alpha: 0.15), fg: theme.colorScheme.secondary),
        ]),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (email.isNotEmpty) Text(email, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          _RoleBadge(role: role),
        ]),
        trailing: (_canManage && !isAdmin && !isMe)
            ? _roleButton(membre, role)
            : null,
      ),
    );
  }

  Widget _roleButton(Map<String, dynamic> membre, String role) {
    final isGest = role == 'gestionnaire';
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: isGest ? Colors.orange.shade700 : Colors.green.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      onPressed: () => _changeRole(membre),
      icon: Icon(isGest ? Icons.arrow_downward : Icons.arrow_upward, size: 16),
      label: Text(isGest ? 'Membre' : 'Gestionnaire',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  // ── Tuile membre SANS compte ─────────────────────────────────────────────────

  Widget _buildSansCompteTile(ThemeData theme, Personne p) {
    final initials = p.nomComplet.isNotEmpty ? p.nomComplet[0].toUpperCase() : '?';
    final sexeColor = p.sexe == 'M' ? Colors.blue.shade300
        : p.sexe == 'F' ? Colors.pink.shade300
        : theme.colorScheme.outline;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: sexeColor.withValues(alpha: 0.2),
          child: Text(initials, style: TextStyle(fontWeight: FontWeight.bold, color: sexeColor)),
        ),
        title: Text(p.nomComplet, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (p.datesAffichage.isNotEmpty) Text(p.datesAffichage, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          _RoleBadge(role: 'membre', muted: true),
        ]),
        trailing: _canManage
            ? FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                onPressed: () => _openCreateCompte(p),
                child: const Text('Créer compte'),
              )
            : Icon(Icons.lock_outline, size: 18, color: theme.colorScheme.outline),
      ),
    );
  }

  Future<void> _openCreateCompte(Personne p) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateMembreScreen(personne: p)),
    );
    if (created == true) _load();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _buildError(ThemeData theme) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
      ]),
    ),
  );
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final String role;
  final bool muted;
  const _RoleBadge({required this.role, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final Color bg, fg;
    final String label;
    switch (role) {
      case 'admin':
        bg = Colors.red.shade50; fg = Colors.red.shade700; label = 'Administrateur';
      case 'gestionnaire':
        bg = Colors.orange.shade50; fg = Colors.orange.shade800; label = 'Gestionnaire';
      default:
        bg = muted
            ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);
        fg = muted
            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
            : Theme.of(context).colorScheme.primary;
        label = 'Membre';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg, fg;
  const _Chip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 6),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
    child: Text(label, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
  );
}
