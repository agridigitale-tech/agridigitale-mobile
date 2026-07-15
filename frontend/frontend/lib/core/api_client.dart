import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final _storage = const FlutterSecureStorage();

  static String get _baseUrl {
    // Backend déployé (Render/Railway) : utilise toujours cette ligne en priorité si dispo.
    const backendDeploye = 'https://agridigitale-api.onrender.com/api';
    if (!kDebugMode) return backendDeploye;

    
    return 'http://localhost:5000/api';
  }

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {'Content-Type': 'application/json'},
    ));

    // Ajout d'un interceptor pour le logging en mode debug pour faciliter le développement et le débogage.
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true, responseBody: true, error: true,
      ));
    }

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _storage.delete(key: 'jwt_token');
        }
        handler.next(error);
      },
    ));
  }
}