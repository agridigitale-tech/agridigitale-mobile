//permet de centraliser les thèmes utilisés dans l'application pour faciliter la maintenance et la cohérence visuelle.

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get sombre => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(primary: AppColors.vertPrimaire, error: AppColors.erreur),
    textTheme: AppTypography.texte(),
    // iconTheme global : s'applique à TOUS les Icon() y compris dans suffixIcon
    iconTheme: const IconThemeData(color: Colors.white70),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1C1E26), foregroundColor: Colors.white, elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2D3A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      suffixIconColor: Colors.white70,
    ),
  );

  static ThemeData get clair => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.fondClair,
    colorScheme: ColorScheme.light(primary: AppColors.vertPrimaire, error: AppColors.erreur),
    textTheme: AppTypography.texte(),
    // iconTheme global : s'applique à TOUS les Icon() y compris dans suffixIcon
    iconTheme: const IconThemeData(color: Colors.black54),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.fondClair, foregroundColor: AppColors.texteFort, elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      suffixIconColor: Colors.black54,
    ),
  );
}