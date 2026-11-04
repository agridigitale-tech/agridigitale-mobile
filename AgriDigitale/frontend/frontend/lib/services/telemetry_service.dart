// Service de Télémétrie et d'Analytics anonyme (Style TikTok & Profilage Temps Réel)
// Mesure le temps d'écran par menu (Home, Météo, TV, Jeux, Articles),
// l'état en direct (en ligne sur quel écran), le nombre d'ouvertures,
// la première action réalisée à l'ouverture, et les heures d'utilisation (0h à 23h).
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';

class TelemetryService with WidgetsBindingObserver {
  static final TelemetryService _instance = TelemetryService._internal();
  factory TelemetryService() => _instance;
  TelemetryService._internal();

  static const String _kKeyDeviceId = 'analytics_device_id_v1';
  String? _cachedDeviceId;
  final _dio = ApiClient().dio;

  // File d'attente d'événements pour envoi groupé ou asynchrone non-bloquant
  final List<Map<String, dynamic>> _queue = [];
  bool _isSending = false;

  // État de la navigation et de la présence
  bool _initialise = false;
  String _ecranActif = 'home';
  String _dernierOngletPrincipal = 'home';
  DateTime? _debutEcran;
  DateTime? _debutSession;
  String? _premierEcranSession;
  Timer? _heartbeatTimer;

  /// Initialise le service de télémétrie global
  void initialiser() {
    if (_initialise) return;
    _initialise = true;
    WidgetsBinding.instance.addObserver(this);
    _debutSession = DateTime.now();
    _debutEcran = DateTime.now();
    _demarrerHeartbeat();
  }

  /// Générateur standard UUID v4 cryptographiquement sécurisé
  static String _genererUuidV4() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant RFC 4122
    return [
      bytes.sublist(0, 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      bytes.sublist(4, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      bytes.sublist(6, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      bytes.sublist(8, 10).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      bytes.sublist(10, 16).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    ].join('-');
  }

  /// Récupère ou génère l'identifiant anonyme unique du téléphone
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString(_kKeyDeviceId);
      if (id == null || id.isEmpty) {
        id = _genererUuidV4();
        await prefs.setString(_kKeyDeviceId, id);
      }
      _cachedDeviceId = id;
      return id;
    } catch (_) {
      _cachedDeviceId ??= _genererUuidV4();
      return _cachedDeviceId!;
    }
  }

