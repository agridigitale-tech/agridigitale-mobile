import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/design/app_colors.dart';
import '../../core/db_helper.dart';
import '../../services/meteo_service.dart';
import 'meteo_archives_screen.dart';
import 'models/bulletin_meteo.dart';
import 'widgets/togo_map_widget.dart';

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

  BulletinMeteo? _bulletin;
  String? _imageUrl;
  bool _chargement = true;
  bool _erreur = false;
  bool _depuisCache = false;

  // Période sélectionnée (0 = Matinée, 1 = Après-midi, 2 = Nuit)
  int _periodeIndex = 0;

  // Recherche météo ville (OpenWeather)
  Map<String, dynamic>? _villeData;
  bool _rechercheEnCours = false;
  String? _rechercheErreur;
  List<String> _historique = [];
  bool _showHistorique = false;

  @override
  void initState() {
    super.initState();
    // Sélectionne la période actuelle de la journée par défaut
    final heure = DateTime.now().hour;
    if (heure < 12) {
      _periodeIndex = 0;
    } else if (heure < 18) {
      _periodeIndex = 1;
    } else {
      _periodeIndex = 2;
    }

    _charger();
    _chargerHistorique();
    _rechercherVille('Lomé'); // Météo temps réel de la capitale togolaise
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
      debugPrint('[METEO] Réponse reçue');
      final data = rep.data as Map<String, dynamic>;

      final iconeDistante = data['iconeUrl'] as String? ?? '';
      final iconeUpload = data['icone'] as String? ?? '';
      final base = ApiClient.baseUrl.replaceAll('/api', '');
      var url = '';
      if (iconeDistante.isNotEmpty) {
        url = iconeDistante;
      } else if (iconeUpload.startsWith('http')) {
        url = iconeUpload;
      } else if (iconeUpload.isNotEmpty) {
        url = '$base$iconeUpload';
      }

      final b = BulletinMeteo.fromApiResponse(data, url);

      // Sauvegarde semestrielle automatique sur le téléphone (offline 6 mois)
      await _db.sauvegarderBulletinSemestriel(b.toDbMap());
      await _db.sauvegarderMeteoCache('__principale__', url);

      if (mounted) {
        setState(() {
          _bulletin = b;
          _imageUrl = url;
          _chargement = false;
        });
      }
    } catch (e) {
      debugPrint('[METEO] Erreur réseau, chargement du cache local : $e');
      // Tentative de récupération depuis les archives locales du téléphone
      final archives = await _db.getBulletinsSemestriels(limite: 1);
      if (archives.isNotEmpty) {
        final b = BulletinMeteo.fromDbRow(archives.first);
        if (mounted) {
          setState(() {
            _bulletin = b;
            _imageUrl = b.imageUrl;
            _chargement = false;
            _depuisCache = true;
          });
        }
      } else {
        // Fallback avec les prévisions synthétiques nationales
        final fallback = BulletinMeteo.fromApiResponse({}, '');
        if (mounted) {
          setState(() {
            _bulletin = fallback;
            _chargement = false;
            _erreur = false;
            _depuisCache = true;
          });
        }
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

  // Ouvre le document image original en plein écran avec zoom interactif
  void _ouvrirDocumentOriginal() {
    if (_imageUrl == null || _imageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le document original est en cours d\'actualisation.'),
          backgroundColor: AppColors.vertPrimaire,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text('Bulletin Officiel Original', style: TextStyle(fontSize: 16)),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: _imageUrl!,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: AppColors.vertPrimaire),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.white54, size: 60),
                      SizedBox(height: 12),
                      Text('Image non disponible', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bulletin = _bulletin ?? BulletinMeteo.fromApiResponse({}, '');
    final dateStr = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(bulletin.date);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Météo Agricole Togo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          // Bouton Archives semestrielles sauvegardées sur le téléphone
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Archives semestrielles (Hors-ligne)',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MeteoArchivesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: () {
              _charger();
              _rechercherVille(_rechercheCtrl.text.isNotEmpty ? _rechercheCtrl.text : 'Lomé');
            },
          ),
        ],
      ),
      body: _chargement && _bulletin == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire))
          : _erreur && _bulletin == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, size: 48, color: AppColors.grisIcone),
                      const SizedBox(height: 12),
                      const Text('Impossible de charger le bulletin météo'),
                      TextButton(onPressed: _charger, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _charger();
                    await _rechercherVille(_rechercheCtrl.text.isNotEmpty ? _rechercheCtrl.text : 'Lomé');
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
              // ── 1. Barre de recherche de ville ──
              _buildBarreRecherche(isDark),
              const SizedBox(height: 12),

              // ── 2. Résultat de la ville recherchée (ex: Lomé en direct) ──
              if (_rechercheEnCours)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.vertPrimaire),
                  ),
                )
              else if (_rechercheErreur != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _rechercheErreur!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (_villeData != null)
                _buildCarteVille(_villeData!, isDark),

              // ── 3. CARTE SYNTHÈSE MÉTÉO NATIONALE (HERO WEATHER CARD) ──
              _buildCarteSyntheseNationale(bulletin, dateStr, isDark),
              const SizedBox(height: 16),

              // ── 4. CARTE GÉOGRAPHIQUE DU TOGO (VISUELLE & INTERACTIVE) ──
              TogoMapWidget(
                regions: bulletin.regions,
                codeRegionSelectionnee: 'maritime',
                onRegionSelected: (region) {},
              ),
              const SizedBox(height: 16),

              // ── 5. ACCÈS AU BULLETIN ORIGINAL / ARCHIVES ──
              _buildBoutonDocumentOriginal(isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero Card : Synthèse Agro-Météo Nationale ──
  Widget _buildCarteSyntheseNationale(BulletinMeteo b, String dateStr, bool isDark) {
    // Texte de la période sélectionnée
    String textePeriode = b.resumeMatin;
    IconData iconePeriode = Icons.wb_cloudy_outlined;
    if (_periodeIndex == 1) {
      textePeriode = b.resumeApresMidi;
      iconePeriode = Icons.thunderstorm_outlined;
    } else if (_periodeIndex == 2) {
      textePeriode = b.resumeNuit;
      iconePeriode = Icons.nightlight_round_outlined;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E261F), const Color(0xFF151922)]
              : [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : AppColors.vertFonce.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : Badge Officiel + Date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.white, size: 13),
                    SizedBox(width: 5),
                    Text(
                      'ANAMET / AgriDigitale',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_depuisCache)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Mode Hors-ligne',
                    style: TextStyle(color: Colors.amberAccent, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Date en grand
          Text(
            dateStr.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),

          // Titre et Plage des températures
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Prévisions Nationales',
                  style: TextStyle(
                    color: isDark ? AppColors.vertClair : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.thermostat, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${b.tempMin.toInt()}°C – ${b.tempMax.toInt()}°C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sélecteur de période de la journée (Matinée / Après-midi / Nuit)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildPeriodeBouton(0, '🌅 Matinée'),
                _buildPeriodeBouton(1, '🌤️ Après-midi'),
                _buildPeriodeBouton(2, '🌙 Nuit'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Texte descriptif de la période sélectionnée
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Container(
              key: ValueKey<int>(_periodeIndex),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(iconePeriode, color: isDark ? AppColors.vertClair : Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      textePeriode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Conseil Agricole
          if (b.conseilAgricole.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.shade900.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade400.withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates_outlined, color: Colors.amberAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Conseil Agricole du Jour',
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          b.conseilAgricole,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodeBouton(int index, String label) {
    final actif = _periodeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _periodeIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: actif ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: actif ? AppColors.vertFonce : Colors.white70,
              fontSize: 12,
              fontWeight: actif ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ── Bouton Document Image Officiel Original ──
  Widget _buildBoutonDocumentOriginal(bool isDark) {
    return InkWell(
      onTap: _ouvrirDocumentOriginal,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceSombre : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.bordureSombre : const Color(0xFFE5E5E5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.vertClair : AppColors.vertPrimaire).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.image_search_rounded,
                color: isDark ? AppColors.vertClair : AppColors.vertPrimaire,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Consulter le bulletin original',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.texteSombreFort : AppColors.texteFort,
                    ),
                  ),
                  Text(
                    'Afficher l\'infographie officielle en grand format zoomable',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.texteSombreMoyen : AppColors.grisTexte,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.fullscreen_rounded,
              color: isDark ? AppColors.vertClair : AppColors.vertPrimaire,
            ),
          ],
        ),
      ),
    );
  }

  // ── Barre de recherche ──
  Widget _buildBarreRecherche(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _rechercheCtrl,
                decoration: InputDecoration(
                  hintText: 'Rechercher une ville agricole (ex: Kara, Sokodé)...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? AppColors.texteSombreMoyen : AppColors.grisIcone,
                  ),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                backgroundColor: isDark ? AppColors.vertClair : AppColors.vertPrimaire,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _rechercherVille(_rechercheCtrl.text),
              child: const Icon(Icons.search),
            ),
          ],
        ),

        // Historique récent
        if (_showHistorique && _historique.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceSombre : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.bordureSombre : const Color(0xFFE5E5E5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 8,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.history,
                          size: 14,
                          color: isDark ? AppColors.texteSombreMoyen : AppColors.grisIcone),
                      const SizedBox(width: 6),
                      Text(
                        'Recherches récentes',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.texteSombreMoyen : AppColors.grisTexte,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _showHistorique = false),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: isDark ? AppColors.texteSombreMoyen : AppColors.grisIcone,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: isDark ? AppColors.bordureSombre : null),
                ..._historique.map(
                  (v) => ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: isDark ? AppColors.vertClair : AppColors.vertPrimaire,
                    ),
                    title: Text(
                      v,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.texteSombreFort : AppColors.texteFort,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 14,
                        color: isDark ? AppColors.texteSombreMoyen : AppColors.grisIcone,
                      ),
                      onPressed: () => _supprimerHistorique(v),
                    ),
                    onTap: () {
                      _rechercheCtrl.text = v;
                      _rechercherVille(v);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Carte météo ville (ex: Lomé en direct) ──
  Widget _buildCarteVille(Map<String, dynamic> d, bool isDark) {
    final iconeUrl = d['icone'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceSombre : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.bordureSombre : const Color(0xFFEEEEEE),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          if (iconeUrl != null)
            CachedNetworkImage(
              imageUrl: iconeUrl,
              width: 50,
              height: 50,
              placeholder: (_, __) => const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (_, __, ___) => const Icon(Icons.cloud, size: 36),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${d['ville'] ?? ''} (${d['pays'] ?? ''})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? AppColors.texteSombreFort : AppColors.texteFort,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'En direct',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.vertClair : AppColors.vertPrimaire,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  d['description'] ?? '',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppColors.texteSombreMoyen : AppColors.grisTexte,
                  ),
                ),
              ],
            ),
          ),
          if (d['temperature'] != null)
            Text(
              '${(d['temperature'] as num).toStringAsFixed(1)}°C',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.vertClair : AppColors.vertPrimaire,
              ),
            ),
        ],
      ),
    );
  }
}
