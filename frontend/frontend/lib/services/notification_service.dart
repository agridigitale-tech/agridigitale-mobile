//permet de gérer les notifications push (souscrire, recevoir) en utilisant Firebase Cloud Messaging et l'API backend.

import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/api_client.dart';

class NotificationService {
  final _messaging = FirebaseMessaging.instance;
  final _dio = ApiClient().dio;

  Future<void> initialiser() async {
    await _messaging.requestPermission();
    final token = await _messaging.getToken();
    if (token != null) {
      await _dio.post('/auth/token-fcm', data: {'token': token});
    }
    FirebaseMessaging.onMessage.listen((message) {
        
      // Affiche une bannière in-app ou déclenche un rafraîchissement du fil
    });
  }
}