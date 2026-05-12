import 'package:flutter/material.dart';
import '../services/auth_test_service.dart';
import '../services/firebase_auth_service.dart';

/// Écran de test pour l'authentification Firebase
class AuthTestScreen extends StatefulWidget {
  const AuthTestScreen({super.key});

  @override
  State<AuthTestScreen> createState() => _AuthTestScreenState();
}

class _AuthTestScreenState extends State<AuthTestScreen> {
  final AuthTestService _testService = AuthTestService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  
  bool _isLoading = false;
  AuthTestResult? _testResult;
  AuthStatus? _authStatus;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final status = _testService.checkAuthStatus();
    setState(() {
      _authStatus = status;
    });
  }

  Future<void> _runFullTest() async {
    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    try {
      final result = await _testService.runFullAuthTest();
      setState(() {
        _testResult = result;
        _isLoading = false;
      });
      
      // Rafraîchir le statut après le test
      await _checkAuthStatus();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _quickTest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _testService.quickAuthTest();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Test rapide réussi !' : 'Test rapide échoué'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      
      await _checkAuthStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Authentification Firebase'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statut actuel
            _buildAuthStatusCard(),
            
            const SizedBox(height: 16),
            
            // Boutons de test
            _buildTestButtons(),
            
            const SizedBox(height: 16),
            
            // Résultats du test
            if (_testResult != null) ...[
              _buildTestResultCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuthStatusCard() {
    if (_authStatus == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Chargement du statut...'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statut Actuel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusRow('Firebase initialisé', _authStatus!.isFirebaseInitialized),
            _buildStatusRow('Utilisateur connecté', _authStatus!.isUserConnected),
            if (_authStatus!.userId != null)
              _buildStatusRow('ID Utilisateur', _authStatus!.userId!),
            if (_authStatus!.userEmail != null)
              _buildStatusRow('Email', _authStatus!.userEmail!),
            _buildStatusRow('Email vérifié', _authStatus!.isEmailVerified),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Text(': '),
          Icon(
            value == true ? Icons.check_circle : (value == false ? Icons.cancel : Icons.info),
            color: value == true ? Colors.green : (value == false ? Colors.red : Colors.blue),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.toString(),
              style: TextStyle(
                color: value == true ? Colors.green : (value == false ? Colors.red : Colors.black),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tests d\'Authentification',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _quickTest,
                    icon: const Icon(Icons.speed),
                    label: const Text('Test Rapide'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _runFullTest,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.checklist),
                    label: Text(_isLoading ? 'Test en cours...' : 'Test Complet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Le test complet créera un compte temporaire et le supprimera',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultCard() {
    return Card(
      color: _testResult!.success ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _testResult!.success ? Icons.check_circle : Icons.error,
                  color: _testResult!.success ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _testResult!.success ? 'Test Réussi' : 'Test Échoué',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _testResult!.success ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _testResult!.message,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            
            // Détails du test
            const SizedBox(height: 16),
            const Text(
              'Détails:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTestDetail('Firebase initialisé', _testResult!.firebaseInitialized),
            _buildTestDetail('Inscription', _testResult!.signUpSuccess),
            _buildTestDetail('Connexion', _testResult!.signInSuccess),
            _buildTestDetail('Récupération utilisateur', _testResult!.getCurrentUserSuccess),
            _buildTestDetail('Déconnexion', _testResult!.signOutSuccess),
            
            // Erreurs
            if (_testResult!.errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Erreurs:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              ..._testResult!.errors.map((error) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '  - $error',
                  style: const TextStyle(color: Colors.red),
                ),
              )),
            ],
            
            // Informations
            if (_testResult!.infos.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Informations:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              ..._testResult!.infos.map((info) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '  - $info',
                  style: const TextStyle(color: Colors.blue),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestDetail(String label, bool success) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            success ? Icons.check : Icons.close,
            color: success ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
