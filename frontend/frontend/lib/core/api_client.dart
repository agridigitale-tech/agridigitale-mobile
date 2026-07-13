import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      // En développement local : 10.0.2.2 redirige automatiquement vers le localhost:5000 de ton PC depuis l'émulateur Android
      baseUrl: 'http://10.0.0.59', 
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Intercepte chaque requête pour y injecter automatiquement le Token JWT s'il existe
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Si le serveur répond 401 (Non autorisé/Token expiré), déconnexion automatique
        if (error.response?.statusCode == 401) {
          await _storage.delete(key: 'jwt_token'); 
        }
        handler.next(error);
      },
    ));
  }
}
