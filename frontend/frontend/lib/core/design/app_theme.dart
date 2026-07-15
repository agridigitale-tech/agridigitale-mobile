//permet de centraliser les thèmes utilisés dans l'application pour faciliter la maintenance et la cohérence visuelle.

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get clair => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.fondClair,
    colorScheme: ColorScheme.light(primary: AppColors.vertPrimaire, error: AppColors.erreur),
    textTheme: AppTypography.texte(),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.fondClair, foregroundColor: AppColors.texteFort, elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    ),
  );
}