# Script de génération d'icônes pour Mam Buudu
# Utilise Icons.family_restroom comme base

## Étapes pour créer les icônes :

### 1. Créer l'image de base (1024x1024)
- Fond : dégradé bleu ciel (#87CEEB → #E0F2FE)
- Icône : Icons.family_restroom (blanc, taille 400px)
- Style : Coins arrondis, ombre portée

### 2. Redimensionner pour Android
```bash
# Android (mipmap-*)
convert icon-1024.png -resize 192x192 mipmap-xxxhdpi/ic_launcher.png
convert icon-1024.png -resize 144x144 mipmap-xxhdpi/ic_launcher.png
convert icon-1024.png -resize 96x96 mipmap-xhdpi/ic_launcher.png
convert icon-1024.png -resize 48x48 mipmap-hdpi/ic_launcher.png
convert icon-1024.png -resize 48x48 mipmap-mdpi/ic_launcher.png
```

### 3. Redimensionner pour iOS
```bash
# iOS (AppIcon.appiconset)
convert icon-1024.png -resize 1024x1024 Icon-App-1024x1024@1x.png
convert icon-1024.png -resize 180x180 Icon-App-60x60@3x.png
convert icon-1024.png -resize 120x120 Icon-App-60x60@2x.png
convert icon-1024.png -resize 152x152 Icon-App-76x76@2x.png
convert icon-1024.png -resize 76x76 Icon-App-76x76@1x.png
convert icon-1024.png -resize 167x167 Icon-App-83.5x83.5@2x.png
convert icon-1024.png -resize 120x120 Icon-App-40x40@3x.png
convert icon-1024.png -resize 80x80 Icon-App-40x40@2x.png
convert icon-1024.png -resize 40x40 Icon-App-40x40@1x.png
convert icon-1024.png -resize 87x87 Icon-App-29x29@3x.png
convert icon-1024.png -resize 58x58 Icon-App-29x29@2x.png
convert icon-1024.png -resize 29x29 Icon-App-29x29@1x.png
convert icon-1024.png -resize 60x60 Icon-App-20x20@3x.png
convert icon-1024.png -resize 40x40 Icon-App-20x20@2x.png
convert icon-1024.png -resize 20x20 Icon-App-20x20@1x.png
```

### 4. Outils recommandés
- **Photoshop** : Pour le design
- **ImageMagick** : Pour le redimensionnement
- **Flutter Launcher Icons** : Package automatisé

### 5. Alternative automatisée
Ajouter à pubspec.yaml :
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/icon-1024x1024.png"
  adaptive_icon_background: "#87CEEB"
  adaptive_icon_foreground: "assets/icon/icon-foreground-1024x1024.png"
```

Puis exécuter :
```bash
flutter pub get
flutter_launcher_icons
```

## Design suggéré :
- **Fond** : Dégradé bleu ciel identique au landing
- **Icône** : Icons.family_restroom blanc
- **Style** : Moderne, épuré, familial
- **Coins** : Légèrement arrondis
- **Ombre** : Subtile pour profondeur
