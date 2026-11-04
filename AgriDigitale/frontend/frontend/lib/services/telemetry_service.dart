// Service de Télémétrie et d'Analytics anonyme (Style TikTok)
// Mesure le temps d'écran, les catégories préférées et la durée de lecture par article
// sans aucune connexion ni création de compte obligatoire.
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';

class TelemetryService {
  static final TelemetryService _instance = TelemetryService._internal();
  factory TelemetryService() => _instance;
  TelemetryService._internal();

  static const String _kKeyDeviceId = 'analytics_device_id_v1';
  String? _cachedDeviceId;
  final _dio = ApiClient().dio;

  // File d'attente d'événements pour envoi groupé ou asynchrone non-bloquant
  final List<Map<String, dynamic>> _queue = [];
  bool _isSending = false;

  /// Générateur standard UUID v4 cryptographiquement sécurisé (sans dépendance externe)
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

  /// Événement d'ouverture de l'application
  Future<void> trackAppOpen() async {
    final devId = await getDeviceId();
    _ajouterEvenement({
      'deviceId': devId,
      'typeEvenement': 'app_open',
      'plateforme': _detecterPlateforme(),
      'date': DateTime.now().toIso8601String(),
    });
  }

  /// Événement de fin de session / temps total passé
  Future<void> trackSession(int dureeSecondes) async {
    if (dureeSecondes < 3) return; // Ignorer les micro-ouvertures accidentelles
    final devId = await getDeviceId();
    _ajouterEvenement({
      'deviceId': devId,
      'typeEvenement': 'session',
      'dureeSecondes': dureeSecondes,
      'plateforme': _detecterPlateforme(),
      'date': DateTime.now().toIso8601String(),
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
    // Si l'utilisateur reste moins de 2 secondes, c'est un clic accidentel
    if (dureeSecondes < 2) return;

    final devId = await getDeviceId();
    _ajouterEvenement({
      'deviceId': devId,
      'typeEvenement': 'article_lecture',
      'articleId': articleId,
      'titreArticle': titre,
      'categorie': categorie,
      'dureeSecondes': dureeSecondes,
      'pourcentageLecture': pourcentageLecture,
      'plateforme': _detecterPlateforme(),
      'date': DateTime.now().toIso8601String(),
    });
  }

  /// Temps passé à explorer une catégorie
  Future<void> trackCategorieVue({
    required String categorie,
    required int dureeSecondes,
  }) async {
    if (dureeSecondes < 3) return;

    final devId = await getDeviceId();
    _ajouterEvenement({
      'deviceId': devId,
      'typeEvenement': 'categorie_vue',
      'categorie': categorie,
      'dureeSecondes': dureeSecondes,
      'plateforme': _detecterPlateforme(),
      'date': DateTime.now().toIso8601String(),
    });
  }

  /// Ajoute un événement à la file d'attente et déclenche l'envoi en arrière-plan
  void _ajouterEvenement(Map<String, dynamic> event) {
    _queue.add(event);
    _envoyerFileAttente();
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
      // Échec silencieux : ne jamais bloquer l'interface
      debugPrint('[TelemetryService] Envoi analytics silencieux différé: $e');
    } finally {
      _isSending = false;
      if (_queue.isNotEmpty) {
        Future.delayed(const Duration(seconds: 5), _envoyerFileAttente);
      }
    }
  }
}
