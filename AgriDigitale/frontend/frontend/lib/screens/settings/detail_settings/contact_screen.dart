import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/design/app_colors.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const String _email = 'agridigitale@gmail.com';
  static const String _telephone = '+228 92 96 88 03';
  static const String _siteWeb = 'https://agridigitale.net';
  static const String _adresse = 'Lomé, Togo';

  Future<void> _ouvrirEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _email,
      query: 'subject=Contact depuis l application AgriDigitale',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _ouvrirTelephone() async {
    final uri = Uri(scheme: 'tel', path: _telephone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _ouvrirWhatsApp() async {
    final uri = Uri.parse('https://wa.me/22892968803');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _ouvrirSite() async {
    final uri = Uri.parse(_siteWeb);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildContactTile({
    required IconData icone,
    required Color couleur,
    required String titre,
    required String valeur,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: couleur.withValues(alpha: 0.1),
              child: Icon(icone, color: couleur, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valeur,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Contactez-nous',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // En-tête
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.vertPrimaire.withValues(alpha: 0.1),
                    child: const Icon(Icons.support_agent, size: 40, color: AppColors.vertPrimaire),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nous sommes là pour vous aider',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'N\'hésitez pas à nous contacter via l\'un des moyens ci-dessous.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Coordonnées en texte brut (exigence Google Play)
            _buildContactTile(
              icone: Icons.email_outlined,
              couleur: const Color(0xFFEA4335),
              titre: 'Email',
              valeur: _email,
              onTap: _ouvrirEmail,
            ),
            _buildContactTile(
              icone: Icons.phone_outlined,
              couleur: const Color(0xFF25D366),
              titre: 'Téléphone',
              valeur: _telephone,
              onTap: _ouvrirTelephone,
            ),
            _buildContactTile(
              icone: Icons.chat_bubble_outline,
              couleur: const Color(0xFF25D366),
              titre: 'WhatsApp',
              valeur: _telephone,
              onTap: _ouvrirWhatsApp,
            ),
            _buildContactTile(
              icone: Icons.language,
              couleur: const Color(0xFF1565C0),
              titre: 'Site web',
              valeur: _siteWeb,
              onTap: _ouvrirSite,
            ),
            _buildContactTile(
              icone: Icons.location_on_outlined,
              couleur: const Color(0xFFE65100),
              titre: 'Adresse',
              valeur: _adresse,
              onTap: () {},
            ),

            const SizedBox(height: 32),

            // Affichage brut des coordonnées (texte visible, pas seulement icônes)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coordonnées complètes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Email : agridigitale@gmail.com',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Téléphone : +228 92 96 88 03 / 98 24 30 43',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Site web : https://agridigitale.net',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Adresse : Lomé, Togo',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
