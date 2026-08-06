import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../providers/notification_provider.dart';

@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background/Terminé: ${message.notification?.title}');
}

const _kChannelId = 'agridigitale_channel';
const _kChannelName = 'AgriDigitale — Actualités';
const _kChannelDesc = 'Notifications pour les nouveaux articles AgriDigitale';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _dio = ApiClient().dio;
  final _localNotif = FlutterLocalNotificationsPlugin();

  static final navigatorKey = GlobalKey<NavigatorState>();

  Future<void> initialiser() async {
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    await _localNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: _onNotifTap,
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _kChannelId,
          _kChannelName,
          description: _kChannelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        ));

    await _messaging.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false, badge: false, sound: false,
    );

    await _envoyerToken();
    _messaging.onTokenRefresh.listen(_sauvegarderToken);

    FirebaseMessaging.onMessage.listen(_afficherNotificationSysteme);
    FirebaseMessaging.onMessageOpenedApp.listen(_gererClic);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _gererClic(initial));
    }
  }

  Future<void> _envoyerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) await _sauvegarderToken(token);
    } catch (e) {
      debugPrint('[FCM] Erreur token: $e');
    }
  }

  Future<void> _sauvegarderToken(String token) async {
    try {
      await _dio.post('/auth/token-fcm', data: {'token': token});
    } catch (e) {
      debugPrint('[FCM] Erreur sauvegarde token: $e');
    }
  }

  void _afficherNotificationSysteme(RemoteMessage message) {
    final notif = message.notification;
    if (notif == null) return;

    // Incrémenter le badge compteur
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      try {
        ctx.read<NotificationProvider>().incrementer();
      } catch (_) {}
    }

    final articleId = message.data['articleId'] ?? '';
    final type = message.data['type'] ?? '';

    _localNotif.show(
      message.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _kChannelId,
          _kChannelName,
          channelDescription: _kChannelDesc,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: '$type|$articleId',
    );
  }

  void _onNotifTap(NotificationResponse response) {
    final parts = (response.payload ?? '').split('|');
    final type = parts.isNotEmpty ? parts[0] : '';
    final id = parts.length > 1 ? parts[1] : '';
    if (type == 'nouvel_article' && id.isNotEmpty) {
      navigatorKey.currentState?.pushNamed('/article', arguments: id);
    }
  }

  void _gererClic(RemoteMessage message) {
    final articleId = message.data['articleId'];
    if (articleId != null && articleId.isNotEmpty) {
      navigatorKey.currentState?.pushNamed('/article', arguments: articleId);
    }
  }
}
