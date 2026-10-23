//pour centraliser les styles de texte utilisés dans l'application pour faciliter la maintenance et la cohérence visuelle.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// PT Serif pour les grands titres de section (Weather, Settings, AGRIDIGITALE TV)
/// exactement comme sur ta maquette. Inter pour tout le reste (lisibilité, nav).
class AppTypography {
  AppTypography._();

  static TextTheme texte({bool estSombre = false}) {
    final couleurTitre = estSombre ? AppColors.texteSombreFort : AppColors.texteFort;
    final couleurSecondaire = estSombre ? AppColors.texteSombreMoyen : AppColors.grisTexte;
    final vertTitre = estSombre ? AppColors.vertClair : AppColors.vertPrimaire;

    return TextTheme(
      displaySmall: GoogleFonts.ptSerif(fontSize: 30, fontWeight: FontWeight.w600, color: couleurTitre),
      titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: vertTitre),
      titleMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: couleurTitre),
      bodyLarge: GoogleFonts.inter(fontSize: 15, height: 1.5, color: couleurTitre),
      bodyMedium: GoogleFonts.inter(fontSize: 13.5, height: 1.4, color: couleurSecondaire),
      labelSmall: GoogleFonts.inter(fontSize: 12, color: couleurSecondaire),
    );
  }
}