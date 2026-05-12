# Guide d'Installation Firebase pour Mam Buudu

## Étape 1: Créer un projet Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Cliquez sur "Ajouter un projet"
3. Nommez votre projet "mam-buudu" ou similaire
4. Activez Google Analytics (recommandé)
5. Cliquez sur "Créer un projet"

## Étape 2: Configuration Android

1. Dans la console Firebase, allez à "Paramètres du projet"
2. Cliquez sur l'icône Android pour ajouter une application Android
3. **Nom du package**: `com.example.mam_buudu` (vérifiez dans `android/app/build.gradle`)
4. **Nom de l'application**: Mam Buudu
5. **Certificat de signature SHA-1**:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Copiez le certificat SHA-1 (debug) et collez-le
6. Téléchargez `google-services.json`
7. Placez-le dans `android/app/google-services.json`

### Configuration du build.gradle Android

**android/build.gradle**:
```gradle
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Ajoutez cette ligne
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

**android/app/build.gradle**:
```gradle
plugins {
    // Ajoutez cette ligne
    id 'com.google.gms.google-services'
}
```

## Étape 3: Configuration iOS

1. Dans la console Firebase, cliquez sur l'icône iOS
2. **Bundle ID**: `com.example.mam_buudu` (vérifiez dans `ios/Runner.xcodeproj`)
3. **Nom de l'application**: Mam Buudu
4. Téléchargez `GoogleService-Info.plist`
5. Placez-le dans `ios/Runner/GoogleService-Info.plist`

### Configuration du projet iOS

**ios/Runner/AppDelegate.swift**:
```swift
import UIKit
import Flutter
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**ios/Podfile**:
```ruby
# Ajoutez cette ligne à la fin
pod 'Firebase/Core'
```

Puis exécutez:
```bash
cd ios
pod install
```

## Étape 4: Configuration Firestore

1. Dans la console Firebase, allez à "Firestore Database"
2. Cliquez sur "Créer une base de données"
3. Choisissez "Démarrer en mode test" (pour le développement)
4. Sélectionnez une localisation (choisissez la plus proche de vos utilisateurs)
5. Cliquez sur "Activer"

### Importer les règles de sécurité

1. Allez dans "Firestore Database" > "Règles"
2. Remplacez le contenu par le fichier `firestore.rules` du projet
3. Cliquez sur "Publier"

## Étape 5: Configuration Firebase Storage

1. Dans la console Firebase, allez à "Storage"
2. Cliquez sur "Commencer"
3. Choisissez "Démarrer en mode test"
4. Configurez la sécurité comme pour Firestore
5. Cliquez sur "Activer"

### Importer les règles de Storage

1. Allez dans "Storage" > "Règles"
2. Remplacez le contenu par le fichier `storage.rules` du projet
3. Cliquez sur "Publier"

## Étape 6: Configuration Authentification

1. Dans la console Firebase, allez à "Authentification"
2. Cliquez sur "Commencer"
3. Activez "Email/Mot de passe"
4. (Optionnel) Activez "Google" pour l'authentification sociale

## Étape 7: Tester l'installation

1. Exécutez `flutter pub get`
2. Lancez l'application:
   ```bash
   flutter run
   ```
3. Testez l'authentification et la connexion à Firebase

## Étape 8: Migration des données

L'application inclut un service de migration automatique:

1. Connectez-vous à l'application
2. Si des données locales existent, une option de migration apparaîtra
3. Suivez les instructions pour migrer vos données vers Firebase

## Dépannage

### Erreurs courantes

**"google-services.json not found"**
- Vérifiez que le fichier est bien dans `android/app/google-services.json`
- Nettoyez et rebuild: `flutter clean && flutter pub get`

**"FirebaseApp not initialized"**
- Vérifiez que `Firebase.initializeApp()` est bien appelé dans `main.dart`
- Assurez-vous que les dépendances sont correctement installées

**"Permission denied"**
- Vérifiez les règles de sécurité Firestore et Storage
- Assurez-vous que l'utilisateur est bien connecté

**"Network request failed"**
- Vérifiez votre connexion internet
- Assurez-vous que Firestore est bien activé dans la console Firebase

### Logs de débogage

Activez les logs Firebase pour le débogage:

```dart
// Dans main.dart, avant runApp()
await Firebase.initializeApp();
print('Firebase initialisé: ${Firebase.app().options.projectId}');
```

## Prochaines étapes

1. **Personnaliser les règles de sécurité** selon vos besoins
2. **Configurer les index Firestore** pour optimiser les requêtes
3. **Mettre en place les notifications push** avec Firebase Cloud Messaging
4. **Configurer Firebase Analytics** pour suivre l'utilisation
5. **Mettre en place Firebase Performance Monitoring**

## Support

- [Documentation Firebase Flutter](https://firebase.google.com/docs/flutter/setup)
- [Console Firebase](https://console.firebase.google.com/)
- [Communauté Firebase](https://firebase.google.com/community)
