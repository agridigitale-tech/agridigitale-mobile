//permet d'afficher les vidéos de la chaîne Youtube AGRIDIGITALE TV et lire les vidéos dans l'application Youtube

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/agdtv_service.dart';
import '../../models/video_agdtv.dart';
import '../../core/design/app_colors.dart';

class AgdtvScreen extends StatefulWidget {
  const AgdtvScreen({super.key});
  @override
  State<AgdtvScreen> createState() => _AgdtvScreenState();
}

class _AgdtvScreenState extends State<AgdtvScreen> {
  final _service = AgdtvService();
  late Future<List<VideoAGDTV>> _future;

  @override
  void initState() { super.initState(); _future = _service.lister(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondSombreAGDTV,
      body: SafeArea(
        child: FutureBuilder<List<VideoAGDTV>>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire));
            }
            final videos = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              children: [
                const Text('AGRIDIGITALE TV', textAlign: TextAlign.center, style: TextStyle(
                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text('The digital agricultural channel of the future', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 15)),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vertPrimaire,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => launchUrl(Uri.parse('https://www.youtube.com/@AGRIDIGITALETV')),
                    child: const Text('Ouvrir sur Youtube', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
                if (videos.isEmpty)
                  const Padding(padding: EdgeInsets.only(top: 40),
                    child: Center(child: Text('Aucune vidéo disponible pour le moment',
                      style: TextStyle(color: Colors.white54))))
                else
                  ...videos.map((v) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () => launchUrl(Uri.parse(v.urlYoutube), mode: LaunchMode.externalApplication),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(children: [
                          Image.network(v.vignette, width: double.infinity, height: 180, fit: BoxFit.cover),
                          Positioned(
                            left: 0, right: 0, bottom: 0,
                            child: Container(
                              color: Colors.black.withOpacity(0.55),
                              padding: const EdgeInsets.all(12),
                              child: Text(v.titre, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  )),
              ],
            );
          },
        ),
      ),
    );
  }
}