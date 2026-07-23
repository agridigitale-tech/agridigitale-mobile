import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/design/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Modèle de données pour les services
  static const List<Map<String, String>> _services = [
    {
      'title': 'Rédaction de contenus web',
      'description': 'AGRIDIGITALE, vous propose des contenus web de qualité pour améliorer votre référencement dans les résultats des moteurs de recherche et augmenter le nombre de visiteurs sur votre site',
      'icon': 'rss', // On utilisera des icônes Flutter adaptées
    },
    {
      'title': 'Publireportage',
      'description': 'Nous vous offrons des services de vidéo de qualité pour promouvoir vos entreprises, vos produits et services sur les réseaux sociaux',
      'icon': 'video_file',
    },
    {
      'title': 'Réalisation de documentaire',
      'description': 'Un moyen simple qui vous permet de faire connaitre vos projets, votre histoire et vos differentes actions à travers un film professionnel permettant aux clients d\'en apprendre davantage sur vous',
      'icon': 'play',
    },
    {
      'title': 'Spot vidéo et audio',
      'description': 'Cela vous facilite le partage d\'informations sur les réseaux sociaux, afin de communiquer et attirer l\'attention de votre public pour renforcer la notoriété de votre marque',
      'icon': 'play_circle',
    },
    {
      'title': 'Communication digitale',
      'description': 'AGRIDIGITALE, est la solution pour optimiser et développer votre présence en ligne afin d\'atteindre votre public grâce à une stratégie de communication personnalisée',
      'icon': 'trending_up',
    },
    {
      'title': 'Production des émissions',
      'description': 'Avec notre expérience, nous vous aidons à créer, et à promouvoir vos idées grâce à une émission unique et mémorable pour atteindre vos objectifs',
      'icon': 'videocam',
    },
  ];

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'rss': return Icons.rss_feed_rounded;
      case 'video_file': return Icons.video_file_outlined;
      case 'play': return Icons.play_arrow_rounded;
      case 'play_circle': return Icons.play_circle_outline_rounded;
      case 'trending_up': return Icons.trending_up_rounded;
      case 'videocam': return Icons.videocam_outlined;
      default: return Icons.star_border;
    }
  }

  // Affiche la boîte de dialogue du bas (Social Bottom Sheet)
  void _showContactBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: const Color(0xFFF6F5F8), // Fond gris clair rosé très doux comme sur l'image
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nous contacter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              // Première ligne d'icônes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _socialIcon(Icons.facebook, const Color(0xFF1877F2), 'https://www.facebook.com/share/1Q8WFS8Si3/'),
                  _socialIcon(Icons.camera_alt, Colors.black, 'https://www.instagram.com/agridigitale?igsh=NTlvb2ExNjBtdXZ5'),
                  _socialIcon(Icons.play_circle_filled, const Color(0xFFFF0000), 'https://youtube.com/@agridigitaletv?si=hTKMLE-a-jGoYMey'),
                  _socialIcon(Icons.link, const Color(0xFF0A66C2), 'https://www.linkedin.com/company/agridigitale/'),
                ],
              ),
              const SizedBox(height: 20),
              // Deuxième ligne d'icônes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _socialIcon(Icons.close, Colors.black, 'https://x.com/agridigitale1'),
                  _socialIcon(Icons.email, const Color(0xFFEA4335), 'mailto:tech@agridigitale.com'),
                  _socialIcon(Icons.phone_android, const Color(0xFF25D366), 'https://wa.me/72140057'),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _socialIcon(IconData icon, Color color, [String? url]) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 26),
        onPressed: url != null
            ? () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Couleur de fond légèrement rosée/grise claire de votre image
    const scaffoldBgColor = Color(0xFFFAF8FB); 

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: scaffoldBgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nos services',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- LOGO ET ENTÊTE BRANDING ---
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Column(
                          children: [
                            // Placez votre image ici (ou une image réseau temporaire)
                            Image.asset(
                              'assets/images/logo-B.png',
                              height: 150,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.eco, 
                                size: 100, 
                                color: AppColors.vertPrimaire,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'AGRIDIGITALE',
                              style: TextStyle(
                                color: AppColors.vertPrimaire,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'LA REFERENCE AGRICOLE EN AFRIQUE',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Divider(height: 1, thickness: 1),

                    // --- LISTE DES SERVICES ---
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _services.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1),
                      itemBuilder: (context, index) {
                        final service = _services[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Pastille d'icône grise
                              CircleAvatar(
                                backgroundColor: const Color(0xFFE8E8EC),
                                radius: 24,
                                child: Icon(
                                  _getIcon(service['icon']!),
                                  color: const Color(0xFF2C3E50),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Contenu textuel
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service['title']!,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      service['description']!,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: Colors.grey.shade600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // --- BOUTON DE CONTACT PERSISTANT EN BAS ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _showContactBottomSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vertPrimaire,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Nous contacter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}