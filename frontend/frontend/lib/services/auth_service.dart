import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_client.dart';

class AuthService {
  final _dio = ApiClient().dio;
  final _storage = const FlutterSecureStorage();

  Future<void> inscrire(String nom, String email, String motDePasse) async {
    final rep = await _dio.post('/auth/inscription', data: {
      'nom': nom, 'email': email, 'motDePasse': motDePasse,
    });
    await _storage.write(key: 'jwt_token', value: rep.data['token']);
  }

  Future<void> connecter(String email, String motDePasse) async {
    final rep = await _dio.post('/auth/connexion', data: {
      'email': email, 'motDePasse': motDePasse,
    });
    await _storage.write(key: 'jwt_token', value: rep.data['token']);
  }

  Future<void> deconnecter() async => _storage.delete(key: 'jwt_token');

  Future<bool> estConnecte() async => (await _storage.read(key: 'jwt_token')) != null;
}