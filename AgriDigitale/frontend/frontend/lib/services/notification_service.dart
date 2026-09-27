import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _appId = '0e79e499-2f86-4bf0-964a-3b162fd3dbec';

  // NavigatorKey partagé avec main.dart pour la navigation depuis les notifs
  static GlobalKey<NavigatorState>? navigatorKey;

  Future<void> initialiser() async {
    OneSignal.Debug.setLogLevel(OSLogLevel.none);
    OneSignal.initialize(_appId);
    await OneSignal.Notifications.requestPermission(true);

    // Tap sur notif (app en arrière-plan ou fermée)
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      if (data != null) _traiterNavigation(data);
    });

    // Notif reçue en foreground → incrémenter le badge
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.notification.display();
    });
  }

  Future<void> synchroniserToken() async {
    try {
      final playerId = OneSignal.User.pushSubscription.id;
      if (playerId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('token') ?? prefs.getString('jwt_token');
      if (jwt == null) return;

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/notifications/token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({'token': playerId}),
      );

      if (response.statusCode == 200) {
        debugPrint('[OneSignal] Token synchronisé avec le backend');
      } else {
        debugPrint('[OneSignal] Erreur sync token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[OneSignal] Erreur synchroniserToken: $e');
    }
  }

  Future<void> gererMessageInitial() async {
    // Géré dans initialiser() via addClickListener
  }

  void ecouterRefreshToken() {
    OneSignal.User.pushSubscription.addObserver((state) {
      if (state.current.id != null) synchroniserToken();
    });
  }

  void _traiterNavigation(Map<String, dynamic> data) {
    final key = navigatorKey;
    if (key == null || key.currentState == null) return;

    final type = data['type'] as String?;
    final articleId = data['articleId'] as String?;

    if (type == 'nouvel_article' && articleId != null && articleId.isNotEmpty) {
      key.currentState!.pushNamed('/article', arguments: articleId);
    }
  }
}
