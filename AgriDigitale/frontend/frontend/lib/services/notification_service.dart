import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../providers/notification_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _appId = '0e79e499-2f86-4bf0-964a-3b162fd3dbec';

  /// Identifiant du canal Android attendu par le backend
  /// (notification.service.js → android_channel_id).
  static const String _canalAndroidId = 'agridigitale_channel';

  static final navigatorKey = GlobalKey<NavigatorState>();

  /// OneSignal n'a pas d'implémentation web : on ignore l'initialisation sur
  /// le web et on empêche toute exception de bloquer le démarrage de l'app.
  bool get _supportNotifications => !kIsWeb;

  Future<void> initialiser() async {
    if (!_supportNotifications) return;
    try {
      // Crée le canal Android attendu par le backend AVANT l'initialisation
      // d'OneSignal, sinon les notifications ciblant "agridigitale_channel"
      // retombent sur le canal par défaut (nom/importance perdus).
      await _creerCanalAndroid();

      OneSignal.Debug.setLogLevel(OSLogLevel.none);
      OneSignal.initialize(_appId);
      await OneSignal.Notifications.requestPermission(true);

      // Clic sur notification (app ouverte ou arrière-plan)
      OneSignal.Notifications.addClickListener((event) {
        final data = event.notification.additionalData;
        if (data != null) _traiterNavigation(data);
      });

      // Notification reçue au premier plan → incrémenter badge
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        event.notification.display();
        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          try { ctx.read<NotificationProvider>().incrementer(); } catch (_) {}
        }
      });
    } catch (e) {
      debugPrint('[OneSignal] Initialisation ignorée : $e');
    }
  }

  void ecouterRefreshToken() {
    if (!_supportNotifications) return;
    try {
      // Resync immédiate si l'ID est déjà disponible (évite le problème de
      // remise à zéro qui obligeait à se déconnecter/reconnecter)
      unawaited(synchroniserToken());

      // Puis à chaque changement de subscription ID OneSignal
      OneSignal.User.pushSubscription.addObserver((state) {
        if (state.current.id != null) synchroniserToken();
      });
    } catch (e) {
      debugPrint('[OneSignal] ecouterRefreshToken ignoré : $e');
    }
  }

  Future<void> synchroniserToken() async {
    if (!_supportNotifications) return;
    try {
      final playerId = await _attendrePlayerId();
      if (playerId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString(AppConstants.jwtTokenKey);
      if (jwt == null) return;

      await http.post(
        Uri.parse('${AppConstants.baseUrl}/notifications/token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({'token': playerId}),
      );
      debugPrint('[OneSignal] Token synchronisé');
    } catch (e) {
      debugPrint('[OneSignal] Erreur synchroniserToken: $e');
    }
  }

  // OneSignal fournit le Player ID de façon asynchrone : on attend qu'il soit
  // disponible (max ~10s) au lieu d'abandonner immédiatement si null.
  Future<String?> _attendrePlayerId({int maxTentatives = 20}) async {
    for (var i = 0; i < maxTentatives; i++) {
      final id = OneSignal.User.pushSubscription.id;
      if (id != null) return id;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return OneSignal.User.pushSubscription.id;
  }

  // Crée le canal de notification Android nommé "agridigitale_channel" pour
  // que le channel_id envoyé par le backend soit reconnu (Android 8+).
  Future<void> _creerCanalAndroid() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      const canal = AndroidNotificationChannel(
        _canalAndroidId,
        'AgriDigitale',
        description: 'Actualités et alertes AgriDigitale',
        importance: Importance.high,
      );
      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(canal);
      debugPrint('[Notifications] Canal Android "$_canalAndroidId" prêt');
    } catch (e) {
      debugPrint('[Notifications] Création du canal Android ignorée : $e');
    }
  }

  void _traiterNavigation(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final articleId = data['articleId'] ?? '';
    if (type == 'nouvel_article' && articleId.isNotEmpty) {
      navigatorKey.currentState?.pushNamed('/article', arguments: articleId);
    }
  }
}
