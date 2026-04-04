# Guide pour créer les icônes manuellement

## Étapes pour créer les icônes Mam Buudu :

### 1. Convertir le SVG en PNG
Utilisez un outil en ligne comme :
- https://svgtopng.com/
- https://convertio.co/fr/svg-png/
- Adobe Illustrator

Ou avec ImageMagick :
```bash
convert assets/icon/icon-1024x1024.svg assets/icon/icon-1024x1024.png
```

### 2. Une fois le PNG créé, exécutez :
```bash
dart run flutter_launcher_icons
```

### 3. Emplacements des icônes générées :

#### ANDROID :
```
android/app/src/main/res/
├── mipmap-hdpi/ic_launcher.png (48x48)
├── mipmap-mdpi/ic_launcher.png (48x48)
├── mipmap-xhdpi/ic_launcher.png (96x96)
├── mipmap-xxhdpi/ic_launcher.png (144x144)
├── mipmap-xxxhdpi/ic_launcher.png (192x192)
├── drawable-hdpi/ic_launcher_background.png
├── drawable-hdpi/ic_launcher_foreground.png
├── drawable-mdpi/ic_launcher_background.png
├── drawable-mdpi/ic_launcher_foreground.png
├── drawable-xhdpi/ic_launcher_background.png
├── drawable-xhdpi/ic_launcher_foreground.png
├── drawable-xxhdpi/ic_launcher_background.png
├── drawable-xxhdpi/ic_launcher_foreground.png
├── drawable-xxxhdpi/ic_launcher_background.png
└── drawable-xxxhdpi/ic_launcher_foreground.png
```

#### IOS :
```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
├── Icon-App-20x20@1x.png
├── Icon-App-20x20@2x.png
├── Icon-App-20x20@3x.png
├── Icon-App-29x29@1x.png
├── Icon-App-29x29@2x.png
├── Icon-App-29x29@3x.png
├── Icon-App-40x40@1x.png
├── Icon-App-40x40@2x.png
├── Icon-App-40x40@3x.png
├── Icon-App-60x60@2x.png
├── Icon-App-60x60@3x.png
├── Icon-App-76x76@1x.png
├── Icon-App-76x76@2x.png
├── Icon-App-83.5x83.5@2x.png
└── Icon-App-1024x1024@1x.png
```

### 4. Design de l'icône :
- **Fond** : Dégradé bleu ciel (#87CEEB → #E0F2FE)
- **Icône** : Famille (parent + 2 enfants)
- **Style** : Moderne, familial
- **Texte** : "Mam Buudu" en bas

### 5. Alternative rapide :
Utilisez l'icône Flutter par défaut en attendant de créer le PNG personnalisé.
