// Constantes pour l'application
class AppConstants {
  // Constantes de l'arbre généalogique
  static const double arbreLargeurPersonne = 120.0;
  static const double arbreHauteurPersonne = 80.0;
  static const double arbreLargeurUnion = 60.0;
  static const double arbreEspacementHorizontal = 40.0;
  static const double arbreEspacementVertical = 120.0;
  
  // Constantes générales
  static const int defaultPageSize = 20;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
}

// Alias pour compatibilité avec le code existant
const double ARBRE_LARGEUR_PERSONNE = AppConstants.arbreLargeurPersonne;
const double ARBRE_HAUTEUR_PERSONNE = AppConstants.arbreHauteurPersonne;
const double ARBRE_LARGEUR_UNION = AppConstants.arbreLargeurUnion;
const double ARBRE_ESPACEMENT_HORIZONTAL = AppConstants.arbreEspacementHorizontal;
const double ARBRE_ESPACEMENT_VERTICAL = AppConstants.arbreEspacementVertical;
