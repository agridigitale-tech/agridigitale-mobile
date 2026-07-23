import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/constants.dart';

class AuthService {
  final _dio = ApiClient().dio;

  static const _keyToken = 'jwt_token';
  static const _keyNom = 'user_nom';
  static const _keyEmail = 'user_email';
  static const _keyRole = 'user_role';

  Future<Map<String, dynamic>> inscrire(String nom, String email, String motDePasse) async {
    try {
      final rep = await _dio.post(AppConstants.apiAuthRegister, data: {
        'nom': nom, 'email': email, 'motDePasse': motDePasse,
      });
      await _sauvegarder(rep.data);
      return rep.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? AppConstants.registerError);
    }
  }

  Future<Map<String, dynamic>> connecter(String email, String motDePasse) async {
    try {
      final rep = await _dio.post(AppConstants.apiAuthLogin, data: {
        'email': email, 'motDePasse': motDePasse,
      });
      await _sauvegarder(rep.data);
      return rep.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? AppConstants.loginError);
    }
  }

  Future<void> _sauvegarder(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final utilisateur = data['utilisateur'] as Map<String, dynamic>? ?? data;
    if (data['token'] != null) await prefs.setString(_keyToken, data['token']);
    if (utilisateur['nom'] != null) await prefs.setString(_keyNom, utilisateur['nom']);
    if (utilisateur['email'] != null) await prefs.setString(_keyEmail, utilisateur['email']);
    if (utilisateur['role'] != null) await prefs.setString(_keyRole, utilisateur['role']);
    ApiClient().updateToken(data['token']);
  }

  Future<void> deconnecter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyNom);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyRole);
    ApiClient().updateToken(null);
  }

  Future<bool> estConnecte() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token != null) ApiClient().updateToken(token);
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>?> lireProfil() async {
    final prefs = await SharedPreferences.getInstance();
    final nom = prefs.getString(_keyNom);
    final email = prefs.getString(_keyEmail);
    final role = prefs.getString(_keyRole);
    if (nom == null) return null;
    return {'nom': nom, 'email': email, 'role': role};
  }
}
