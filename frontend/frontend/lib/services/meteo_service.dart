//permet de gérer la météo (consulter) en utilisant l'API backend.

import '../core/api_client.dart';
import '../models/meteo.dart';

class MeteoService {
  final _dio = ApiClient().dio;
  Future<Meteo> consulter() async {
    final rep = await _dio.get('/meteo');
    return Meteo.fromJson(rep.data);
  }
}