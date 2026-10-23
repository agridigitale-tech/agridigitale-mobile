//permet de centraliser les couleurs utilisées dans l'application pour faciliter la maintenance et la cohérence visuelle.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const vertPrimaire = Color(0xFF3CA35A);   // logo "AGRIDIGITALE", boutons, actifs
  static const vertFonce = Color(0xFF1F7A3D);
  static const vertClair = Color(0xFF4ECB73);      // Vert vif pour contraste optimal en mode sombre
  static const fondClair = Color(0xFFF8F9FA);       // fond clair moderne
  static const fondSombre = Color(0xFF12141A);      // Fond sombre élégant OLED
  static const surfaceSombre = Color(0xFF1A1D26);   // Surface cartes / barres mode sombre
  static const surfaceSombreLegere = Color(0xFF222634); // Surface champs / boutons secondaires
  static const bordureSombre = Color(0xFF2E3344);   // Bordure discrète mode sombre
  static const texteSombreFort = Color(0xFFF5F6F8); // Texte blanc cassé haute lisibilité
  static const texteSombreMoyen = Color(0xFFA6ABB8); // Texte secondaire mode sombre
  static const fondSombreAGDTV = Color(0xFF1C1E26);  // fond sombre de l'écran AGDTV
  static const grisTexte = Color(0xFF6B6B6B);
  static const grisIcone = Color(0xFF7C7C7C);
  static const grisLigne = Color(0xFFE7E7E7);
  static const grisPastille = Color(0xFFEDEDED);
  static const texteFort = Color(0xFF1A1A1A);
  static const erreur = Color(0xFFC62828);
}