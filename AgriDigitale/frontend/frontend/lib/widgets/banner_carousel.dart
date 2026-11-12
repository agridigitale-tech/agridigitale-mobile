// Carousel de bannières publicitaires chargées depuis le backend.
// Défilement automatique toutes les 5 secondes. Clic → ouvre le lien externe si présent.
// Si aucune bannière active n'est présente, le widget disparaît complètement (SizedBox.shrink).
import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_client.dart';
import '../core/db_helper.dart';
import '../core/design/app_colors.dart';
import 'home_skeleton_loading.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  /// Notifier global pour demander le rafraîchissement immédiat des bannières
  static final ValueNotifier<int> rafraichirNotifier = ValueNotifier<int>(0);

  /// Déclenche le rechargement de la liste des bannières sur l'accueil
  static void actualiser() {
    rafraichirNotifier.value++;
  }

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _controleur =
      PageController(viewportFraction: 0.92, initialPage: 1000);
  int _pageActuelle = 1000;
  List<Map<String, String?>> _bannieres = [];
  bool _chargement = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    BannerCarousel.rafraichirNotifier.addListener(_surDemandeRafraichissement);
    _chargerBannieres();
  }

  void _surDemandeRafraichissement() {
    if (mounted) {
      _chargerBannieres();
    }
  }

  // Charge les bannières locales depuis le cache hors ligne SQLite
  Future<void> _chargerBannieresDepuisCache() async {
    if (kIsWeb) return;
    try {
      final cached = await DBHelper().getBannieresCache();
      if (cached.isNotEmpty && mounted) {
        setState(() {
          _bannieres = cached;
          _chargement = false;
        });
        debugPrint('[BannerCarousel] ${cached.length} bannières chargées depuis le cache hors ligne SQLite');
      }
    } catch (e) {
      debugPrint('[BannerCarousel] Erreur chargement cache bannières: $e');
    }
  }

  void _demarrerTimer() {
    _timer?.cancel();
    if (_bannieres.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) _pageSuivante();
      });
    }
  }

  // Charge les bannières depuis l'API et démarre le timer de défilement si plusieurs bannières
  Future<void> _chargerBannieres() async {
    // Tenter immédiatement de lire le cache hors ligne pour un affichage instantané
    await _chargerBannieresDepuisCache();

    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('/bannieres');
      final baseServer = ApiClient.baseUrl.replaceAll('/api', '');

      final rawList = response.data is List ? response.data as List : [];
      final bannieres = rawList
          .where((b) =>
              b != null &&
              b['image'] != null &&
              (b['image'] as String).isNotEmpty)
          .map((b) {
            final img = b['image'] as String;
            final imageUrl = img.startsWith('http') ? img : '$baseServer$img';
            final lien = b['lien'] as String?;
            return <String, String?>{'image': imageUrl, 'lien': lien};
          })
          .toList();

      if (!mounted) return;

      if (bannieres.isNotEmpty) {
        setState(() {
          _bannieres = bannieres;
          _chargement = false;
        });

        // Sauvegarder dans SQLite pour la prochaine session hors ligne
        if (!kIsWeb) {
          try {
            await DBHelper().sauvegarderBannieres(bannieres);
          } catch (_) {}
        }
      }

      _demarrerTimer();
    } catch (e) {
      debugPrint('[BannerCarousel] Mode hors ligne / réseau indisponible ($e), bannières actuelles: ${_bannieres.length}');
      if (_bannieres.isEmpty) {
        await _chargerBannieresDepuisCache();
      }
      _demarrerTimer();
    } finally {
      if (mounted) {
        setState(() => _chargement = false);
      }
    }
  }

  void _pageSuivante() {
    if (_bannieres.length <= 1) return;
    _controleur.animateToPage(
      _pageActuelle + 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    BannerCarousel.rafraichirNotifier.removeListener(_surDemandeRafraichissement);
    _timer?.cancel();
    _controleur.dispose();
    super.dispose();
  }

  Widget _buildCarteBanniere(Map<String, String?> b,
      {EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 4)}) {
    final imageUrl = b['image'] ?? '';
    final lien = b['lien'];
    final hasLien = lien != null && lien.isNotEmpty;

    return Padding(
      padding: padding,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.06),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            onTap: hasLien
                ? () async {
                    final uri = Uri.tryParse(lien);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  }
                : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Fond flouté d'ambiance reprenant les couleurs de la bannière
                if (imageUrl.isNotEmpty)
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Transform.scale(
                      scale: 1.15, // Évite les contours blancs provoqués par le flou aux bords
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 1080,
                        maxWidthDiskCache: 1200,
                        placeholder: (_, __) => const SizedBox.shrink(),
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),

                // 2. Voile d'atténuation subtil pour adoucir le fond et donner du relief
                Container(
                  color: Colors.black.withValues(alpha: 0.12),
                ),

                // 3. Image entière au premier plan : dézoomée pour afficher 100% de la bannière sans rognage
                Center(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    memCacheWidth: 1080,
                    maxWidthDiskCache: 1200,
                    placeholder: (context, url) => Container(
                      color: Colors.transparent,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.vertPrimaire,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: AppColors.grisIcone,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si les bannières sont en cours de chargement initial, afficher le squelette shimmer
    if (_chargement && _bannieres.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 150,
        child: const ShimmerProvider(
          child: SkeletonBox(
            width: double.infinity,
            height: 150,
            radius: 12,
          ),
        ),
      );
    }

    // Si aucune bannière active n'est présente, ne rien afficher
    if (_bannieres.isEmpty) {
      return const SizedBox.shrink();
    }

    // S'il n'y a qu'une seule bannière, l'afficher directement sans carrousel ni points
    if (_bannieres.length == 1) {
      return Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        height: 150,
        child: _buildCarteBanniere(
          _bannieres.first,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      );
    }

    // Plusieurs bannières : carrousel animé avec défilement et indicateurs
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      height: 150,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controleur,
            onPageChanged: (i) => setState(() => _pageActuelle = i),
            itemCount: null,
            itemBuilder: (context, i) {
              final b = _bannieres[i % _bannieres.length];
              return _buildCarteBanniere(b);
            },
          ),
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    _bannieres.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: (_pageActuelle % _bannieres.length) == index ? 14 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: (_pageActuelle % _bannieres.length) == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
