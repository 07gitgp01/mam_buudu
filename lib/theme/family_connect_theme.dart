import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design System Family Connect - Inspiré d'Instagram et TikTok
/// Gradients modernes, typographie Poppins, micro-interactions
class FamilyConnectTheme {
  // ============================================
  // PALETTE DE GRADIENTS MODERNES
  // ============================================
  
  // Gradients primaires - Bleu-Violet vers Rose-Orangé
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6366F1), // Indigo
      Color(0xFF8B5CF6), // Violet
      Color(0xFFEC4899), // Pink
      Color(0xFFF97316), // Orange
    ],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF3B82F6), // Blue
      Color(0xFF06B6D4), // Cyan
    ],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF59E0B), // Amber
      Color(0xFFEF4444), // Red
    ],
  );
  
  // ============================================
  // SYSTÈME DE COULEURS
  // ============================================
  
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surfaceDark = Color(0xFF0F0F0F);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1A1A1A);
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color secondaryColor = Color(0xFF3B82F6);
  static const Color accentColor = Color(0xFFF59E0B);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  
  // ============================================
  // TYPOGRAPHIE Poppins - 6 niveaux de hiérarchie
  // ============================================
  
  static TextStyle get h1 => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  static TextStyle get h2 => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.25,
  );
  
  static TextStyle get h3 => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static TextStyle get h4 => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  
  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  
  // ============================================
  // SPACING SYSTEM - Basé sur 8px
  // ============================================
  
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
  
  // ============================================
  // BORDER RADIUS SYSTEM
  // ============================================
  
  static const BorderRadius radiusXs = BorderRadius.all(Radius.circular(4));
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(20));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(999));
  
  // ============================================
  // SHADOW SYSTEM
  // ============================================
  
  static List<BoxShadow> get shadowXs => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];
  
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.16),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get shadowXl => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.20),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
  
  // ============================================
  // THÈME LIGHT MODE
  // ============================================
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        surface: surfaceLight,
        onSurface: Color(0xFF1F2937),
        error: errorColor,
        onError: Colors.white,
        outline: Color(0xFFE5E7EB),
        outlineVariant: Color(0xFFF3F4F6),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
      ),
      
      // Typography
      textTheme: TextTheme(
        displayLarge: h1.copyWith(color: const Color(0xFF1F2937)),
        displayMedium: h2.copyWith(color: const Color(0xFF1F2937)),
        displaySmall: h3.copyWith(color: const Color(0xFF1F2937)),
        headlineLarge: h4.copyWith(color: const Color(0xFF1F2937)),
        bodyLarge: bodyLarge.copyWith(color: const Color(0xFF4B5563)),
        bodyMedium: bodyMedium.copyWith(color: const Color(0xFF6B7280)),
        bodySmall: bodySmall.copyWith(color: const Color(0xFF9CA3AF)),
        labelLarge: bodyMedium.copyWith(color: const Color(0xFF4B5563)),
        labelMedium: bodySmall.copyWith(color: const Color(0xFF6B7280)),
        labelSmall: caption.copyWith(color: const Color(0xFF9CA3AF)),
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceLight,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: h4.copyWith(color: const Color(0xFF1F2937)),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        margin: const EdgeInsets.all(sm),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          padding: const EdgeInsets.symmetric(horizontal: md, vertical: sm),
          textStyle: bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          padding: const EdgeInsets.symmetric(horizontal: md, vertical: sm),
          textStyle: bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          padding: const EdgeInsets.symmetric(horizontal: md, vertical: sm),
          textStyle: bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: md, vertical: sm),
        hintStyle: bodyMedium.copyWith(color: const Color(0xFF9CA3AF)),
        labelStyle: bodyMedium.copyWith(color: const Color(0xFF6B7280)),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceLight,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF9CA3AF),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: radiusFull),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF3F4F6),
        selectedColor: primaryColor.withValues(alpha: 0.1),
        disabledColor: const Color(0xFFF9FAFB),
        labelStyle: bodySmall.copyWith(color: const Color(0xFF4B5563)),
        secondaryLabelStyle: bodySmall.copyWith(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: sm, vertical: xs),
        shape: RoundedRectangleBorder(borderRadius: radiusSm),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceLight,
        elevation: 24,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: radiusLg),
        titleTextStyle: h4.copyWith(color: const Color(0xFF1F2937)),
        contentTextStyle: bodyLarge.copyWith(color: const Color(0xFF4B5563)),
      ),
      
      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1F2937),
        contentTextStyle: bodyMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: radiusSm),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),
    );
  }
  
  // ============================================
  // THÈME DARK MODE ÉLÉGANT
  // ============================================
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        surface: surfaceDark,
        onSurface: Color(0xFFF9FAFB),
        error: errorColor,
        onError: Colors.white,
        outline: Color(0xFF374151),
        outlineVariant: Color(0xFF1F2937),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
      ),
      
      // Typography
      textTheme: TextTheme(
        displayLarge: h1.copyWith(color: const Color(0xFFF9FAFB)),
        displayMedium: h2.copyWith(color: const Color(0xFFF9FAFB)),
        displaySmall: h3.copyWith(color: const Color(0xFFF9FAFB)),
        headlineLarge: h4.copyWith(color: const Color(0xFFF9FAFB)),
        bodyLarge: bodyLarge.copyWith(color: const Color(0xFFD1D5DB)),
        bodyMedium: bodyMedium.copyWith(color: const Color(0xFF9CA3AF)),
        bodySmall: bodySmall.copyWith(color: const Color(0xFF6B7280)),
        labelLarge: bodyMedium.copyWith(color: const Color(0xFFD1D5DB)),
        labelMedium: bodySmall.copyWith(color: const Color(0xFF9CA3AF)),
        labelSmall: caption.copyWith(color: const Color(0xFF6B7280)),
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: h4.copyWith(color: const Color(0xFFF9FAFB)),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        margin: const EdgeInsets.all(sm),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          padding: const EdgeInsets.symmetric(horizontal: md, vertical: sm),
          textStyle: bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          padding: const EdgeInsets.symmetric(horizontal: md, vertical: sm),
          textStyle: bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          padding: const EdgeInsets.symmetric(horizontal: md, vertical: sm),
          textStyle: bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1F2937),
        border: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: Color(0xFF374151), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: Color(0xFF374151), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: md, vertical: sm),
        hintStyle: bodyMedium.copyWith(color: const Color(0xFF6B7280)),
        labelStyle: bodyMedium.copyWith(color: const Color(0xFF9CA3AF)),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF6B7280),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: radiusFull),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1F2937),
        selectedColor: primaryColor.withValues(alpha: 0.2),
        disabledColor: const Color(0xFF374151),
        labelStyle: bodySmall.copyWith(color: const Color(0xFFD1D5DB)),
        secondaryLabelStyle: bodySmall.copyWith(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: sm, vertical: xs),
        shape: RoundedRectangleBorder(borderRadius: radiusSm),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        elevation: 24,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: radiusLg),
        titleTextStyle: h4.copyWith(color: const Color(0xFFF9FAFB)),
        contentTextStyle: bodyLarge.copyWith(color: const Color(0xFFD1D5DB)),
      ),
      
      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1F2937),
        contentTextStyle: bodyMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: radiusSm),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),
    );
  }
  
  // ============================================
  // MICRO-INTERACTIONS UTILITAIRES
  // ============================================
  
  // Animation durations
  static const Duration fastDuration = Duration(milliseconds: 150);
  static const Duration normalDuration = Duration(milliseconds: 250);
  static const Duration slowDuration = Duration(milliseconds: 350);
  
  // Curve presets
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve sharpCurve = Curves.easeInOutCubic;
  
  // Scale transforms
  static Transform scaleTap(double scale) {
    return Transform.scale(
      scale: scale,
      alignment: Alignment.center,
      child: Container(),
    );
  }
  
  // Gradient overlay utility
  static Widget gradientOverlay({Widget? child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: primaryGradient,
      ),
      child: child,
    );
  }
}
