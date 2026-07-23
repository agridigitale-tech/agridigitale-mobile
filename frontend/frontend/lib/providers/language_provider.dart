// Permet de gérer la langue de l'application et la localisation
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('fr', 'FR');
  Locale get locale => _locale;

  Future<void> charger() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language_code') ?? 'fr';
    final countryCode = prefs.getString('country_code') ?? 'FR';
    _locale = Locale(langCode, countryCode);
    notifyListeners();
  }

  Future<void> changerLangue(Locale nouvelleLocale) async {
    if (_locale == nouvelleLocale) return;

    _locale = nouvelleLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', nouvelleLocale.languageCode);
    await prefs.setString('country_code', nouvelleLocale.countryCode ?? '');
    notifyListeners();
  }

  // Méthode pour basculer entre français et anglais
  Future<void> basculerLangue() async {
    final nouvelleLocale = _locale.languageCode == 'fr'
        ? const Locale('en', 'US')
        : const Locale('fr', 'FR');
    await changerLangue(nouvelleLocale);
  }
}