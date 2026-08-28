// Client HTTP singleton basé sur Dio.
// Centralise l'URL du backend, le token JWT et les intercepteurs (logs + auth).
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  String? _token;

  // URL du backend Render — commune à toute l'app (mobile + web)
  static String get baseUrl {
  return 'https://agridigitale-backend.onrender.com/api';
}



  // Met à jour le token JWT après connexion ou le supprime après déconnexion
  void updateToken(String? token) {
    _token = token;
  }

    ApiClient._internal() {
      dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ));
    
      // En mode debug : affiche toutes les requêtes et réponses dans la console
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (o) => debugPrint(o.toString()),
      ));
    }
    // Intercepteur auth : injecte le token Bearer dans chaque requête,
    // et efface le token local si le serveur répond 401 (session expirée)
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          _token = null;
        }
        handler.next(error);
      },
    ));
  }
}
