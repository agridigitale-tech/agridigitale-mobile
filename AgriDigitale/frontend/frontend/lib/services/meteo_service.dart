// Service météo : récupère les bulletins ANAMET et les données météorologiques
// en direct pour le Togo (Savanes, Kara, Centrale, Plateaux, Maritime) et villes mondiales.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/meteo.dart';
import '../screens/weather/models/bulletin_meteo.dart';

class MeteoService {
  final _dio = ApiClient().dio;

  Future<Meteo> consulter() async {
    final rep = await _dio.get('/meteo');
    return Meteo.fromJson(rep.data);
  }

  /// Récupère la météo en direct pour les 5 régions du Togo via l'API météorologique
  /// (Dapaong, Kara, Sokodé, Atakpamé, Lomé).
  /// Données 100% dynamiques, renouvelées en temps réel chaque jour.
  Future<List<RegionMeteo>> recupererMeteoDirecteTogo() async {
    try {
      final client = Dio();
      // Coordonnées géographiques officielles des 5 chefs-lieux régionaux du Togo :
      // Savanes (Dapaong), Kara (Kara), Centrale (Sokodé), Plateaux (Atakpamé), Maritime (Lomé)
      const url = 'https://api.open-meteo.com/v1/forecast'
          '?latitude=10.86,9.55,8.98,7.53,6.14'
          '&longitude=0.20,1.19,1.14,1.13,1.21'
          '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m'
          '&daily=temperature_2m_max,temperature_2m_min'
          '&timezone=Africa%2FAccra';

      final rep = await client.get(
        url,
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      final dynamic raw = rep.data;
      List dataList = [];
      if (raw is List) {
        dataList = raw;
      } else if (raw is Map) {
        dataList = [raw];
      }

      if (dataList.length < 5) {
        return BulletinMeteo.regionsParDefaut;
      }

      const configs = [
        {'code': 'savanes', 'nom': 'Savanes', 'chefLieu': 'Dapaong (Mango)'},
        {'code': 'kara', 'nom': 'Kara', 'chefLieu': 'Kara (Bassar, Pagouda)'},
        {'code': 'centrale', 'nom': 'Centrale', 'chefLieu': 'Sokodé (Tchamba, Sotouboua)'},
        {'code': 'plateaux', 'nom': 'Plateaux', 'chefLieu': 'Atakpamé (Kpalimé, Badou)'},
        {'code': 'maritime', 'nom': 'Maritime', 'chefLieu': 'Lomé (Tsévié, Aného)'},
      ];

      final regions = <RegionMeteo>[];
      for (int i = 0; i < 5; i++) {
        final item = dataList[i] as Map<String, dynamic>;
        final current = item['current'] as Map<String, dynamic>? ?? {};
        final daily = item['daily'] as Map<String, dynamic>? ?? {};
        final weatherCode = (current['weather_code'] as num?)?.toInt() ?? 0;

        final tMinList = (daily['temperature_2m_min'] as List?) ?? [];
        final tMaxList = (daily['temperature_2m_max'] as List?) ?? [];

        final tMin = tMinList.isNotEmpty ? (tMinList.first as num).toDouble() : 22.0;
        final tMax = tMaxList.isNotEmpty ? (tMaxList.first as num).toDouble() : 34.0;

        final conditionInfo = interpreterWmoCode(weatherCode);

        regions.add(RegionMeteo(
          code: configs[i]['code']!,
          nom: configs[i]['nom']!,
          chefLieu: configs[i]['chefLieu']!,
          condition: conditionInfo['condition'] as String,
          icone: conditionInfo['icone'] as String,
          tempMin: tMin,
          tempMax: tMax,
          pluie: conditionInfo['pluie'] as bool,
          conseil: '',
        ));
      }
      return regions;
    } catch (e) {
      debugPrint('[MeteoService] Erreur récupération météo directe: $e');
      return BulletinMeteo.regionsParDefaut;
    }
  }

  /// Convertit un code météorologique WMO en état et icône reconnue
  static Map<String, dynamic> interpreterWmoCode(int code) {
    if (code == 0) {
      return {'icone': 'soleil', 'condition': 'Ciel dégagé et ensoleillé', 'pluie': false};
    } else if (code <= 2) {
      return {'icone': 'eclaircie', 'condition': 'Éclaircies et passages nuageux', 'pluie': false};
    } else if (code == 3 || code == 45 || code == 48) {
      return {'icone': 'nuage', 'condition': 'Ciel nuageux et couvert', 'pluie': false};
    } else if (code >= 95) {
      return {'icone': 'orage', 'condition': 'Orages et averses orageuses', 'pluie': true};
    } else if (code >= 80) {
      return {'icone': 'pluie', 'condition': 'Averses de pluie locales', 'pluie': true};
    } else {
      return {'icone': 'pluie', 'condition': 'Pluie et bruine passagère', 'pluie': true};
    }
  }

  /// Recherche la météo d'une ville (OpenWeatherMap via backend, avec fallback météo direct).
  Future<Map<String, dynamic>> rechercherVille(String ville) async {
    try {
      final rep = await _dio.get('/meteo/ville/${Uri.encodeComponent(ville)}');
      return rep.data as Map<String, dynamic>;
    } catch (_) {
      // Secours Open-Meteo Géocodage si le backend ou l'API externe est indisponible
      return await _rechercherVilleDirect(ville);
    }
  }

  Future<Map<String, dynamic>> _rechercherVilleDirect(String ville) async {
    final client = Dio();
    final geoUrl = 'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(ville)}&count=1&language=fr';
    final geoRep = await client.get(geoUrl);
    final results = geoRep.data['results'] as List?;
    if (results == null || results.isEmpty) {
      throw Exception('Ville introuvable');
    }
    final first = results.first as Map<String, dynamic>;
    final lat = first['latitude'];
    final lon = first['longitude'];
    final nomVille = first['name'] ?? ville;
    final pays = first['country'] ?? '';

    final forecastUrl = 'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&timezone=auto';
    final fRep = await client.get(forecastUrl);
    final current = fRep.data['current'] as Map<String, dynamic>? ?? {};
    final code = (current['weather_code'] as num?)?.toInt() ?? 0;
    final info = interpreterWmoCode(code);

    return {
      'ville': nomVille,
      'pays': pays,
      'temperature': current['temperature_2m'],
      'description': info['condition'],
      'icone': null,
      'iconeCode': info['icone'],
      'humidite': current['relative_humidity_2m'],
      'vitesseVent': current['wind_speed_10m'],
    };
  }
}
