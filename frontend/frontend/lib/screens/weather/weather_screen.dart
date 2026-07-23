import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/api_client.dart';
import '../../core/design/app_colors.dart';
import 'meteo_archives_screen.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _dio = ApiClient().dio;
  String? _imageUrl;
  bool _chargement = true;
  bool _erreur = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _chargement = true; _erreur = false; });
    try {
      final rep = await _dio.get('/meteo');
      final icone = rep.data['icone'] as String? ?? '';
      final base = ApiClient.baseUrl.replaceAll('/api', '');
      setState(() {
        _imageUrl = icone.startsWith('http') ? icone : '$base$icone';
        _chargement = false;
      });
    } catch (_) {
      setState(() { _chargement = false; _erreur = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Météo Agricole'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Archives météo',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MeteoArchivesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _charger,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: _chargement
            ? const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire))
            : _erreur || _imageUrl == null
                ? ListView(children: [
                    const SizedBox(height: 120),
                    const Icon(Icons.cloud_off, size: 64, color: AppColors.grisIcone),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text('Aucune photo météo disponible',
                          style: TextStyle(fontSize: 16, color: AppColors.grisTexte)),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: _charger,
                        child: const Text('Réessayer'),
                      ),
                    ),
                  ])
                : InteractiveViewer(
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: _imageUrl!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        placeholder: (_, _) => const Center(
                          child: CircularProgressIndicator(color: AppColors.vertPrimaire),
                        ),
                        errorWidget: (_, _, _) => const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 64, color: AppColors.grisIcone),
                            SizedBox(height: 12),
                            Text('Image non disponible',
                                style: TextStyle(color: AppColors.grisTexte)),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
