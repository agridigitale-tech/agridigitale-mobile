// Écran de célébration "Victoires Quotidiennes" fidèle à la maquette officielle (Image 0).
// Comporte :
// - Ambiance vert forêt / bambou immersive
// - Médaillon circulaire central en bois sculpté avec feuilles vertes et compteur doré
// - Rangée interactive des 7 jours (Sa, Su, Mo, Tu, We, Th, Fr) avec coches dorées et cadeaux
// - Message d'encouragement valorisant
// - Bouton 3D vert "D'accord" avec retour haptique et animation fluide
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/quiz_sound_service.dart';
import '../../services/quiz_tournament_service.dart';

class QuizDailyScreen extends StatefulWidget {
  final int streakJours;
  const QuizDailyScreen({super.key, this.streakJours = 1});

  static Future<void> afficher(BuildContext context, {int streakJours = 1}) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.85),
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => QuizDailyScreen(streakJours: streakJours),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<QuizDailyScreen> createState() => _QuizDailyScreenState();
}

class _QuizDailyScreenState extends State<QuizDailyScreen> with TickerProviderStateMixin {
  final _tournamentService = QuizTournamentService();
  final _soundService = QuizSoundService();

  late AnimationController _badgeAnimController;
  late Animation<double> _badgeScale;
  late Animation<double> _leavesFloat;

  Map<String, bool> _jours = {
    'Sa': true,
    'Su': false,
    'Mo': false,
    'Tu': false,
    'We': false,
    'Th': false,
    'Fr': false,
  };

