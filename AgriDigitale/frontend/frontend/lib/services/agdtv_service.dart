// Service AGDTV : récupère les vidéos YouTube d'AgriDigitale TV.
// Utilise l'API backend en priorité, avec un fallback automatique direct vers le flux RSS YouTube
// officiel (channel UCc-oD_vR9ilzlyeZKemRZ-w) sans dépendre de Render ou d'une clé API payante.

import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/video_agdtv.dart';

class AgdtvService {
  final _dio = ApiClient().dio;
  static const String _youtubeChannelId = 'UCc-oD_vR9ilzlyeZKemRZ-w';

  Future<List<VideoAGDTV>> lister() async {
    try {
      final rep = await _dio.get('/agdtv');
      final data = rep.data;
      if (data is List && data.isNotEmpty) {
        return data.map((e) => VideoAGDTV.fromJson(e as Map<String, dynamic>)).toList();
      }
      return await _recupererDepuisYouTubeRss();
    } catch (_) {
      // Fallback transparent direct sur YouTube si Render est en veille ou injoignable
      try {
        return await _recupererDepuisYouTubeRss();
      } catch (err) {
        return [];
      }
    }
  }

  Future<List<VideoAGDTV>> _recupererDepuisYouTubeRss() async {
    final response = await _dio.get<String>(
      'https://www.youtube.com/feeds/videos.xml?channel_id=$_youtubeChannelId',
      options: Options(responseType: ResponseType.plain),
    );
    final xml = response.data ?? '';
    final videos = <VideoAGDTV>[];

    final entryRegex = RegExp(r'<entry>([\s\S]*?)<\/entry>');
    final videoIdRegex = RegExp(r'<yt:videoId>([^<]+)<\/yt:videoId>');
    final titleRegex = RegExp(r'<title>([^<]+)<\/title>');
    final thumbRegex = RegExp(r'<media:thumbnail\s+url="([^"]+)"');

    for (final match in entryRegex.allMatches(xml)) {
      final entry = match.group(1) ?? '';
      final idMatch = videoIdRegex.firstMatch(entry);
      final tMatch = titleRegex.firstMatch(entry);
      final thumbMatch = thumbRegex.firstMatch(entry);

      if (idMatch != null && tMatch != null) {
        final id = idMatch.group(1)!.trim();
        final titre = tMatch.group(1)!.trim();
        final vignette = thumbMatch != null
            ? thumbMatch.group(1)!.trim()
            : 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
        videos.add(VideoAGDTV(idYoutube: id, titre: titre, vignette: vignette));
      }
    }
    return videos;
  }
}