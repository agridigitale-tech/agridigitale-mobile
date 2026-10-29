// Carousel de bannières publicitaires chargées depuis le backend.
// Défilement automatique toutes les 5 secondes. Clic → ouvre le lien externe si présent.
// Si aucune bannière active n'est présente, le widget disparaît complètement (SizedBox.shrink).
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_client.dart';
import '../core/design/app_colors.dart';

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

  // Charge les bannières depuis l'API et démarre le timer de défilement si plusieurs bannières
  Future<void> _chargerBannieres() async {
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

      setState(() {
        _bannieres = bannieres;
      });

      if (_bannieres.length > 1) {
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 5), (_) {
          if (mounted) _pageSuivante();
        });
      } else {
        _timer?.cancel();
      }
    } catch (e) {
      debugPrint('[BannerCarousel] Erreur chargement bannières: $e');
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
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si aucune bannière active n'est présente (ou pendant le chargement initial),
    // afficher la page comme si la bannière n'existait pas du tout (0 pixel, 0 espace).
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
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _bannieres.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: (_pageActuelle % _bannieres.length) == index ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: (_pageActuelle % _bannieres.length) == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
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
