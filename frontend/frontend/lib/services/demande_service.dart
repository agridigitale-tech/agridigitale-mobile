//permet de gérer les demandes (envoyer) en utilisant l'API backend.

import '../core/api_client.dart';

class DemandeService {
  final _dio = ApiClient().dio;
  Future<void> envoyer(Map<String, dynamic> donnees) async {
    await _dio.post('/demandes', data: donnees);
  }
}