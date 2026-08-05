//permet de gérer les vidéos AGDTV (lister) en utilisant l'API backend.

import '../core/api_client.dart';
import '../models/video_agdtv.dart';

class AgdtvService {
  final _dio = ApiClient().dio;
  Future<List<VideoAGDTV>> lister() async {
    final rep = await _dio.get('/agdtv');
    return (rep.data as List).map((e) => VideoAGDTV.fromJson(e)).toList();
  }
}