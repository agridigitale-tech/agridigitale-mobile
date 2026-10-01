import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
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
  static final navigatorKey = GlobalKey<NavigatorState>();

  Future<void> initialiser() async {
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
  }

  void ecouterRefreshToken() {
    // Resync immédiate si l'ID est déjà disponible (évite le problème de
    // remise à zéro qui obligeait à se déconnecter/reconnecter)
    unawaited(synchroniserToken());

    // Puis à chaque changement de subscription ID OneSignal
    OneSignal.User.pushSubscription.addObserver((state) {
      if (state.current.id != null) synchroniserToken();
    });
  }

  Future<void> synchroniserToken() async {
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

  void _traiterNavigation(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final articleId = data['articleId'] ?? '';
    if (type == 'nouvel_article' && articleId.isNotEmpty) {
      navigatorKey.currentState?.pushNamed('/article', arguments: articleId);
    }
  }
}