  @override
  void initState() {
    super.initState();
    _soundService.playVictory();
    _soundService.vibrateHeavy();

    _badgeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _badgeScale = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _badgeAnimController, curve: Curves.easeInOut),
    );

    _leavesFloat = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _badgeAnimController, curve: Curves.easeInOut),
    );

    _chargerJours();
  }

  @override
  void dispose() {
    _badgeAnimController.dispose();
    super.dispose();
  }

  Future<void> _chargerJours() async {
    final j = await _tournamentService.getVictoiresHebdo();
    if (mounted) setState(() => _jours = j);
  }

  @override
  Widget build(BuildContext context) {
    final streak = widget.streakJours > 0 ? widget.streakJours : 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond dégradé vert forêt avec motif bambou
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.2,
                colors: [
                  Color(0xFF1B4D2E), // Vert émeraude au centre
                  Color(0xFF0F301B), // Vert bambou profond
                  Color(0xFF071B0E), // Sombre extérieur
                ],
              ),
            ),
          ),

          // Silhouettes de feuilles de bambou en arrière-plan
          Positioned(
            top: -40,
            right: -30,
            child: Opacity(
              opacity: 0.12,
              child: Transform.rotate(
                angle: 0.4,
                child: const Icon(Icons.park_rounded, size: 240, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -40,
            child: Opacity(
              opacity: 0.10,
              child: Transform.rotate(
                angle: -0.3,
                child: const Icon(Icons.eco_rounded, size: 260, color: Colors.white),
              ),
            ),
          ),

          // Contenu principal centré
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // ── MÉDAILLON EN BOIS SCULPTÉ AVEC FEUILLES & NUMÉRO ──
                  AnimatedBuilder(
                    animation: _badgeAnimController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _badgeScale.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 28,
                            spreadRadius: 4,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
                            blurRadius: 36,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Anneau extérieur en bois sculpté avec arche asiatique/bambou
                          Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [
                                  Color(0xFF2E7D32),
                                  Color(0xFF1B5E20),
                                  Color(0xFF0F3814),
                                ],
                              ),
                              border: Border.all(
                                color: const Color(0xFF81C784),
                                width: 3.5,
                              ),
                            ),
                          ),

                          // Panneau central en bois veiné
                          Container(
                            width: 195,
                            height: 195,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [
                                  Color(0xFF6D4C41), // Bois chaud au centre
                                  Color(0xFF4E342E), // Bois sombre sculpté
                                  Color(0xFF3E2723), // Bordure boisée
                                ],
                              ),
                              border: Border.all(
                                color: const Color(0xFF2E7D32),
                                width: 4.0,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 10,
                                  spreadRadius: -2,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Les deux feuilles vertes flottantes au-dessus du chiffre
                                Positioned(
                                  top: 36,
                                  child: AnimatedBuilder(
                                    animation: _leavesFloat,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(0, _leavesFloat.value),
                                        child: child,
                                      );
                                    },
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Feuille arrière
                                        Transform.rotate(
                                          angle: -0.35,
                                          child: Container(
                                            width: 50,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                                              ),
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(30),
                                                bottomRight: Radius.circular(30),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.3),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Feuille avant lumineuse
                                        Transform.rotate(
                                          angle: 0.25,
                                          child: Container(
                                            width: 62,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF81C784), Color(0xFF43A047)],
                                              ),
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(35),
                                                bottomRight: Radius.circular(35),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF66BB6A).withValues(alpha: 0.6),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Chiffre doré géant du streak
                                Positioned(
                                  bottom: 22,
                                  child: Text(
                                    '$streak',
                                    style: GoogleFonts.poppins(
                                      fontSize: 68,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFFFD54F),
                                      shadows: [
                                        const Shadow(
                                          color: Color(0xFFB78103),
                                          offset: Offset(0, 4),
                                          blurRadius: 4,
                                        ),
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          offset: const Offset(0, 6),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 34),

                  // ── TITRE AVEC LOSANGES DORÉS ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.diamond, color: Color(0xFF81C784), size: 10),
                      const SizedBox(width: 8),
                      Text(
                        'Victoires Quotidiennes',
                        style: GoogleFonts.poppins(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFF1F8E9),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.diamond, color: Color(0xFF81C784), size: 10),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ── RANGÉE DES 7 JOURS HEBDOMADAIRES ──
                  _buildBarreSemaine(),

                  const SizedBox(height: 22),

                  // ── MESSAGE D'ENCOURAGEMENT ──
                  Text(
                    'Vous êtes prêt pour une belle semaine',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE8F5E9),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ── BOUTON 3D VERT "D'ACCORD" ──
                  _buildBoutonDaccord(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarreSemaine() {
    final List<Map<String, dynamic>> joursConfig = [
      {'code': 'Sa', 'label': 'Sa', 'isGift': false},
      {'code': 'Su', 'label': 'Su', 'isGift': false},
      {'code': 'Mo', 'label': 'Mo', 'isGift': false},
      {'code': 'Tu', 'label': 'Tu', 'isGift': true}, // Cadeau palier
      {'code': 'We', 'label': 'We', 'isGift': false},
      {'code': 'Th', 'label': 'Th', 'isGift': false},
      {'code': 'Fr', 'label': 'Fr', 'isGift': true}, // Grand cadeau
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF092013).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF1B5E20).withValues(alpha: 0.8),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Noms des jours (Sa, Su, Mo, Tu, We, Th, Fr)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: joursConfig.map((item) {
              return SizedBox(
                width: 38,
                child: Text(
                  item['label'] as String,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF81C784),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Puces graphiques : Coche dorée, Cercle sombre ou Cadeau 🎁
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: joursConfig.map((item) {
              final code = item['code'] as String;
              final estValide = _jours[code] ?? false;
              final isGift = item['isGift'] as bool;

              if (estValide) {
                // Coche dorée en relief
                return Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFEE58), Color(0xFFFBC02D)],
                    ),
                    border: Border.all(color: const Color(0xFFFFF9C4), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBC02D).withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF3E2723),
                    size: 24,
                  ),
                );
              } else if (isGift) {
                // Cadeau palier vert/doré
                return Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: Color(0xFF2E7D32),
                    size: 32,
                  ),
                );
              } else {
                // Cercle vide vert sombre
                return Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF143820),
                  ),
                );
              }
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBoutonDaccord() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          const BoxShadow(
            color: Color(0xFF1B5E20),
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _soundService.playCorrect();
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF43A047),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: Color(0xFF81C784), width: 2),
          ),
        ),
        child: Text(
          'D\'accord',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: const [
              Shadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}
