import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/api_client.dart';
import '../../core/design/app_colors.dart';
import '../../core/db_helper.dart';
import '../../services/meteo_service.dart';
import 'meteo_archives_screen.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _dio = ApiClient().dio;
  final _meteoService = MeteoService();
  final _db = DBHelper();
  final _rechercheCtrl = TextEditingController();

  String? _imageUrl;
  bool _chargement = true;
  bool _erreur = false;
  bool _depuisCache = false;

  // Recherche ville
  Map<String, dynamic>? _villeData;
  bool _rechercheEnCours = false;
  String? _rechercheErreur;
  List<String> _historique = [];
  bool _showHistorique = false;

  @override
  void initState() {
    super.initState();
    _charger();
    _chargerHistorique();
  }

  @override
  void dispose() {
    _rechercheCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerHistorique() async {
    final h = await _db.getHistoriqueVilles();
    if (mounted) setState(() => _historique = h);
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = false;
      _depuisCache = false;
    });
    try {
      final rep = await _dio.get('/meteo');
      final icone = rep.data['icone'] as String? ?? '';
      final base = ApiClient.baseUrl.replaceAll('/api', '');
      final url = icone.startsWith('http') ? icone : '$base$icone';

      // Sauvegarder en cache local
      await _db.sauvegarderMeteoCache('__principale__', url);

      if (mounted) {
        setState(() {
          _imageUrl = url;
          _chargement = false;
        });
      }
    } catch (_) {
      // Tenter le cache local
      final cached = await _db.getMeteoCache('__principale__');
      if (mounted) {
        setState(() {
          _imageUrl = cached;
          _chargement = false;
          _erreur = cached == null;
          _depuisCache = cached != null;
        });
      }
    }
  }

  Future<void> _rechercherVille(String ville) async {
    final v = ville.trim();
    if (v.isEmpty) return;
    setState(() {
      _rechercheEnCours = true;
      _rechercheErreur = null;
      _showHistorique = false;
    });
    try {
      final data = await _meteoService.rechercherVille(v);
      await _db.ajouterVilleHistorique(v);
      await _chargerHistorique();
      if (mounted) {
        setState(() {
          _villeData = data;
          _rechercheEnCours = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _rechercheErreur = e.toString().contains('404')
              ? 'Ville introuvable'
              : 'Erreur de connexion';
          _rechercheEnCours = false;
        });
      }
    }
  }

  Future<void> _supprimerHistorique(String ville) async {
    await _db.supprimerVilleHistorique(ville);
    await _chargerHistorique();
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Barre de recherche ville ──
            _barreRecherche(),
            const SizedBox(height: 16),

            // ── Résultat recherche ville ──
            if (_rechercheEnCours)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.vertPrimaire),
              ))
            else if (_rechercheErreur != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_rechercheErreur!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center),
              )
            else if (_villeData != null)
              _carteVille(_villeData!),

            const SizedBox(height: 8),

            // ── Photo météo principale ──
            if (_depuisCache)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(children: [
                  Icon(Icons.offline_bolt, size: 16, color: Colors.orange),
                  SizedBox(width: 6),
                  Text('Affichage hors-ligne (cache local)',
                      style: TextStyle(fontSize: 12, color: Colors.orange)),
                ]),
              ),

            _chargement
                ? const Center(
                    child: Padding(
                    padding: EdgeInsets.all(40),
                    child:
                        CircularProgressIndicator(color: AppColors.vertPrimaire),
                  ))
                : _erreur || _imageUrl == null
                    ? Column(children: [
                        const SizedBox(height: 40),
                        const Icon(Icons.cloud_off,
                            size: 64, color: AppColors.grisIcone),
                        const SizedBox(height: 16),
                        const Text('Aucune photo météo disponible',
                            style: TextStyle(
                                fontSize: 16, color: AppColors.grisTexte),
                            textAlign: TextAlign.center),
                        TextButton(
                            onPressed: _charger,
                            child: const Text('Réessayer')),
                      ])
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: _imageUrl!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          placeholder: (context, url) => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(
                                  color: AppColors.vertPrimaire),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image,
                                  size: 64, color: AppColors.grisIcone),
                              SizedBox(height: 12),
                              Text('Image non disponible',
                                  style:
                                      TextStyle(color: AppColors.grisTexte)),
                            ],
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _barreRecherche() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _rechercheCtrl,
              decoration: InputDecoration(
                hintText: 'Rechercher une ville agricole...',
                prefixIcon: const Icon(Icons.search, color: AppColors.grisIcone),
                suffixIcon: _rechercheCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _rechercheCtrl.clear();
                          setState(() {
                            _villeData = null;
                            _rechercheErreur = null;
                            _showHistorique = false;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) {
                setState(() => _showHistorique = v.isEmpty && _historique.isNotEmpty);
              },
              onSubmitted: _rechercherVille,
              textInputAction: TextInputAction.search,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vertPrimaire,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _rechercherVille(_rechercheCtrl.text),
            child: const Icon(Icons.search, color: Colors.white),
          ),
        ]),

        // ── Historique ──
        if (_showHistorique && _historique.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(children: [
                    const Icon(Icons.history,
                        size: 14, color: AppColors.grisIcone),
                    const SizedBox(width: 6),
                    const Text('Recherches récentes',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.grisTexte)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _showHistorique = false),
                      child: const Icon(Icons.close,
                          size: 14, color: AppColors.grisIcone),
                    ),
                  ]),
                ),
                const Divider(height: 1),
                ..._historique.map((v) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on_outlined,
                          size: 16, color: AppColors.grisIcone),
                      title: Text(v,
                          style: const TextStyle(
                              fontSize: 13,
                              textBaseline: TextBaseline.alphabetic)),
                      trailing: IconButton(
                        icon: const Icon(Icons.close,
                            size: 14, color: AppColors.grisIcone),
                        onPressed: () => _supprimerHistorique(v),
                      ),
                      onTap: () {
                        _rechercheCtrl.text = v;
                        _rechercherVille(v);
                      },
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _carteVille(Map<String, dynamic> d) {
    final iconeUrl = d['icone'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07), blurRadius: 10)
        ],
      ),
      child: Row(children: [
        if (iconeUrl != null)
          CachedNetworkImage(
            imageUrl: iconeUrl,
            width: 56,
            height: 56,
            placeholder: (context, url) => const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(strokeWidth: 2)),
            errorWidget: (context, url, error) => const Icon(Icons.cloud,
                size: 40, color: AppColors.grisIcone),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '${d['ville'] ?? ''} (${d['pays'] ?? ''})',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              d['description'] ?? '',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.grisTexte),
            ),
          ]),
        ),
        if (d['temperature'] != null)
          Text(
            '${(d['temperature'] as num).toStringAsFixed(1)}°C',
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.vertPrimaire),
          ),
      ]),
    );
  }
}
