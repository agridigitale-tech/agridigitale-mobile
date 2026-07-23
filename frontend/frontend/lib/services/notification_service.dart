import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../core/api_client.dart';

// Handler background — doit être une fonction top-level
@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Message background: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _dio = ApiClient().dio;

  // Clé globale pour afficher les snackbars depuis n'importe où
  static final navigatorKey = GlobalKey<NavigatorState>();

  Future<void> initialiser() async {
    // 1. Enregistrer le handler background
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    // 2. Demander la permission (Android 13+ / iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // 3. Récupérer et envoyer le token FCM au backend
    await _envoyerToken();

    // 4. Écouter les refresh de token
    _messaging.onTokenRefresh.listen(_sauvegarderToken);

    // 5. Notification reçue en foreground → afficher une bannière + rafraîchir badge
    FirebaseMessaging.onMessage.listen((message) {
      _afficherNotificationForeground(message);
      // Le badge sera rafraîchit via FirebaseMessaging.onMessage dans HomeScreen
    });

    // 6. Notification cliquée depuis background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] Notification ouverte: ${message.notification?.title}');
    });

    // 7. Notification qui a ouvert l'app depuis terminated
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('[FCM] App ouverte via notification: ${initial.notification?.title}');
    }
  }

  Future<void> _envoyerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _sauvegarderToken(token);
      }
    } catch (e) {
      debugPrint('[FCM] Erreur token: $e');
    }
  }

  Future<void> _sauvegarderToken(String token) async {
    try {
      await _dio.post('/auth/token-fcm', data: {'token': token});
      debugPrint('[FCM] Token enregistré');
    } catch (e) {
      debugPrint('[FCM] Erreur sauvegarde token: $e');
    }
  }

  void _afficherNotificationForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: const Color(0xFF3CA35A),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.notifications, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    notification.title ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  if ((notification.body ?? '').isNotEmpty)
                    Text(
                      notification.body!,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
