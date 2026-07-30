import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/api_client.dart';
import '../../core/design/app_colors.dart';

class MeteoArchivesScreen extends StatefulWidget {
  const MeteoArchivesScreen({super.key});
  @override
  State<MeteoArchivesScreen> createState() => _MeteoArchivesScreenState();
}

class _MeteoArchivesScreenState extends State<MeteoArchivesScreen> {
  final _dio = ApiClient().dio;
  List<dynamic> _archives = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    try {
      final rep = await _dio.get('/meteo/archives');
      setState(() {
        _archives = rep.data as List;
        _chargement = false;
      });
    } catch (_) {
      setState(() => _chargement = false);
    }
  }

  String _urlImage(String img) {
    if (img.isEmpty) return '';
    if (img.startsWith('http')) return img;
    return '${ApiClient.baseUrl.replaceAll('/api', '')}$img';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archives météo'),
        backgroundColor: AppColors.vertPrimaire,
        foregroundColor: Colors.white,
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire))
          : _archives.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, size: 64, color: AppColors.grisIcone),
                      SizedBox(height: 12),
                      Text('Aucune archive disponible',
                          style: TextStyle(color: AppColors.grisTexte, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _archives.length,
                    itemBuilder: (context, i) {
                      final a = _archives[i];
                      final url = _urlImage(a['icone'] ?? '');
                      final date = a['dateMiseAJour'] != null
                          ? DateTime.tryParse(a['dateMiseAJour'])
                          : null;
                      final dateStr = date != null
                          ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                          : '';
                      return GestureDetector(
                        onTap: () => _voirPlein(context, url, dateStr),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[100],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                            color: AppColors.vertPrimaire, strokeWidth: 2),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[100],
                                      child: const Icon(Icons.broken_image,
                                          color: AppColors.grisIcone, size: 40),
                                    ),
                                  ),
                                ),
                              ),
                              if (dateStr.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                  child: Text(
                                    dateStr,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.grisTexte,
                                        fontWeight: FontWeight.w500),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _voirPlein(BuildContext context, String url, String date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(date, style: const TextStyle(color: Colors.white)),
          ),
          body: InteractiveViewer(
            child: Center(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image,
                    color: Colors.white, size: 64),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
