//permet de gérer le thème de l'application (clair ou sombre)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;

  Future<void> charger() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = (prefs.getString('theme') == 'sombre') ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> basculer() async {
    _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', _mode == ThemeMode.dark ? 'sombre' : 'clair');
    notifyListeners();
  }
}
//Ce code permet de gérer le thème visuel de l'application (mode clair ou mode sombre) et de sauvegarder ce choix sur le téléphone pour qu'il soit conservé au redémarrage.