import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/agdtv_service.dart';
import '../../models/video_agdtv.dart';
import '../../core/design/app_colors.dart';
import '../../core/app_localizations.dart';

class AgdtvScreen extends StatefulWidget {
  const AgdtvScreen({super.key});
  @override
  State<AgdtvScreen> createState() => _AgdtvScreenState();
}

class _AgdtvScreenState extends State<AgdtvScreen> {
  final _service = AgdtvService();
  late Future<List<VideoAGDTV>> _future;
  YoutubePlayerController? _controller;
  List<VideoAGDTV> _videos = [];
  int _indexActif = 0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _future = _chargerVideos();
  }

  Future<List<VideoAGDTV>> _chargerVideos() async {
    final videos = await _service.lister();
    if (videos.isNotEmpty && !kIsWeb) {
      // Ne recréer le contrôleur que s'il n'existe pas
      if (_controller == null || _initialized == false) {
        _controller = YoutubePlayerController(
          initialVideoId: videos[0].idYoutube,
          flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
        );
        _initialized = true;
      }
      _videos = videos;
      _indexActif = 0;
    }
    return videos;
  }

  void _jouer(int index) {
    setState(() => _indexActif = index);
    if (!kIsWeb && _controller != null) {
      _controller!.load(_videos[index].idYoutube);
    }
  }

  Future<void> _ouvrirYoutube(String idYoutube) async {
    final url = Uri.parse('https://www.youtube.com/watch?v=$idYoutube');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    // Détruire le contrôleur pour arrêter la vidéo quand on quitte
    _controller?.dispose();
    _controller = null;
    _initialized = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VideoAGDTV>>(
      future: _future,
      builder: (context, snapshot) {
        final videos = snapshot.data ?? [];

        // Sur mobile : envelopper avec YoutubePlayerBuilder dès que le controller existe
        if (!kIsWeb && _controller != null && videos.isNotEmpty) {
          return YoutubePlayerBuilder(
            player: YoutubePlayer(
              controller: _controller!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: AppColors.vertPrimaire,
              onReady: () => debugPrint('[AGDTV] Player prêt'),
            ),
            builder: (context, player) => _buildScaffold(
              context,
              snapshot,
              videos,
              playerWidget: player,
            ),
          );
        }

        return _buildScaffold(context, snapshot, videos);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    AsyncSnapshot<List<VideoAGDTV>> snapshot,
    List<VideoAGDTV> videos, {
    Widget? playerWidget,
  }) {
    return Scaffold(
      backgroundColor: AppColors.fondSombreAGDTV,
      body: SafeArea(
        child: Column(
          children: [
            // En-tête
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(children: [
                Text('AGRIDIGITALE TV',
                    style: GoogleFonts.ptSerif(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(AppLocalizations.of(context).t('agdtv_subtitle'),
                    style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13)),
              ]),
            ),

            // Contenu principal
            if (snapshot.connectionState == ConnectionState.waiting)
              const Expanded(
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.vertPrimaire)),
              )
            else if (snapshot.hasError)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.white54, size: 48),
                      const SizedBox(height: 12),
                      const Text('Erreur de chargement',
                          style: TextStyle(color: Colors.white)),
                      TextButton(
                        onPressed: () {
                            final future = _chargerVideos();
                            setState(() => _future = future);
                          },
                        child: const Text('Réessayer',
                            style:
                                TextStyle(color: AppColors.vertPrimaire)),
                      ),
                    ],
                  ),
                ),
              )
            else if (videos.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('Aucune vidéo disponible',
                      style: TextStyle(color: Colors.white54)),
                ),
              )
            else ...[
              // Zone lecteur
              if (kIsWeb)
                _WebPlayerZone(
                  video: videos[_indexActif],
                  onOuvrir: () =>
                      _ouvrirYoutube(videos[_indexActif].idYoutube),
                )
              else if (playerWidget != null)
                playerWidget
              else
                // Fallback si controller pas encore prêt
                GestureDetector(
                  onTap: () =>
                      _ouvrirYoutube(videos[_indexActif].idYoutube),
                  child: _Thumbnail(
                      video: videos[_indexActif], height: 220),
                ),

              const SizedBox(height: 8),

              // Titre vidéo active
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  videos[_indexActif].titre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ),

              const Divider(color: Colors.white24, height: 16),

              // Liste des vidéos en grille 2 colonnes
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: videos.length,
                  itemBuilder: (context, i) {
                    final v = videos[i];
                    final actif = i == _indexActif;
                    return GestureDetector(
                      onTap: () {
                        if (kIsWeb) {
                          setState(() => _indexActif = i);
                        } else {
                          _jouer(i);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: actif
                              ? Border.all(
                                  color: AppColors.vertPrimaire, width: 2)
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(children: [
                            _Thumbnail(video: v, height: double.infinity),
                            Positioned.fill(
                              child: Container(
                                  color: Colors.black
                                      .withValues(alpha: 0.35)),
                            ),
                            Positioned.fill(
                              child: Center(
                                child: Icon(
                                  actif
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  color: actif
                                      ? Colors.white
                                      : Colors.white70,
                                  size: 36,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.6),
                                padding: const EdgeInsets.all(6),
                                child: Text(v.titre,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Widget miniature YouTube (thumbnail mise en cache pour chargement instantané)
class _Thumbnail extends StatelessWidget {
  final VideoAGDTV video;
  final double? height;
  const _Thumbnail({required this.video, this.height});

  @override
  Widget build(BuildContext context) {
    final url = video.vignette.isNotEmpty
        ? video.vignette
        : 'https://img.youtube.com/vi/${video.idYoutube}/hqdefault.jpg';
    return CachedNetworkImage(
      imageUrl: url,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      memCacheWidth: 400,
      maxWidthDiskCache: 600,
      errorWidget: (context, error, stackTrace) => Container(
        height: height,
        color: Colors.grey[800],
        child: const Icon(Icons.play_circle, color: Colors.white54, size: 40),
      ),
    );
  }
}

// Zone player Web
class _WebPlayerZone extends StatelessWidget {
  final VideoAGDTV video;
  final VoidCallback onOuvrir;
  const _WebPlayerZone({required this.video, required this.onOuvrir});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOuvrir,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _Thumbnail(video: video, height: 200),
          Container(
            width: double.infinity,
            height: 200,
            color: Colors.black.withValues(alpha: 0.4),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle_filled,
                  color: Colors.white, size: 64),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Ouvrir sur YouTube',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
