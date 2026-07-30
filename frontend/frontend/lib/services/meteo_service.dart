import '../core/api_client.dart';
import '../models/meteo.dart';

class MeteoService {
  final _dio = ApiClient().dio;

  Future<Meteo> consulter() async {
    final rep = await _dio.get('/meteo');
    return Meteo.fromJson(rep.data);
  }

  /// Recherche la météo d'une ville via OpenWeatherMap (cache 30min côté backend).
  /// Retourne les données brutes pour affichage dans WeatherScreen.
  Future<Map<String, dynamic>> rechercherVille(String ville) async {
    final rep = await _dio.get('/meteo/ville/${Uri.encodeComponent(ville)}');
    return rep.data as Map<String, dynamic>;
  }
}