  /// Détecte la plateforme physique
  String _detecterPlateforme() {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
    } catch (_) {}
    return 'inconnu';
  }

  /// Démarre le battement de cœur périodique (toutes les 20 secondes)
  /// pour maintenir le statut "EN LIGNE" et comptabiliser le temps en temps réel
  void _demarrerHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _envoyerHeartbeat();
    });
  }

  void _arreterHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _envoyerHeartbeat() {
    _ajouterEvenement({
      'typeEvenement': 'presence_ping',
      'ecran': _ecranActif,
      'dureeSecondes': 20,
    });
  }

  /// Signale un changement d'écran ou d'onglet
  /// (ex: 'home', 'meteo', 'tv', 'jeux', 'favoris', 'parametres', 'article')
  void naviguerVersEcran(
    String nomEcran, {
    bool estOuvertureInitiale = false,
    String? articleId,
    String? titreArticle,
  }) {
    final maintenant = DateTime.now();

    // 1. Gestion de la première action à l'ouverture de l'application
    if (estOuvertureInitiale) {
      _premierEcranSession = nomEcran;
      trackAppOpen(premierEcran: nomEcran);
    } else if (_premierEcranSession == null) {
      _premierEcranSession = nomEcran;
      _ajouterEvenement({
        'typeEvenement': 'premiere_action',
        'premierEcran': nomEcran,
        'ecran': nomEcran,
      });
    }

    // 2. Si on quitte un écran précédent, on comptabilise la durée passée dessus
    if (_debutEcran != null && _ecranActif != nomEcran) {
      final ecoule = maintenant.difference(_debutEcran!).inSeconds;
      if (ecoule >= 1) {
        trackEcranVue(ecran: _ecranActif, dureeSecondes: ecoule);
      }
    }

    // 3. Mémoriser le dernier onglet principal pour retour après écran secondaire (ex: article)
    const ongletsPrincipaux = ['home', 'meteo', 'tv', 'jeux', 'favoris', 'parametres'];
    if (ongletsPrincipaux.contains(nomEcran)) {
      _dernierOngletPrincipal = nomEcran;
    }

    _ecranActif = nomEcran;
    _debutEcran = maintenant;

    // 4. Ping de présence immédiat pour mettre à jour l'écran actif sur le dashboard
    _ajouterEvenement({
      'typeEvenement': 'presence_ping',
      'ecran': nomEcran,
      if (articleId != null) 'articleId': articleId,
      if (titreArticle != null) 'titreArticle': titreArticle,
      'dureeSecondes': 0,
    });
  }

  /// Quitte un écran secondaire (ex: retour d'un article vers l'onglet principal)
  void quitterEcran(String nomEcran) {
    if (_debutEcran != null) {
      final ecoule = DateTime.now().difference(_debutEcran!).inSeconds;
      if (ecoule >= 1) {
        trackEcranVue(ecran: nomEcran, dureeSecondes: ecoule);
      }
    }
    _ecranActif = _dernierOngletPrincipal;
    _debutEcran = DateTime.now();

    _ajouterEvenement({
      'typeEvenement': 'presence_ping',
      'ecran': _ecranActif,
      'dureeSecondes': 0,
    });
  }

  /// Événement d'ouverture de l'application
  Future<void> trackAppOpen({String premierEcran = 'home'}) async {
    _ajouterEvenement({
      'typeEvenement': 'app_open',
      'premierEcran': premierEcran,
      'ecran': premierEcran,
    });
  }

  /// Événement de fin de session / temps total passé
  Future<void> trackSession(int dureeSecondes) async {
    if (dureeSecondes < 2) return;
    _ajouterEvenement({
      'typeEvenement': 'session',
      'dureeSecondes': dureeSecondes,
      'ecran': _ecranActif,
    });
  }

  /// Temps passé sur un écran précis (Home, Météo, TV, Jeux, etc.)
  Future<void> trackEcranVue({
    required String ecran,
    required int dureeSecondes,
  }) async {
    if (dureeSecondes < 1) return;
    _ajouterEvenement({
      'typeEvenement': 'ecran_vue',
      'ecran': ecran,
      'dureeSecondes': dureeSecondes,
    });
  }

  /// Mesure précise du temps de lecture d'un article
  Future<void> trackArticleLecture({
    required String articleId,
    required String titre,
    required String categorie,
    required int dureeSecondes,
    double pourcentageLecture = 100.0,
  }) async {
    if (dureeSecondes < 2) return;
    _ajouterEvenement({
      'typeEvenement': 'article_lecture',
      'articleId': articleId,
      'titreArticle': titre,
      'categorie': categorie,
      'ecran': 'article',
      'dureeSecondes': dureeSecondes,
      'pourcentageLecture': pourcentageLecture,
    });
  }

  /// Temps passé à explorer une catégorie
  Future<void> trackCategorieVue({
    required String categorie,
    required int dureeSecondes,
  }) async {
    if (dureeSecondes < 2) return;
    _ajouterEvenement({
      'typeEvenement': 'categorie_vue',
      'categorie': categorie,
      'ecran': _ecranActif,
      'dureeSecondes': dureeSecondes,
    });
  }

  /// Écouteur de cycle de vie Flutter (pause, reprise en arrière-plan)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _arreterHeartbeat();
      final maintenant = DateTime.now();
      if (_debutEcran != null) {
        final sec = maintenant.difference(_debutEcran!).inSeconds;
        if (sec >= 1) {
          trackEcranVue(ecran: _ecranActif, dureeSecondes: sec);
        }
      }
      if (_debutSession != null) {
        final sec = maintenant.difference(_debutSession!).inSeconds;
        if (sec >= 3) {
          trackSession(sec);
        }
      }
      _envoyerFileAttente();
    } else if (state == AppLifecycleState.resumed) {
      _debutSession = DateTime.now();
      _debutEcran = DateTime.now();
      _demarrerHeartbeat();
      _ajouterEvenement({
        'typeEvenement': 'presence_ping',
        'ecran': _ecranActif,
        'dureeSecondes': 0,
      });
    }
  }

  /// Ajoute un événement à la file d'attente et déclenche l'envoi en arrière-plan
  Future<void> _ajouterEvenement(Map<String, dynamic> event) async {
    try {
      final devId = await getDeviceId();
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userNom = prefs.getString('user_nom');
      final userEmail = prefs.getString('user_email');

      final chargeUtile = <String, dynamic>{
        'deviceId': devId,
        'plateforme': _detecterPlateforme(),
        'heureJour': DateTime.now().hour,
        'date': DateTime.now().toIso8601String(),
        ...event,
      };

      if (userId != null && userId.isNotEmpty) chargeUtile['utilisateurId'] = userId;
      if (userNom != null && userNom.isNotEmpty) chargeUtile['nomUtilisateur'] = userNom;
      if (userEmail != null && userEmail.isNotEmpty) chargeUtile['emailUtilisateur'] = userEmail;

      _queue.add(chargeUtile);
      _envoyerFileAttente();
    } catch (_) {}
  }

  /// Envoi silencieux et non-bloquant vers le serveur Node.js
  Future<void> _envoyerFileAttente() async {
    if (_isSending || _queue.isEmpty) return;
    _isSending = true;

    try {
      final lot = List<Map<String, dynamic>>.from(_queue);
      _queue.clear();

      await _dio.post(
        '/analytics/track',
        data: lot,
      );
    } catch (e) {
      debugPrint('[TelemetryService] Envoi analytics silencieux différé: $e');
    } finally {
      _isSending = false;
      if (_queue.isNotEmpty) {
        Future.delayed(const Duration(seconds: 4), _envoyerFileAttente);
      }
    }
  }
}
