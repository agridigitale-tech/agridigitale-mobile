import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api_client.dart';  

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});
  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _controleur = PageController(viewportFraction: 0.92);
  int _pageActuelle = 0;
  List<String> _images = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerBannieres();
  }

  Future<void> _chargerBannieres() async {
    try {
      // ✅ Utilisation correcte de ApiClient
      final apiClient = ApiClient(); // Crée une instance
      final response = await apiClient.dio.get('/bannieres');
      
      final images = (response.data as List)
          .where((b) => b['image'] != null && b['image'].isNotEmpty)
          .map((b) => b['image'] as String)
          .toList();
      
      setState(() {
        _images = images;
        _chargement = false;
      });

      if (_images.length > 1) {
        _demarrerDefilementAuto();
      }
    } catch (e) {
      print('❌ Erreur chargement bannières: $e');
      setState(() {
        _chargement = false;
      });
    }
  }

  void _demarrerDefilementAuto() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _pageSuivante();
        _demarrerDefilementAuto();
      }
    });
  }

  void _pageSuivante() {
    if (_images.isEmpty) return;
    int pageSuivante = _pageActuelle + 1;
    if (pageSuivante >= _images.length) {
      pageSuivante = 0;
    }
    _controleur.animateToPage(
      pageSuivante,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2E7D32),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_images.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 150,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controleur,
            onPageChanged: (i) {
              setState(() {
                _pageActuelle = i;
              });
            },
            itemCount: _images.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: _images[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
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
                  width: _pageActuelle == index ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _pageActuelle == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }
}