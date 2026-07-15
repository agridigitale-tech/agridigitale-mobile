//permet de définir les thèmes clair et sombre de l'application

import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get clair => ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.green,
    useMaterial3: true,
  );

  static ThemeData get sombre => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.green,
    useMaterial3: true,
  );
}