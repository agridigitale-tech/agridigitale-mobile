// Barre supérieure unifiée pour l'aventure Jungle Quiz Adventure.
// Reproduit fidèlement la barre vue sur les trois écrans :
// - Avatar Germain avec bordure lumineuse et pilule nom/niveau (ou Logo Agri Digitale Quiz)
// - Compteur de pièces d'or ($ 2 350) avec bouton '+'
// - Compteur de gemmes violettes (75) avec bouton '+'
// - Bouton réglages (roue crantée)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizJungleTopBar extends StatelessWidget {
  final String userName;
  final int niveau;
  final int pieces;
  final int gemmes;
  final bool afficherLogo;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onAddCoinsTap;
  final VoidCallback? onAddGemsTap;

  const QuizJungleTopBar({
    super.key,
    this.userName = 'Germain_Ahobli',
    this.niveau = 7,
    this.pieces = 2350,
    this.gemmes = 75,
    this.afficherLogo = false,
    this.onSettingsTap,
    this.onAddCoinsTap,
    this.onAddGemsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Section Gauche : Logo OU Avatar + Nom/Niveau ──
            if (afficherLogo) ...[
              _buildLogoAgriDigitale(),
              const SizedBox(width: 8),
              _buildPiluleProfilCompact(),
            ] else ...[
              _buildPiluleProfilEtendue(),
            ],

            const SizedBox(width: 8),

            // ── Section Pièces d'Or ──
            _buildCompteurPieces(),

            const SizedBox(width: 6),

            // ── Section Gemmes Violettes ──
            if (!afficherLogo) ...[
              _buildCompteurGemmes(),
              const SizedBox(width: 6),
            ],

            // ── Section Réglages ──
            _buildBoutonReglages(context),
          ],
        ),
      ),
    );
  }

  /// Logo officiel "Agri Digitale Quiz" pour l'écran Roadmap
  Widget _buildLogoAgriDigitale() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Agri Digitale',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.1,
                shadows: [const Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
            Text(
              'Quiz',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFFD54F),
                height: 1.1,
                shadows: [const Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Profil compact avec avatar rond
  Widget _buildPiluleProfilCompact() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xDD0D2A2A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF26A69A), width: 1.4),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatarRond(26),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userName.length > 10 ? '${userName.substring(0, 10)}...' : userName,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFFCA28), size: 12),
                  const SizedBox(width: 2),
                  Text(
                    'Niveau $niveau',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFCA28),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Profil étendu avec avatar débordant à gauche
  Widget _buildPiluleProfilEtendue() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 12, 3),
      decoration: BoxDecoration(
        color: const Color(0xDD0A2326),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF00E676), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatarRond(34),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userName,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFFCA28), size: 13),
                  const SizedBox(width: 2),
                  Text(
                    'Niveau $niveau',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFFCA28),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Avatar rond avec bordure dorée éclatante
  Widget _buildAvatarRond(double taille) {
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFD54F), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/germain_avatar.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF2E7D32),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  /// Compteur de pièces d'or ($ 2 350)
  Widget _buildCompteurPieces() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xDD0D2A2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB300), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pièce d'or brillante
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFFEE58), Color(0xFFFF8F00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Text(
                '\$',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _formaterNombre(pieces),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          // Bouton '+' vert
          Container(
            width: 17,
            height: 17,
            decoration: BoxDecoration(
              color: const Color(0xFF00E676),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E676).withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 13),
          ),
        ],
      ),
    );
  }

  /// Compteur de gemmes violettes (💎 75)
  Widget _buildCompteurGemmes() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xDD0D2A2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFAB47BC), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Diamant violet
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFE1BEE7), Color(0xFF8E24AA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.diamond_rounded, color: Colors.white, size: 13),
          ),
          const SizedBox(width: 5),
          Text(
            _formaterNombre(gemmes),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          // Bouton '+' vert
          Container(
            width: 17,
            height: 17,
            decoration: BoxDecoration(
              color: const Color(0xFF00E676),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E676).withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 13),
          ),
        ],
      ),
    );
  }

  /// Bouton Réglages (Roue crantée)
  Widget _buildBoutonReglages(BuildContext context) {
    return InkWell(
      onTap: onSettingsTap ?? () => _afficherDialogueReglages(context),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xDD0D2A2A),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30, width: 1.2),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  void _afficherDialogueReglages(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B3B2B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF00E676), width: 1.5),
        ),
        title: Text(
          'Options du Quiz',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.volume_up_rounded, color: Color(0xFFFFD54F)),
              title: const Text('Effets sonores', style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676)),
            ),
            ListTile(
              leading: const Icon(Icons.vibration_rounded, color: Color(0xFFFFD54F)),
              title: const Text('Retour haptique', style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('FERMER', style: TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formaterNombre(int n) {
    if (n >= 1000) {
      final s = n.toString();
      final r = s.substring(s.length - 3);
      final l = s.substring(0, s.length - 3);
      return '$l $r';
    }
    return n.toString();
  }
}
