import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const delegate = _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _traductions = {
    'fr': {
      'app_title': 'AgriDigitale',
      'home': 'Accueil',
      'weather': 'Météo',
      'agdtv': 'AGDTV',
      'favorites': 'Favoris',
      'request': 'Demande',
      'games': 'Jeux',
      'settings': 'Paramètres',
      'notifications': 'Alertes',
      'search': 'Rechercher...',
      'no_articles': 'Aucun article',
      'no_articles_sub': 'Rien à afficher pour cette rubrique.',
      'connection_error': 'Connexion impossible',
      'connection_error_sub': 'Vérifie ta connexion internet et tire vers le bas pour réessayer.',
      'retry': 'Réessayer',
      'source': 'Voir la source originale',
      'favorites_empty': 'Aucun article enregistré',
      'favorites_hint': 'Appuie sur 🔖 sur un article pour l\'enregistrer',
      'login': 'Se connecter',
      'logout': 'Déconnexion',
      'login_to_favorites': 'Connecte-toi pour voir tes favoris',
      'language': 'Langue',
      'share': 'Partager Agridigitale',
      'rate': 'Noter Agridigitale',
      'about': 'À propos',
      'comments': 'Commentaires',
      'add_comment': 'Écrire un commentaire...',
      'login_to_comment': 'Connectez-vous pour commenter',
      'other_articles': 'Autres articles',
      'weather_title': 'Météo Agricole',
      'humidity': 'Humidité',
      'wind': 'Vent',
      'forecast': 'Prévisions 5 jours',
      'today': 'Aujourd\'hui',
      'tomorrow': 'Demain',
      'agricultural_advice': 'Conseil agricole',
      'added_to_favorites': '✓ Ajouté aux favoris',
      'already_in_favorites': 'Déjà dans vos favoris',
      'removed_from_favorites': 'Retiré des favoris',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'delete_comment': 'Voulez-vous supprimer ce commentaire ?',
      'search_favorites': 'Rechercher dans mes favoris...',
      'no_results': 'Aucun résultat',
      'sort_recent': 'Plus récent',
      'sort_oldest': 'Plus ancien',
      'sort_az': 'A → Z',
      'views': 'vues',
      'be_first_comment': 'Soyez le premier à commenter !',
      'loading': 'Chargement...',
      'no_video': 'Aucune vidéo disponible',
      'open_youtube': 'Ouvrir sur YouTube',
      'agdtv_subtitle': 'La chaîne agricole digitale du futur',
      'register': 'Créer un compte',
      'email': 'Email',
      'password': 'Mot de passe',
      'name': 'Nom',
      'login_create': 'Se connecter / Créer un compte',
    },
    'en': {
      'app_title': 'AgriDigitale',
      'home': 'Home',
      'weather': 'Weather',
      'agdtv': 'AGDTV',
      'favorites': 'Favorites',
      'request': 'Request',
      'games': 'Games',
      'settings': 'Settings',
      'notifications': 'Alerts',
      'search': 'Search...',
      'no_articles': 'No articles',
      'no_articles_sub': 'Nothing to display for this category.',
      'connection_error': 'Connection failed',
      'connection_error_sub': 'Check your internet connection and pull down to retry.',
      'retry': 'Retry',
      'source': 'View original source',
      'favorites_empty': 'No saved articles',
      'favorites_hint': 'Tap 🔖 on an article to save it',
      'login': 'Sign in',
      'logout': 'Sign out',
      'login_to_favorites': 'Sign in to see your favorites',
      'language': 'Language',
      'share': 'Share Agridigitale',
      'rate': 'Rate Agridigitale',
      'about': 'About',
      'comments': 'Comments',
      'add_comment': 'Write a comment...',
      'login_to_comment': 'Sign in to comment',
      'other_articles': 'Other articles',
      'weather_title': 'Agricultural Weather',
      'humidity': 'Humidity',
      'wind': 'Wind',
      'forecast': '5-day forecast',
      'today': 'Today',
      'tomorrow': 'Tomorrow',
      'agricultural_advice': 'Agricultural advice',
      'added_to_favorites': '✓ Added to favorites',
      'already_in_favorites': 'Already in favorites',
      'removed_from_favorites': 'Removed from favorites',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'delete_comment': 'Do you want to delete this comment?',
      'search_favorites': 'Search in my favorites...',
      'no_results': 'No results',
      'sort_recent': 'Most recent',
      'sort_oldest': 'Oldest first',
      'sort_az': 'A → Z',
      'views': 'views',
      'be_first_comment': 'Be the first to comment!',
      'loading': 'Loading...',
      'no_video': 'No videos available',
      'open_youtube': 'Open on YouTube',
      'agdtv_subtitle': 'The digital agricultural channel of the future',
      'register': 'Create account',
      'email': 'Email',
      'password': 'Password',
      'name': 'Name',
      'login_create': 'Sign in / Create account',
    },
  };

  String t(String key) {
    final lang = locale.languageCode;
    return _traductions[lang]?[key] ?? _traductions['fr']?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['fr', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
