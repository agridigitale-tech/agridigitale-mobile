import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api_client.dart';
import '../core/design/app_colors.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});
  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _controleur = PageController(viewportFraction: 0.92, initialPage: 1000);
  int _pageActuelle = 1000;
  List<String> _images = [];
  bool _chargement = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _chargerBannieres();
  }

  Future<void> _chargerBannieres() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('/bannieres');
      final baseServer = ApiClient.baseUrl.replaceAll('/api', '');

      final images = (response.data as List)
          .where((b) => b['image'] != null && (b['image'] as String).isNotEmpty)
          .map((b) {
            final img = b['image'] as String;
            if (img.startsWith('http')) return img;
            return '$baseServer$img';
          })
          .toList();

      setState(() {
        _images = images;
        _chargement = false;
      });

       if (_images.length > 1) {
         _timer?.cancel();
         _timer = Timer.periodic(const Duration(seconds: 5), (_) {
           if (mounted) _pageSuivante();
         });
       }
    } catch (e) {
      debugPrint('[BannerCarousel] Erreur chargement bannières: $e');
      setState(() => _chargement = false);
    }
  }

  void _pageSuivante() {
    if (_images.isEmpty) return;
    _controleur.animateToPage(
      _pageActuelle + 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.vertPrimaire,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_images.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 150,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controleur,
            onPageChanged: (i) => setState(() => _pageActuelle = i),
            itemCount: null,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: _images[i % _images.length],
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
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _images.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: (_pageActuelle % _images.length) == index ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: (_pageActuelle % _images.length) == index
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
