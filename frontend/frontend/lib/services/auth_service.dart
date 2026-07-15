// permet de gérer l'authentification de l'utilisateur (inscription, connexion, déconnexion) et le stockage sécurisé du token JWT.

import 'package:dio/dio.dart'; // <--- INDISPENSABLE POUR UTILISER DIOEXCEPTION
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_client.dart';
import '../core/constants.dart';

class AuthService {
  final _dio = ApiClient().dio;
  final _storage = const FlutterSecureStorage();

   Future<void> inscrire(String nom, String email, String motDePasse) async {
     try {
       final rep = await _dio.post(AppConstants.apiAuthRegister, data: {
         'nom': nom, 'email': email, 'motDePasse': motDePasse,
       });
       await _storage.write(key: AppConstants.jwtTokenKey, value: rep.data['token']);
      } on DioException catch (e) { // <--- CORRECTION DU TYPAGE ICI
        String errorMessage = AppConstants.registerError;
        if (e.response?.data != null && e.response?.data['message'] != null) {
          errorMessage = e.response?.data['message'];
        }
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception(AppConstants.registerError);
      }
   }

  Future<void> connecter(String email, String motDePasse) async {
    try {
      final rep = await _dio.post(AppConstants.apiAuthLogin, data: {
        'email': email, 'motDePasse': motDePasse,
      });
      await _storage.write(key: AppConstants.jwtTokenKey, value: rep.data['token']);
    } on DioException catch (e) { // <--- ALIGNEMENT DE SÉCURITÉ POUR LA CONNEXION
      final errorMessage = e.response?.data['message'] ?? AppConstants.loginError;
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(AppConstants.loginError);
    }
  }

  Future<void> deconnecter() async => _storage.delete(key: AppConstants.jwtTokenKey);

  Future<bool> estConnecte() async => (await _storage.read(key: AppConstants.jwtTokenKey)) != null;
}
