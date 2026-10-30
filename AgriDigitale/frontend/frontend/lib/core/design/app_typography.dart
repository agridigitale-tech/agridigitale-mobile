// Centralise les styles de texte et polices utilisés dans toute l'application.
// Typographie officielle AgriDigitale :
// - PT Serif pour les titres d'articles et titres éditoriaux (identique à l'écran de détail article)
// - Inter pour l'ensemble des textes d'interface, navigations, métadonnées et composants

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  /// Police principale pour l'application (Inter)
  static String get policePrincipale => GoogleFonts.inter().fontFamily ?? 'Inter';

  /// Police éditoriale pour les articles et grands titres (PT Serif)
  static String get policeEditorial => GoogleFonts.ptSerif().fontFamily ?? 'PT Serif';

  static TextTheme texte({bool estSombre = false}) {
    final couleurTitre = estSombre ? AppColors.texteSombreFort : AppColors.texteFort;
    final couleurSecondaire = estSombre ? AppColors.texteSombreMoyen : AppColors.grisTexte;
    final vertTitre = estSombre ? AppColors.vertClair : AppColors.vertPrimaire;

    // Base Inter TextTheme complète pour Material 3
    final base = GoogleFonts.interTextTheme(
      estSombre ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return base.copyWith(
      displayLarge: GoogleFonts.ptSerif(fontSize: 32, fontWeight: FontWeight.w700, color: couleurTitre),
      displayMedium: GoogleFonts.ptSerif(fontSize: 28, fontWeight: FontWeight.w700, color: couleurTitre),
      displaySmall: GoogleFonts.ptSerif(fontSize: 24, fontWeight: FontWeight.w600, color: couleurTitre),
      headlineLarge: GoogleFonts.ptSerif(fontSize: 22, fontWeight: FontWeight.w700, color: couleurTitre),
      headlineMedium: GoogleFonts.ptSerif(fontSize: 20, fontWeight: FontWeight.w700, color: couleurTitre),
      headlineSmall: GoogleFonts.ptSerif(fontSize: 18, fontWeight: FontWeight.w600, color: couleurTitre),
      titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: vertTitre),
      titleMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: couleurTitre),
      titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: couleurTitre),
      bodyLarge: GoogleFonts.inter(fontSize: 15, height: 1.5, color: couleurTitre),
      bodyMedium: GoogleFonts.inter(fontSize: 13.5, height: 1.4, color: couleurSecondaire),
      bodySmall: GoogleFonts.inter(fontSize: 12, height: 1.4, color: couleurSecondaire),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: couleurTitre),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: couleurSecondaire),
      labelSmall: GoogleFonts.inter(fontSize: 11, color: couleurSecondaire),
    );
  }
}