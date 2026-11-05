// Écran de Victoire & Célébration de l'Ego fidèle à la maquette officielle (Image 2).
// Intègre :
// - En-tête avec compteur de QI ("IQ: 149.7") et boutons retour / menu
// - Lotus doré radieux avec volutes orientales et aura étincelante
// - Grand titre lumineux en dégradé d'or : "Incroyable !"
// - 3 cartes métriques : temps (04:27), IQ (149.7 👑), Combo (28)
// - Phrase de valorisation de l'ego avec séparateurs dorés
// - Jauge segmentée vers le palier coffre ("Atteindre le niveau 110")
// - Bouton néon 3D ambré "LUCKY 💡x2 ↩️x2"
// - Bouton 3D vert "Niveau 106 🎴x2"
// - Barre inférieure de boosters (Mélange, Annuler, Indice, Retour)
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/quiz_sound_service.dart';
import '../../services/quiz_tournament_service.dart';
import 'quiz_league_screen.dart';

class QuizVictoryScreen extends StatefulWidget {
  final int tempsSecondes;
  final double iqScore;
  final int combo;
  final int niveau;
  final int etoiles;
  final int grainsGagnes;
  final VoidCallback? onSuivant;
  final VoidCallback? onVoirLigue;

  const QuizVictoryScreen({
    super.key,
    this.tempsSecondes = 267, // 04:27 par défaut
    this.iqScore = 149.7,
    this.combo = 28,
    this.niveau = 105,
    this.etoiles = 3,
    this.grainsGagnes = 30,
    this.onSuivant,
    this.onVoirLigue,
  });

  static Future<void> afficher(
    BuildContext context, {
    int tempsSecondes = 267,
    double iqScore = 149.7,
    int combo = 28,
    int niveau = 105,
    int etoiles = 3,
    int grainsGagnes = 30,
    VoidCallback? onSuivant,
    VoidCallback? onVoirLigue,
  }) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => QuizVictoryScreen(
          tempsSecondes: tempsSecondes,
          iqScore: iqScore,
          combo: combo,
          niveau: niveau,
          etoiles: etoiles,
          grainsGagnes: grainsGagnes,
          onSuivant: onSuivant,
          onVoirLigue: onVoirLigue,
        ),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  State<QuizVictoryScreen> createState() => _QuizVictoryScreenState();
}

class _QuizVictoryScreenState extends State<QuizVictoryScreen> with TickerProviderStateMixin {
  final _tournamentService = QuizTournamentService();
  final _soundService = QuizSoundService();

  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _raysAnimation;

  bool _luckyReclame = false;

