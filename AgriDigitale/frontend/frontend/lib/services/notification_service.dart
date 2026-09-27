import 'dart:convert';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _appId = '0e79e499-2f86-4bf0-964a-3b162fd3dbec';

  Future<void> initialiser() async {
    OneSignal.Debug.setLogLevel(OSLogLevel.none);
    OneSignal.initialize(_appId);
    await OneSignal.Notifications.requestPermission(true);

    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      if (data != null) _traiterNavigation(data);
    });
  }

  Future<void> synchroniserToken() async {
    try {
      final playerId = OneSignal.User.pushSubscription.id;
      if (playerId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('token');
      if (jwt == null) return;

      print('[OneSignal] Player ID: ${playerId.substring(0, 20)}...');

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/notifications/token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({'token': playerId}),
      );

      if (response.statusCode == 200) {
        print('[OneSignal] Token synchronisé avec le backend');
      } else {
        print('[OneSignal] Erreur sync token: ${response.statusCode}');
      }
    } catch (e) {
      print('[OneSignal] Erreur synchroniserToken: $e');
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
    // Navigation selon data['type']
  }
}
