//permet de centraliser les couleurs utilisées dans l'application pour faciliter la maintenance et la cohérence visuelle.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const vertPrimaire = Color(0xFF3CA35A);   // logo "AGRIDIGITALE", boutons, actifs
  static const vertFonce = Color(0xFF1F7A3D);
  static const fondClair = Color(0xFFFCF6F8);       // blanc légèrement rosé (vu sur tes captures)
  static const fondSombreAGDTV = Color(0xFF1C1E26);  // fond sombre de l'écran AGDTV
  static const grisTexte = Color(0xFF6B6B6B);
  static const grisIcone = Color(0xFF7C7C7C);
  static const grisLigne = Color(0xFFE7E7E7);
  static const grisPastille = Color(0xFFEDEDED);
  static const texteFort = Color(0xFF1A1A1A);
  static const erreur = Color(0xFFC62828);
}