  @override
  void initState() {
    super.initState();
    _soundService.playVictory();
    _soundService.vibrateHeavy();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _raysAnimation = CurvedAnimation(parent: _rotationController, curve: Curves.linear);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formaterTemps(int totalSecs) {
    final minutes = totalSecs ~/ 60;
    final seconds = totalSecs % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _reclamerBonusLucky() async {
    if (_luckyReclame) return;
    HapticFeedback.heavyImpact();
    _soundService.playCorrect();

    await _tournamentService.modifierBooster('hint', 2);
    await _tournamentService.modifierBooster('undo', 2);

    if (mounted) {
      setState(() {
        _luckyReclame = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const Icon(Icons.stars_rounded, color: Color(0xFFFFD54F), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bonus LUCKY réclamé : +2 Indices 💡 et +2 Retours ↩️ !',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final niveauSuivant = widget.niveau + 1;
    final palierCoffre = ((widget.niveau ~/ 10) + 1) * 10;
    final progressionPalier = (widget.niveau % 10) + 1; // e.g. 6 sur 10

    return Scaffold(
      backgroundColor: const Color(0xFF04120C),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fond Ambiance Sombre & Rayons Dorés Célestes ──
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.45),
                radius: 0.95,
                colors: [
                  Color(0xFF1E3A24), // Halo vert émeraude doux au centre haut
                  Color(0xFF071B12),
                  Color(0xFF030D08),
                ],
              ),
            ),
          ),

          // Lueur dorée douce au centre
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFB74D).withValues(alpha: 0.28),
                      const Color(0xFFFFA000).withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Rayons de soleil célestes tournants
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Center(
              child: RotationTransition(
                turns: _raysAnimation,
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: CustomPaint(
                    painter: _SunburstRaysPainter(),
                  ),
                ),
              ),
            ),
          ),

          // ── Contenu Principal Défilable ──
          SafeArea(
            child: Column(
              children: [
                // En-tête supérieur
                _buildEnTete(),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 6),

                          // Illustration du Lotus Doré & Volutes
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: _buildLotusHero(),
                          ),

                          const SizedBox(height: 4),

                          // Grand titre en dégradé d'or : Incroyable !
                          _buildTitreIncroyable(),

                          const SizedBox(height: 18),

                          // Les 3 Cartes Métriques (temps, IQ, Combo)
                          _buildCartesMetriques(),

                          const SizedBox(height: 18),

                          // Phrase de valorisation de l'égo (psychologie du succès)
                          _buildCitationEgo(),

                          const SizedBox(height: 20),

                          // Barre de progression vers le Coffre (10 segments)
                          _buildJaugeVersCoffre(progressionPalier, palierCoffre),

                          const SizedBox(height: 18),

                          // Bouton 3D Ambré LUCKY
                          _buildBoutonLucky(),

                          const SizedBox(height: 12),

                          // Bouton 3D Vert Niveau Suivant
                          _buildBoutonNiveauSuivant(niveauSuivant),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── En-tête : Retour, Score IQ, Menu ──
  Widget _buildEnTete() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bouton retour rond marron
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF381F14), Color(0xFF1B0E09)],
                ),
                border: Border.all(color: const Color(0xFF6B4423), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Color(0xFFFFB74D), size: 22),
            ),
          ),

          // Score IQ doré central
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'IQ: ${widget.iqScore.toStringAsFixed(1)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFFD54F),
                  letterSpacing: 0.6,
                  shadows: [
                    Shadow(color: const Color(0xFFFFB300).withValues(alpha: 0.6), blurRadius: 8),
                  ],
                ),
              ),
            ],
          ),

          // Bouton menu rond marron
          GestureDetector(
            onTap: () {
              // Ouvre le tournoi virtuel de la ligue
              QuizLeagueScreen.afficher(context);
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF381F14), Color(0xFF1B0E09)],
                ),
                border: Border.all(color: const Color(0xFF6B4423), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.leaderboard_rounded, color: Color(0xFFFFB74D), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Illustration Lotus Doré & Volutes Orientales ──
  Widget _buildLotusHero() {
    return SizedBox(
      width: 240,
      height: 140,
      child: CustomPaint(
        painter: _GoldenLotusPainter(),
      ),
    );
  }

  // ── Titre "Incroyable !" en dégradé d'or flamboyant ──
  Widget _buildTitreIncroyable() {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF9C4), // Blanc doré étincelant en haut
            Color(0xFFFFD54F), // Or chaud
            Color(0xFFFF8F00), // Ambre orangé
          ],
        ).createShader(bounds);
      },
      child: Text(
        'Incroyable !',
        style: GoogleFonts.cinzel(
          fontSize: 44,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1.2,
          shadows: [
            Shadow(
              color: const Color(0xFFFF6F00).withValues(alpha: 0.9),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
            const Shadow(
              color: Colors.black,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }

  // ── Les 3 Cartes Métriques (temps, IQ, Combo) ──
  Widget _buildCartesMetriques() {
    return Row(
      children: [
        // Carte 1 : Temps
        Expanded(
          child: _buildCarteStat(
            titre: 'temps',
            valeur: _formaterTemps(widget.tempsSecondes),
            icone: null,
          ),
        ),
        const SizedBox(width: 10),

        // Carte 2 : IQ avec couronne dorée
        Expanded(
          child: _buildCarteStat(
            titre: 'IQ',
            valeur: widget.iqScore.toStringAsFixed(1),
            iconeCouronne: true,
          ),
        ),
        const SizedBox(width: 10),

        // Carte 3 : Combo
        Expanded(
          child: _buildCarteStat(
            titre: 'Combo',
            valeur: '${widget.combo}',
            icone: null,
          ),
        ),
      ],
    );
  }

  Widget _buildCarteStat({
    required String titre,
    required String valeur,
    IconData? icone,
    bool iconeCouronne = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B0F09), // Fond chocolat noir très sombre
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF5A381E),
          width: 1.6,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Titre (temps / IQ / Combo)
          Text(
            titre,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFD7CCC8),
            ),
          ),
          const SizedBox(height: 4),

          // Valeur avec éventuelle couronne
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                valeur,
                style: GoogleFonts.poppins(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              if (iconeCouronne) ...[
                const SizedBox(width: 4),
                const Text(
                  '👑',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Phrase de valorisation de l'ego avec séparateurs ──
  Widget _buildCitationEgo() {
    return Column(
      children: [
        // Séparateur supérieur avec losange doré
        _buildSeparateurDore(),

        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Les niveaux difficiles ne sont qu’un échauffement pour vous !',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFFF3E0),
              height: 1.35,
              letterSpacing: 0.2,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Séparateur inférieur avec losange doré
        _buildSeparateurDore(),
      ],
    );
  }

  Widget _buildSeparateurDore() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Color(0xFFFFB74D)],
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.diamond_rounded, size: 8, color: Color(0xFFFFD54F)),
        const SizedBox(width: 6),
        Container(
          width: 60,
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFB74D), Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }

  // ── Jauge Segmentée vers le Coffre ──
  Widget _buildJaugeVersCoffre(int rempli, int niveauCible) {
    const totalSegments = 10;
    final int segmentsRemplis = math.min(totalSegments, math.max(0, rempli));

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Barre à 10 segments
            Row(
              children: List.generate(totalSegments, (i) {
                final estRempli = i < segmentsRemplis;
                return Container(
                  width: 18,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: estRempli
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFFCA28), Color(0xFFFF8F00)],
                          )
                        : null,
                    color: estRempli ? null : const Color(0xFF261911),
                    border: Border.all(
                      color: estRempli ? const Color(0xFFFFE082) : const Color(0xFF3E2723),
                      width: 1,
                    ),
                    boxShadow: estRempli
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF8F00).withValues(alpha: 0.6),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),

            const SizedBox(width: 10),

            // Coffre au trésor / Coffret japonais fleuri
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const RadialGradient(
                  colors: [Color(0xFF8D2B1C), Color(0xFF4A1008)],
                ),
                border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: const Center(
                child: Text('🧰', style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Sous-titre jauge
        Text(
          'Atteindre le niveau $niveauCible',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFFE082),
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Bouton Néon 3D Ambré LUCKY ──
  Widget _buildBoutonLucky() {
    return Column(
      children: [
        // Mot "LUCKY" néon multicolore
        ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [
                Color(0xFF00E676), // Vert néon
                Color(0xFFFFEB3B), // Jaune
                Color(0xFFFF4081), // Rose magenta
                Color(0xFFE040FB), // Violet électrique
              ],
            ).createShader(bounds);
          },
          child: Text(
            'LUCKY ✨',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: Colors.white,
              shadows: [
                Shadow(color: const Color(0xFFFF4081).withValues(alpha: 0.8), blurRadius: 10),
              ],
            ),
          ),
        ),

        const SizedBox(height: 4),

        GestureDetector(
          onTap: _luckyReclame ? null : _reclamerBonusLucky,
          child: Container(
            width: double.infinity,
            height: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _luckyReclame
                    ? [const Color(0xFF757575), const Color(0xFF424242)]
                    : [
                        const Color(0xFFFFB74D), // Ambre clair
                        const Color(0xFFFF9800), // Orange vif
                        const Color(0xFFE65100), // Ombre 3D
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: (_luckyReclame ? Colors.black38 : const Color(0xFFE65100)).withValues(alpha: 0.8),
                  blurRadius: 0,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône vidéo / clapperboard
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.movie_filter_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),

                // Bonus 💡x2
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4E2600).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_rounded, color: Color(0xFFFFEB3B), size: 22),
                      const SizedBox(width: 4),
                      Text(
                        'x2',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Bonus ↩️x2
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4E2600).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.replay_rounded, color: Color(0xFFFFD54F), size: 22),
                      const SizedBox(width: 4),
                      Text(
                        'x2',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Bouton 3D Vert "Niveau 106 🎴x2" ──
  Widget _buildBoutonNiveauSuivant(int niveauSuivant) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            _soundService.playCorrect();

            Navigator.pop(context);
            if (widget.onSuivant != null) {
              widget.onSuivant!();
            } else if (widget.onVoirLigue != null) {
              widget.onVoirLigue!();
            } else {
              // Par défaut ouvre l'écran de la ligue pour admirer la montée en rang !
              QuizLeagueScreen.afficher(context);
            }
          },
          child: Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF66BB6A), // Vert clair
                  Color(0xFF43A047), // Vert forêt vif
                  Color(0xFF2E7D32), // Vert profond
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.95),
                  blurRadius: 0,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tuile / Plante
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white38, width: 1),
                  ),
                  child: const Center(
                    child: Text('🌾', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),

                // Texte "Niveau 106"
                Text(
                  'Niveau $niveauSuivant',
                  style: GoogleFonts.poppins(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Étiquette violette suspendue "x2"
        Positioned(
          top: -10,
          right: 18,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFAB47BC), Color(0xFF7B1FA2)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE1BEE7), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.style_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  'x2',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Peintre du Lotus Doré & Volutes Orientales (Image 2) ──
class _GoldenLotusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.72;

    // 1. Rayonnement d'aura doré derrière
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD54F).withValues(alpha: 0.45),
          const Color(0xFFFF8F00).withValues(alpha: 0.20),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy - 20), radius: 65));
    canvas.drawCircle(Offset(cx, cy - 20), 65, glowPaint);

    // 2. Volutes orientales décoratives sur les côtés
    final swirlPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..shader = const LinearGradient(
        colors: [Color(0xFF81C784), Color(0xFFFFD54F), Color(0xFFFF8F00)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Volute gauche
    final pathGauche = Path();
    pathGauche.moveTo(cx - 30, cy + 10);
    pathGauche.cubicTo(cx - 70, cy + 20, cx - 90, cy - 10, cx - 110, cy + 5);
    pathGauche.cubicTo(cx - 115, cy + 10, cx - 100, cy + 25, cx - 80, cy + 18);
    canvas.drawPath(pathGauche, swirlPaint);

    // Volute droite (symétrique)
    final pathDroite = Path();
    pathDroite.moveTo(cx + 30, cy + 10);
    pathDroite.cubicTo(cx + 70, cy + 20, cx + 90, cy - 10, cx + 110, cy + 5);
    pathDroite.cubicTo(cx + 115, cy + 10, cx + 100, cy + 25, cx + 80, cy + 18);
    canvas.drawPath(pathDroite, swirlPaint);

    // 3. Pétales extérieurs du lotus
    _dessinerPetale(canvas, cx, cy, angleDeg: -40, longueur: 52, largeur: 18, alpha: 0.85);
    _dessinerPetale(canvas, cx, cy, angleDeg: 40, longueur: 52, largeur: 18, alpha: 0.85);
    _dessinerPetale(canvas, cx, cy, angleDeg: -22, longueur: 64, largeur: 20, alpha: 0.92);
    _dessinerPetale(canvas, cx, cy, angleDeg: 22, longueur: 64, largeur: 20, alpha: 0.92);

    // Pétale central majestueux
    _dessinerPetale(canvas, cx, cy, angleDeg: 0, longueur: 72, largeur: 24, alpha: 1.0);

    // 4. Cœur lumineux du lotus
    final coeurPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFFFEB3B), Color(0xFFFF8F00)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy - 8), radius: 14));
    canvas.drawCircle(Offset(cx, cy - 8), 9, coeurPaint);
  }

  void _dessinerPetale(
    Canvas canvas,
    double cx,
    double cy, {
    required double angleDeg,
    required double longueur,
    required double largeur,
    required double alpha,
  }) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angleDeg * math.pi / 180);

    final path = Path();
    path.moveTo(0, 0);
    // Courbe gauche du pétale
    path.cubicTo(-largeur, -longueur * 0.45, -largeur * 0.7, -longueur * 0.85, 0, -longueur);
    // Courbe droite du pétale
    path.cubicTo(largeur * 0.7, -longueur * 0.85, largeur, -longueur * 0.45, 0, 0);

    // Remplissage dégradé or chaud
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFFF8F00).withValues(alpha: alpha * 0.9),
          const Color(0xFFFFD54F).withValues(alpha: alpha),
          const Color(0xFFFFF9C4).withValues(alpha: alpha),
        ],
      ).createShader(Rect.fromLTWH(-largeur, -longueur, largeur * 2, longueur));
    canvas.drawPath(path, fillPaint);

    // Ligne de crête dorée au centre du pétale
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 0), Offset(0, -longueur * 0.85), linePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Rayons de Soleil Célestes ──
class _SunburstRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rayonMax = size.width * 0.48;

    final rayPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD54F).withValues(alpha: 0.18),
          const Color(0xFFFF8F00).withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: rayonMax));

    const nbRayons = 16;
    const double angleParRayon = (2 * math.pi) / nbRayons;

    for (int i = 0; i < nbRayons; i++) {
      final double angle = i * angleParRayon;
      final path = Path();
      path.moveTo(cx, cy);
      path.lineTo(
        cx + rayonMax * math.cos(angle - 0.07),
        cy + rayonMax * math.sin(angle - 0.07),
      );
      path.lineTo(
        cx + rayonMax * math.cos(angle + 0.07),
        cy + rayonMax * math.sin(angle + 0.07),
      );
      path.close();
      canvas.drawPath(path, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
