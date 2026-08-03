import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api_client.dart';

// Handler background/terminated — fonction top-level obligatoire
// FCM affiche automatiquement la notification système grâce au champ
// notification: {title, body} envoyé par le backend. Ce handler est
// appelé pour les traitements silencieux (data-only messages).
@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  // Pas besoin de Firebase.initializeApp() ici — flutter_fire le gère
  debugPrint('[FCM] Background: ${message.notification?.title}');
}

// Canal Android — doit correspondre à default_notification_channel_id dans AndroidManifest
const _kChannelId = 'agridigitale_channel';
const _kChannelName = 'AgriDigitale — Actualités';
const _kChannelDesc = 'Notifications pour les nouveaux articles AgriDigitale';

// Crée le canal Android via MethodChannel (nécessaire Android 8+)
Future<void> _creerCanalAndroid() async {
  try {
    const channel = MethodChannel('com.example.frontend/notifications');
    await channel.invokeMethod('createChannel', {
      'id': _kChannelId,
      'name': _kChannelName,
      'description': _kChannelDesc,
      'importance': 4, // IMPORTANCE_HIGH
    });
  } catch (_) {
    // Le canal sera créé par FCM automatiquement si le MethodChannel n'existe pas
  }
}

// Service singleton qui gère les notifications push Firebase (FCM).
// Il enregistre le token FCM de l'appareil au backend pour que l'admin
// puisse envoyer des notifications à tous les utilisateurs.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _dio = ApiClient().dio;

  // Clé globale pour afficher les snackbars depuis n'importe où
  static final navigatorKey = GlobalKey<NavigatorState>();

  Future<void> initialiser() async {
    // 1. Enregistrer le handler background/terminated
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    // 2. Créer le canal Android (Android 8+ / Oreo)
    await _creerCanalAndroid();

    // 3. Demander la permission (Android 13+ / iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false, // false = demande explicite à l'utilisateur
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // 4. Forcer la livraison des notifications en foreground sur iOS
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 5. Récupérer et envoyer le token FCM au backend
    await _envoyerToken();

    // 6. Écouter les refresh de token
    _messaging.onTokenRefresh.listen(_sauvegarderToken);

    // 7. Notification reçue en foreground → afficher une bannière
    FirebaseMessaging.onMessage.listen(_afficherNotificationForeground);

    // 8. Notification cliquée depuis background → naviguer vers l'article
    FirebaseMessaging.onMessageOpenedApp.listen(_gererClic);

    // 9. Notification qui a ouvert l'app depuis état terminé
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _gererClic(initial);
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

  // Appelé quand l'utilisateur clique sur une notification (background ou terminé)
  void _gererClic(RemoteMessage message) {
    debugPrint('[FCM] Notification cliquée: ${message.notification?.title}');
    final articleId = message.data['articleId'];
    if (articleId != null && articleId.isNotEmpty) {
      // Naviguer vers l'article concerné
      navigatorKey.currentState?.pushNamed('/article', arguments: articleId);
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
