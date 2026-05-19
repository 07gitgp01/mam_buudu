import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';

/// Résultat d'une recherche de famille
class FamilleInfo {
  final String id;
  final String nom;
  final String? lieu;
  const FamilleInfo({required this.id, required this.nom, this.lieu});
  factory FamilleInfo.fromJson(Map<String, dynamic> j) =>
      FamilleInfo(id: j['id'] as String, nom: j['nom'] as String, lieu: j['lieu'] as String?);
}

class ApiService {
  static const String _baseUrl = 'http://10.10.0.34:3000';
  static const Duration _timeout = Duration(seconds: 15);

  // ── Token JWT ────────────────────────────────────────────────────────────────

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', token);
  }

  /// Vérifie si le token existe et que la session n'a pas expiré (< 1 jour)
  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null) return false;
    final expiry = prefs.getInt('api_session_expiry');
    if (expiry == null) return false;
    return DateTime.now().millisecondsSinceEpoch < expiry;
  }

  static Future<void> clearToken() async {
    await DatabaseHelper.instance.clearFamilyData();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_token');
    await prefs.remove('api_famille_id');
    await prefs.remove('api_user_id');
    await prefs.remove('api_user_role');
    await prefs.remove('api_session_expiry');
    await prefs.remove('api_user_nom');
    await prefs.remove('api_user_prenom');
    await prefs.remove('api_user_email');
    await prefs.remove('api_user_telephone');
    await prefs.remove('api_famille_nom');
    await prefs.remove('api_famille_code');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<void> _saveSession(Map<String, dynamic> body) async {
    await saveToken(body['token'] as String);
    final prefs = await SharedPreferences.getInstance();

    final nouvelleFamilleId = (body['famille'] as Map)['id'] as String;
    final ancienneFamilleId = prefs.getString('api_famille_id');

    // Si la famille change, purger les données locales de l'ancienne famille
    if (ancienneFamilleId != null && ancienneFamilleId != nouvelleFamilleId) {
      await DatabaseHelper.instance.clearFamilyData();
    }

    // Session valide 1 jour à partir de maintenant
    await prefs.setInt(
      'api_session_expiry',
      DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
    );

    final user = body['user'] as Map;
    final famille = body['famille'] as Map;
    await prefs.setString('api_user_id', user['id'] as String);
    await prefs.setString('api_famille_id', nouvelleFamilleId);
    await prefs.setString('api_user_nom', user['nom'] as String? ?? '');
    await prefs.setString('api_user_prenom', user['prenom'] as String? ?? '');
    await prefs.setString('api_user_email', user['email'] as String? ?? '');
    final tel = user['telephone'] as String?;
    if (tel != null) await prefs.setString('api_user_telephone', tel);
    final role = user['role'] as String?;
    if (role != null) await prefs.setString('api_user_role', role);
    await prefs.setString('api_famille_nom', famille['nom'] as String? ?? '');
    final code = famille['codeUnique'] as String?;
    if (code != null) await prefs.setString('api_famille_code', code);
  }

  // ── Auth ─────────────────────────────────────────────────────────────────────

  /// Création d'une famille + compte administrateur
  static Future<String?> register({
    required String nomFamille,
    String? codeUnique,       // null = auto-généré par le serveur
    String? lieu,
    required String email,
    String? telephone,
    required String password,
    required String nom,
    required String prenom,
    required String questionSecrete,
    required String reponseSecrete,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nomFamille': nomFamille,
              if (codeUnique != null) 'codeUnique': codeUnique,
              if (lieu != null) 'lieu': lieu,
              'email': email,
              if (telephone != null) 'telephone': telephone,
              'password': password,
              'nom': nom,
              'prenom': prenom,
              'questionSecrete': questionSecrete,
              'reponseSecrete': reponseSecrete,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        await _saveSession(body);
        return null;
      }
      return body['error'] as String? ?? 'Erreur inconnue';
    } on http.ClientException {
      return 'Impossible de joindre le serveur. Vérifie ta connexion WiFi.';
    } catch (e) {
      return 'Erreur réseau : $e';
    }
  }

  /// Connexion avec code famille + email/téléphone + mot de passe
  static Future<String?> login({
    required String familleCode,
    required String identifiant, // email ou numéro de téléphone
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'familleCode': familleCode,
              'identifiant': identifiant,
              'password': password,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        await _saveSession(body);
        return null;
      }
      return body['error'] as String? ?? 'Identifiant ou mot de passe incorrect';
    } on http.ClientException {
      return 'Impossible de joindre le serveur. Vérifie ta connexion WiFi.';
    } catch (e) {
      return 'Erreur réseau : $e';
    }
  }

  /// Réinitialisation mot de passe
  static Future<String?> resetPassword({
    required String email,
    required String questionSecrete,
    required String reponseSecrete,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/auth/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'questionSecrete': questionSecrete,
              'reponseSecrete': reponseSecrete,
              'newPassword': newPassword,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return null;
      return body['error'] as String? ?? 'Erreur';
    } catch (e) {
      return 'Erreur réseau : $e';
    }
  }

  /// Recherche de familles par nom (pour l'autocomplete de connexion)
  static Future<List<FamilleInfo>> searchFamilles(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/familles/search?q=${Uri.encodeQueryComponent(query)}'))
          .timeout(_timeout);
      if (response.statusCode != 200) return [];
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((j) => FamilleInfo.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Vérifie un code famille et retourne les infos basiques
  static Future<FamilleInfo?> getFamilleByCode(String code) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/familles/by-code/${Uri.encodeComponent(code.toUpperCase())}'))
          .timeout(_timeout);
      if (response.statusCode != 200) return null;
      return FamilleInfo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Admin/gestionnaire crée un compte login pour un membre de la famille
  static Future<String?> createMembre({
    required String email,
    String? telephone,
    required String password,
    required String nom,
    required String prenom,
    required String role, // 'gestionnaire' ou 'membre'
    required String questionSecrete,
    required String reponseSecrete,
    String? personneId, // lien vers l'arbre généalogique (optionnel)
  }) async {
    try {
      final response = await post('/api/auth/membres/create', {
        'email': email,
        if (telephone != null) 'telephone': telephone,
        'password': password,
        'nom': nom,
        'prenom': prenom,
        'role': role,
        'questionSecrete': questionSecrete,
        'reponseSecrete': reponseSecrete,
        if (personneId != null) 'personneId': personneId,
      });
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201) return null;
      return body['error'] as String? ?? 'Erreur inconnue';
    } catch (e) {
      return 'Erreur réseau : $e';
    }
  }

  /// Vérifie si le user connecté peut éditer/créer des données
  static Future<bool> userCanEdit() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('api_user_role') ?? '';
    return role == 'admin' || role == 'gestionnaire';
  }

  /// Liste les membres de la famille active (throws on error)
  static Future<List<Map<String, dynamic>>> getFamilleMembers() async {
    final response = await get('/api/familles/current');
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] as String? ?? 'Erreur serveur ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = body['membres'] as List? ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Change le rôle d'un membre (admin/gestionnaire uniquement)
  static Future<String?> changeMemberRole({
    required String userId,
    required String role, // 'gestionnaire' ou 'membre'
  }) async {
    try {
      final response = await patch('/api/familles/membres/$userId/role', {'role': role});
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return null;
      return body['error'] as String? ?? 'Erreur inconnue';
    } catch (e) {
      return 'Erreur réseau : $e';
    }
  }

  /// Vérifie si le serveur est joignable
  static Future<bool> isServerReachable() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Requêtes génériques ──────────────────────────────────────────────────────

  static Future<http.Response> get(String path) async {
    final headers = await _authHeaders();
    return http.get(Uri.parse('$_baseUrl$path'), headers: headers).timeout(_timeout);
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    return http
        .post(Uri.parse('$_baseUrl$path'), headers: headers, body: jsonEncode(body))
        .timeout(_timeout);
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    return http
        .put(Uri.parse('$_baseUrl$path'), headers: headers, body: jsonEncode(body))
        .timeout(_timeout);
  }

  static Future<http.Response> patch(String path, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    return http
        .patch(Uri.parse('$_baseUrl$path'), headers: headers, body: jsonEncode(body))
        .timeout(_timeout);
  }

  static Future<http.Response> delete(String path) async {
    final headers = await _authHeaders();
    return http.delete(Uri.parse('$_baseUrl$path'), headers: headers).timeout(_timeout);
  }
}
