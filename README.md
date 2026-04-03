# Mam Buudu - Arbre Généalogique Familial

Une application Flutter complète pour la gestion et la visualisation d'arbres généalogiques familiaux.

## 📱 Description

Mam Buudu est une application mobile intuitive qui permet de :
- Créer et gérer des arbres généalogiques complets
- Ajouter des personnes avec leurs informations détaillées
- Gérer les unions et les filiations familiales
- Visualiser l'arbre sous forme graphique interactive
- Importer/exporter des données au format GEDCOM
- Générer des livrets familiaux imprimables

## 🚀 Fonctionnalités Principales

### 🧙‍♂️ Assistant de Saisie Guidé
- **Wizard en 5 étapes** pour créer rapidement un arbre généalogique
- **Prise en main intuitive** pour les nouveaux utilisateurs
- **Création automatique** des relations familiales

### 👥 Gestion des Personnes
- **Formulaire complet** avec validation
- **Photos et biographies** 
- **Dates partielles** (année, mois, jour)
- **Gestion du sexe** et des noms (naissance/usage)

### 💞 Gestion des Unions
- **Création d'unions** entre personnes
- **Types d'unions** variés (mariage, PACS, etc.)
- **Dates et lieux** des unions
- **Notes et descriptions**

### 🌳 Visualisation de l'Arbre
- **Arbre interactif** avec navigation
- **Zoom et pan** pour explorer
- **Changement de racine** dynamique
- **Colors codes** pour les générations

### 📁 Import/Export GEDCOM
- **Importation** de fichiers GEDCOM standards
- **Exportation** au format GEDCOM
- **Compatibilité** avec les logiciels de généalogie
- **Préservation** des données

### 📖 Livret Familial
- **Génération PDF** du livret familial
- **Mise en page professionnelle**
- **Photos incluses**
- **Export partageable**

### 🔍 Recherche et Filtrage
- **Recherche textuelle** instantanée
- **Filtrage par nom, prénoms**
- **Recherche dans tous les champs**
- **Résultats en temps réel**

## 🛠️ Installation

### Prérequis
- Flutter SDK (>= 3.10.4)
- Dart SDK
- Android Studio / VS Code
- Émulateur Android ou appareil iOS

### Installation

1. **Cloner le repository**
```bash
git clone https://github.com/votre-username/mam_buudu.git
cd mam_buudu
```

2. **Installer les dépendances**
```bash
flutter pub get
```

3. **Lancer l'application**
```bash
flutter run
```

### Pour la production

```bash
# Build Android
flutter build apk --release

# Build iOS
flutter build ios --release
```

## 📖 Guide d'Utilisation

### Première Utilisation

1. **Lancement** : L'application démarre avec l'assistant de saisie
2. **Assistant** : Suivez les 5 étapes pour créer votre premier arbre
3. **Navigation** : Utilisez l'écran principal pour gérer vos données

### Création d'une Personne

1. Appuyez sur le bouton **+** (ajouter une personne)
2. Remplissez le formulaire :
   - Nom de naissance ou prénoms (obligatoire)
   - Sexe, dates de naissance/décès
   - Lieux, biographie, photo
3. Validez pour sauvegarder

### Création d'une Union

1. Appuyez sur **"Créer une union"**
2. Sélectionnez les deux conjoints
3. Ajoutez les dates et lieux
4. Enregistrez l'union

### Visualisation de l'Arbre

1. Appuyez sur **"Voir l'arbre"**
2. Naviguez avec **zoom et pan**
3. **Tapotez** sur une personne pour voir ses détails
4. Utilisez **"Changer racine"** pour recentrer

## 🏗️ Architecture Technique

### Structure du Projet

```
lib/
├── models/           # Modèles de données (Personne, Union, Filiation)
├── database/         # Repositories et gestion BDD (SQLite)
├── screens/          # Écrans de l'application
├── widgets/          # Widgets réutilisables
├── services/         # Services métier (cache, notifications)
├── utils/            # Utilitaires (GEDCOM, UUID)
└── main.dart         # Point d'entrée
```

### Technologies Utilisées

- **Flutter** : Framework UI multiplateforme
- **SQLite** : Base de données locale via `sqflite`
- **GEDCOM** : Standard d'échange de données généalogiques
- **Material Design** : Interface utilisateur moderne
- **SharedPreferences** : Stockage local des préférences

### Base de Données

L'application utilise SQLite avec les tables principales :
- `personnes` : Informations des individus
- `unions` : Relations entre conjoints
- `union_participants` : Participants aux unions
- `filiations` : Relations parent-enfant

## 🎨 Personnalisation

### Thème et Couleurs

Le thème utilise le vert comme couleur principale :
```dart
colorScheme: ColorScheme.fromSeed(seedColor: Colors.green)
```

### Icône et Splash Screen

Pour personnaliser l'icône et le splash screen :

```bash
# Générer l'icône adaptive
flutter pub run flutter_launcher_icons

# Configurer le splash screen
flutter pub run flutter_native_splash:create
```

## 🐛 Dépannage

### Problèmes Communs

**L'application ne se lance pas**
- Vérifiez que Flutter est bien installé
- Nettoyez le projet : `flutter clean && flutter pub get`

**Les données ne s'affichent pas**
- Vérifiez les permissions de stockage
- Redémarrez l'application

**Import GEDCOM échoue**
- Vérifiez le format du fichier (.ged)
- Assurez-vous que le fichier n'est pas corrompu

### Logs et Debugging

Activez les logs de debugging :
```bash
flutter run --verbose
```

## 🤝 Contribuer

Les contributions sont bienvenues ! Voici comment participer :

1. **Fork** le repository
2. **Créez une branche** (`git checkout -b feature/nouvelle-fonctionnalite`)
3. **Commitez** vos changements (`git commit -am 'Ajout nouvelle fonctionnalité'`)
4. **Pushez** vers la branche (`git push origin feature/nouvelle-fonctionalite`)
5. **Ouvrez un Pull Request**

### Standards de Code

- Suivez les conventions de style Dart/Flutter
- Ajoutez des commentaires pour le code complexe
- Testez vos modifications
- Documentez les nouvelles fonctionnalités

## 📄 Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 📞 Support

Pour toute question ou suggestion :

- **Issues** : [GitHub Issues](https://github.com/votre-username/mam_buudu/issues)
- **Email** : votre-email@exemple.com
- **Discord** : [Serveur Discord](https://discord.gg/votre-invite)

## 🙏 Remerciements

- **Flutter Team** : Pour le framework amazing
- **Community** : Pour les packages et contributions
- **Testeurs** : Pour leurs retours précieux

---

**Mam Buudu** - *Votre histoire familiale, préservée pour les générations futures* 🌳
