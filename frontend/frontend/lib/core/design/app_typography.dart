//pour centraliser les styles de texte utilisés dans l'application pour faciliter la maintenance et la cohérence visuelle.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// PT Serif pour les grands titres de section (Weather, Settings, AGRIDIGITALE TV)
/// exactement comme sur ta maquette. Inter pour tout le reste (lisibilité, nav).
class AppTypography {
  AppTypography._();

  static TextTheme texte() => TextTheme(
    displaySmall: GoogleFonts.ptSerif(fontSize: 30, fontWeight: FontWeight.w600, color: AppColors.texteFort),
    titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.vertPrimaire),
    titleMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.texteFort),
    bodyLarge: GoogleFonts.inter(fontSize: 15, height: 1.5, color: AppColors.texteFort),
    bodyMedium: GoogleFonts.inter(fontSize: 13.5, height: 1.4, color: AppColors.grisTexte),
    labelSmall: GoogleFonts.inter(fontSize: 12, color: AppColors.grisTexte),
  );
}