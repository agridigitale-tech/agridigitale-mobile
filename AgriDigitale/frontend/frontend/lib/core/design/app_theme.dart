//permet de centraliser les thèmes utilisés dans l'application pour faciliter la maintenance et la cohérence visuelle.


// Au lieu de définir les couleurs, les bordures et les polices de caractères sur chaque écran, tu le fais une seule fois ici. Ainsi, si tu veux changer la couleur de tous les champs de texte de l'application, tu as juste à modifier une ligne dans ce fichier 
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get sombre => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.fondSombre,
    canvasColor: AppColors.fondSombre,
    cardColor: AppColors.surfaceSombre,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.vertClair,
      secondary: AppColors.vertPrimaire,
      surface: AppColors.surfaceSombre,
      surfaceContainerHighest: AppColors.surfaceSombreLegere,
      onSurface: AppColors.texteSombreFort,
      error: AppColors.erreur,
    ),
    textTheme: AppTypography.texte(estSombre: true),
    iconTheme: const IconThemeData(color: Colors.white70),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceSombre,
      foregroundColor: AppColors.texteSombreFort,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(color: AppColors.texteSombreFort, fontSize: 17, fontWeight: FontWeight.bold),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceSombre,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.bordureSombre, width: 0.8),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceSombre,
      selectedItemColor: AppColors.vertClair,
      unselectedItemColor: AppColors.texteSombreMoyen,
      elevation: 8,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.bordureSombre,
      thickness: 0.8,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceSombre,
      elevation: 16,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: const TextStyle(color: AppColors.texteSombreFort, fontSize: 18, fontWeight: FontWeight.bold),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceSombre,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.bordureSombre),
      ),
      textStyle: const TextStyle(color: AppColors.texteSombreFort),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceSombreLegere,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.bordureSombre),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.bordureSombre),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.vertClair, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.texteSombreMoyen, fontSize: 13),
      suffixIconColor: Colors.white70,
    ),
  );

  static ThemeData get clair => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.fondClair,
    canvasColor: AppColors.fondClair,
    cardColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: AppColors.vertPrimaire,
      secondary: AppColors.vertFonce,
      surface: Colors.white,
      surfaceContainerHighest: Color(0xFFF0F2F5),
      onSurface: AppColors.texteFort,
      error: AppColors.erreur,
    ),
    textTheme: AppTypography.texte(estSombre: false),
    iconTheme: const IconThemeData(color: Colors.black54),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.texteFort,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(color: AppColors.texteFort, fontSize: 17, fontWeight: FontWeight.bold),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEEEEEE), width: 0.8),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.vertPrimaire,
      unselectedItemColor: Colors.black54,
      elevation: 8,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFEFEFEF),
      thickness: 0.8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.vertPrimaire, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.grisTexte, fontSize: 13),
      suffixIconColor: Colors.black54,
    ),
  );
}