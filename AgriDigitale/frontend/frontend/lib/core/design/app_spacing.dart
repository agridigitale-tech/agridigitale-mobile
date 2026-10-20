// Tokens d'espacement, de rayons et d'ombres pour une UI cohérente et premium.
// Centraliser ces valeurs évite les "magic numbers" éparpillés dans les écrans.

import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 100;
}

class AppShadow {
  AppShadow._();

  /// Ombre douce pour les cartes légères.
  static List<BoxShadow> douce = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Ombre marquée pour les surfaces flottantes (hero, cartes "à lire aussi").
  static List<BoxShadow> moyenne = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}
