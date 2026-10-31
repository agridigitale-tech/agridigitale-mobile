// Écran interactif du Roadmap / Monde du Quiz Agricole.
// Design inspiré du Bubble Shooter / Candy Crush :
// - Ciel bleu avec nuages flottants
// - Route sinueuse (S-curve) en sable reliant les niveaux 1 (en bas) à 15 (en haut)
// - Bulles 3D immersives (Bleu brillant pour débloqué, pierre grise pour verrouillé)
// - Étoiles au-dessus des niveaux réussis, halo lumineux & pin joueur "Vous êtes ici !"
// - Coffres aux trésors aux paliers des mondes (Niveaux 3, 6, 9, 12, 15)
// - Panneau de prévisualisation ergonomique avant de lancer un niveau

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design/app_colors.dart';
import '../../data/quiz_data.dart';
import '../../services/quiz_service.dart';
import 'quiz_screen.dart';

class QuizNiveauxScreen extends StatefulWidget {
  static const int kTotalNiveaux = 15;
  const QuizNiveauxScreen({super.key});

  @override
  State<QuizNiveauxScreen> createState() => _QuizNiveauxScreenState();
}

class _QuizNiveauxScreenState extends State<QuizNiveauxScreen> with SingleTickerProviderStateMixin {
  final _quizService = QuizService();
  final _scrollController = ScrollController();

  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;

  int _niveauMax = 1;
  int _totalGrains = 0;
  int _streak = 0;
  Map<int, int> _etoilesMap = {};
  List<String> _badgesDebloques = [];
  bool _chargement = true;

  // Géométrie de la carte
  static const int kTotalNiveaux = QuizNiveauxScreen.kTotalNiveaux;
  static const double kTopPadding = 200.0;
  static const double kStepY = 140.0;
  static const double kBottomPadding = 180.0;
  static const double kTotalHeight = kTopPadding + (kTotalNiveaux - 1) * kStepY + kBottomPadding;

  // Oscillation horizontale de la route (ratio 0.0 = bord gauche, 1.0 = bord droit)
  // Index 0 = Niveau 1 (départ en bas), Index 14 = Niveau 15 (sommet en haut)
  static const List<double> kXRatios = [
    0.50, // N1  (Départ centré en bas)
    0.28, // N2  (Courbe à gauche)
    0.18, // N3  (Palier gauche - Monde 1)
    0.44, // N4  (Vers la droite)
    0.74, // N5  (Courbe à droite)
    0.82, // N6  (Palier droite - Monde 2)
    0.56, // N7  (Vers la gauche)
    0.26, // N8  (Courbe à gauche)
    0.18, // N9  (Palier gauche - Monde 3)
    0.44, // N10 (Vers la droite)
    0.74, // N11 (Courbe à droite)
    0.82, // N12 (Palier droite - Monde 4)
    0.56, // N13 (Vers la gauche)
    0.28, // N14 (Courbe à gauche)
    0.50, // N15 (Sommet centré - Monde 5)
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _chargerDonnees();
    _quizService.changeNotifier.addListener(_chargerDonnees);
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    _quizService.changeNotifier.removeListener(_chargerDonnees);
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    final max = await _quizService.getNiveauMaxDebloque();
    final grains = await _quizService.getTotalGrains();
    final streak = await _quizService.getStreakJours();
    final etoiles = await _quizService.getEtoilesParNiveau();
    final badges = await _quizService.getBadgesDebloques();

    if (mounted) {
      setState(() {
        _niveauMax = max;
        _totalGrains = grains;
        _streak = streak;
        _etoilesMap = etoiles;
        _badgesDebloques = badges;
        _chargement = false;
      });

      // Centrage automatique sur le niveau du joueur après le premier rendu
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollerVersNiveauActuel(anime: false);
      });
    }
  }

  double _calculerYPourNiveau(int niveauId) {
    final index = (niveauId - 1).clamp(0, kTotalNiveaux - 1);
    // Niveau 1 est en bas, Niveau 15 est en haut
    return kTopPadding + (kTotalNiveaux - 1 - index) * kStepY;
  }

  double _calculerXPourNiveau(int niveauId, double screenWidth) {
    final index = (niveauId - 1).clamp(0, kTotalNiveaux - 1);
    const margin = 56.0;
    final trackWidth = screenWidth - (margin * 2);
    return margin + (kXRatios[index] * trackWidth);
  }

  void _scrollerVersNiveauActuel({bool anime = true}) {
    if (!_scrollController.hasClients) return;

    final targetNiveau = _niveauMax.clamp(1, kTotalNiveaux);
    final targetY = _calculerYPourNiveau(targetNiveau);
    final viewportHeight = _scrollController.position.viewportDimension;
    final desiredScroll = (targetY - (viewportHeight / 2) + 33.0).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    if (anime) {
      _scrollController.animateTo(
        desiredScroll,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(desiredScroll);
    }
  }

  void _lancerNiveau(NiveauQuiz niveau) async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: niveau.questions,
          titre: niveau.titre,
          niveauId: niveau.id,
        ),
      ),
    );
    if (res == true) {
      _chargerDonnees();
    }
  }

  void _afficherApercuNiveau(NiveauQuiz niveau, int etoiles) {
    HapticFeedback.lightImpact();

    MondeQuiz? mondeParent;
    for (final m in QuizData.mondes) {
      if (m.niveaux.any((n) => n.id == niveau.id)) {
        mondeParent = m;
        break;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poignée supérieure
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // En-tête Monde
              if (mondeParent != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.vertPrimaire.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(mondeParent.icone, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        'Monde ${mondeParent.id} : ${mondeParent.nom}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.vertFonce,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Titre du Niveau
              Text(
                niveau.titre,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.texteFort,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                niveau.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.grisTexte,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),

              // Étoiles obtenues
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final active = (i < etoiles);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.star_rounded,
                      size: 42,
                      color: active ? Colors.amber : Colors.grey.shade300,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              Text(
                etoiles > 0
                    ? '$etoiles/3 étoiles obtenues'
                    : 'Nouveau défi • Obtenez jusqu\'à 3 étoiles',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: etoiles > 0 ? Colors.amber.shade900 : AppColors.grisTexte,
                ),
              ),
              const SizedBox(height: 24),

              // Piliers de récompense
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6FAF6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grisLigne),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildModalBadge(Icons.timer_outlined, '3 questions', '1 min snack'),
                    _buildModalBadge(Icons.monetization_on_outlined, '+15 à +25', 'Grains 🌾'),
                    _buildModalBadge(Icons.local_fire_department, 'Série +1', 'Boost 🔥'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bouton Jouer
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _lancerNiveau(niveau);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vertPrimaire,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppColors.vertPrimaire.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(etoiles > 0 ? Icons.replay_rounded : Icons.play_arrow_rounded, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        etoiles > 0 ? 'REJOUER LE NIVEAU' : 'JOUER LE NIVEAU',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalBadge(IconData icone, String titre, String sousTitre) {
    return Column(
      children: [
        Icon(icone, color: AppColors.vertPrimaire, size: 22),
        const SizedBox(height: 4),
        Text(titre, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.texteFort)),
        Text(sousTitre, style: GoogleFonts.inter(fontSize: 11, color: AppColors.grisTexte)),
      ],
    );
  }

  void _afficherDialogueNiveauVerrouille(int niveauId) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2C3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        content: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Colors.amber, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Niveau $niveauId verrouillé ! Réussissez d\'abord le Niveau ${niveauId - 1} pour continuer l\'aventure.',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _afficherDialogueCoffre(int mondeId, int niveauPalier) {
    HapticFeedback.mediumImpact();
    final estDebloque = (_niveauMax > niveauPalier);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Text(estDebloque ? '🎁' : '🔒', style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                estDebloque ? 'Coffre du Monde $mondeId Débloqué !' : 'Coffre Mystère du Monde $mondeId',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          estDebloque
              ? 'Félicitations ! Vous avez conquis ce monde agricole. Vos grains et étoiles sont bien au chaud dans votre grange.'
              : 'Ce coffre s\'ouvrira dès que vous aurez réussi le Niveau $niveauPalier. Continuez de grimper la route !',
          style: GoogleFonts.inter(fontSize: 14, height: 1.4, color: AppColors.grisTexte),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Fermer', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.vertPrimaire)),
          ),
        ],
      ),
    );
  }

  void _afficherBadges() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('🏆 Trophées & Badges', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.vertPrimaire.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_badgesDebloques.length}/${QuizService.tousLesBadges.length}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.vertPrimaire, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                itemCount: QuizService.tousLesBadges.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final b = QuizService.tousLesBadges[i];
                  final estDebloque = _badgesDebloques.contains(b.id);
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: estDebloque ? Colors.amber.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: estDebloque ? Colors.amber.shade400 : Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Text(estDebloque ? b.icone : '🔒', style: const TextStyle(fontSize: 30)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.nom,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: estDebloque ? Colors.black87 : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                b.description,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: estDebloque ? AppColors.grisTexte : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (estDebloque)
                          const Icon(Icons.check_circle, color: Colors.green, size: 22),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalEtoiles = _etoilesMap.values.fold(0, (sum, val) => sum + val);

    return Scaffold(
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire))
          : Stack(
              children: [
                // Arrière-plan dégradé Ciel façon Bubble Shooter
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF4CA0F6), // Ciel bleu en haut
                          Color(0xFF67B5FA),
                          Color(0xFF90D5FB),
                          Color(0xFFAEE4FD), // Ciel clair vers le bas
                        ],
                      ),
                    ),
                  ),
                ),

                // Canvas scrollable avec la route en S et les bulles 3D
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = constraints.maxWidth;

                      // Pré-calculer les positions des 15 niveaux
                      final levelPositions = <int, Offset>{};
                      for (int n = 1; n <= kTotalNiveaux; n++) {
                        levelPositions[n] = Offset(
                          _calculerXPourNiveau(n, screenWidth),
                          _calculerYPourNiveau(n),
                        );
                      }

                      return SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        child: SizedBox(
                          width: screenWidth,
                          height: kTotalHeight,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // 1. Dessin de la route sinueuse et des nuages
                              CustomPaint(
                                size: Size(screenWidth, kTotalHeight),
                                painter: _RoadMapPainter(
                                  levelPositions: levelPositions,
                                  screenWidth: screenWidth,
                                ),
                              ),

                              // 2. Panneaux de Mondes et Bannières
                              ..._buildBannieresMondes(screenWidth, levelPositions),

                              // 3. Coffres au trésor aux paliers de mondes
                              ..._buildCoffresTresors(levelPositions),

                              // 4. Les 15 bulles de niveau 3D
                              for (int n = 1; n <= kTotalNiveaux; n++)
                                _buildNiveauBubble(n, levelPositions[n]!),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Barre supérieure fixe avec Stats du Joueur
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildHeaderFlottant(totalEtoiles),
                ),

                // Bouton Flottant "Mon Niveau" pour recentrer immédiatement
                Positioned(
                  right: 16,
                  bottom: 24,
                  child: FloatingActionButton.extended(
                    onPressed: () => _scrollerVersNiveauActuel(anime: true),
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.vertPrimaire,
                    elevation: 5,
                    icon: const Icon(Icons.my_location_rounded, size: 20),
                    label: Text(
                      'Niv. $_niveauMax',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Barre Supérieure Frosted Glass ──
  Widget _buildHeaderFlottant(int totalEtoiles) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 10,
        left: 12,
        right: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton retour si applicable
          if (Navigator.canPop(context))
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.texteFort),
              onPressed: () => Navigator.pop(context),
            )
          else
            const Padding(
              padding: EdgeInsets.only(left: 6, right: 4),
              child: Text('🎮', style: TextStyle(fontSize: 22)),
            ),

          Text(
            'Défi Agricole',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: AppColors.texteFort,
            ),
          ),
          const Spacer(),

          // Pastilles de Stats
          _buildStatPill('⭐', '$totalEtoiles/${QuizData.totalNiveaux * 3}', Colors.amber.shade900, Colors.amber.shade50),
          const SizedBox(width: 6),
          _buildStatPill('🌾', '$_totalGrains', Colors.orange.shade900, Colors.orange.shade50),
          const SizedBox(width: 6),
          _buildStatPill('🔥', '$_streak j', Colors.redAccent.shade700, Colors.red.shade50),
          const SizedBox(width: 6),

          // Trophée Badges
          InkWell(
            onTap: _afficherBadges,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.vertPrimaire.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.emoji_events_rounded, color: AppColors.vertPrimaire, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String emoji, String texte, Color texteColor, Color fondColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: fondColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: texteColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            texte,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: texteColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bulles de Niveaux 3D ──
  Widget _buildNiveauBubble(int niveauId, Offset pos) {
    final estDebloque = (niveauId <= _niveauMax);
    final estNiveauActuel = (niveauId == _niveauMax);
    final etoiles = _etoilesMap[niveauId] ?? 0;
    const bubbleSize = 66.0;

    return Positioned(
      left: pos.dx - (bubbleSize / 2),
      top: pos.dy - (bubbleSize / 2),
      child: SizedBox(
        width: bubbleSize,
        height: bubbleSize + 40, // Espace pour étoiles et badge "Vous êtes ici"
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // A. Halo lumineux pulsant si niveau actuel
            if (estNiveauActuel)
              Positioned(
                top: 20,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: bubbleSize + 16,
                        height: bubbleSize + 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF28B7FE).withValues(alpha: 0.6),
                              blurRadius: 18,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // B. Bouton 3D de la bulle
            Positioned(
              top: 20,
              child: GestureDetector(
                onTap: () {
                  final niveau = QuizData.getNiveau(niveauId);
                  if (niveau == null) return;
                  if (estDebloque) {
                    _afficherApercuNiveau(niveau, etoiles);
                  } else {
                    _afficherDialogueNiveauVerrouille(niveauId);
                  }
                },
                child: SizedBox(
                  width: bubbleSize,
                  height: bubbleSize,
                  child: Stack(
                    children: [
                      // 1. Rebord 3D inférieur (Donne l'aspect relief façon Bubble Shooter)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: bubbleSize - 4,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: estDebloque
                                ? const Color(0xFF095889)
                                : const Color(0xFF5E6B77),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.28),
                                blurRadius: 8,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 2. Corps de la bulle en dégradé
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: bubbleSize - 6,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: estDebloque
                                ? const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF38C5FE), // Cyan vibrant
                                      Color(0xFF0C7BBF), // Bleu profond
                                    ],
                                  )
                                : const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFFA5B2BE), // Gris pierre
                                      Color(0xFF768490),
                                    ],
                                  ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: estDebloque ? 0.45 : 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Reflet spéculaire brillant supérieur (effet bulle de verre)
                              Positioned(
                                top: 4,
                                width: bubbleSize * 0.55,
                                height: 14,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.65),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Numéro ou Cadenas
                              if (estDebloque)
                                Text(
                                  '$niveauId',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    shadows: const [
                                      Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 4),
                                    ],
                                  ),
                                )
                              else
                                const Icon(Icons.lock_rounded, color: Color(0xFF455059), size: 26),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // C. Étoiles au-dessus pour les niveaux complétés (si débloqué et pas le niveau actuel sans étoiles)
            if (estDebloque && etoiles > 0)
              Positioned(
                top: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (starIdx) {
                    final brille = starIdx < etoiles;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: brille ? Colors.amber : Colors.grey.shade400.withValues(alpha: 0.6),
                        shadows: brille
                            ? const [
                                Shadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 2),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ),

            // D. Avatar / Pin joueur animé "Vous êtes ici !" sur le niveau actif
            if (estNiveauActuel)
              Positioned(
                top: -14,
                child: AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _bounceAnimation.value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('📍', style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 3),
                            Text(
                              'Ici !',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Bannières de Début de Monde & Sommet ──
  List<Widget> _buildBannieresMondes(double screenWidth, Map<int, Offset> levelPositions) {
    final widgets = <Widget>[];

    // Bannières entre les mondes
    final separations = [
      (y: levelPositions[1]!.dy + 90, monde: QuizData.mondes[0], label: '🌱 DÉPART : SOLS & PÉPINIÈRES'),
      (y: (levelPositions[3]!.dy + levelPositions[4]!.dy) / 2, monde: QuizData.mondes[1], label: '🌽 MONDE 2 : GRANDES CULTURES'),
      (y: (levelPositions[6]!.dy + levelPositions[7]!.dy) / 2, monde: QuizData.mondes[2], label: '🐄 MONDE 3 : ÉLEVAGE & SANTÉ'),
      (y: (levelPositions[9]!.dy + levelPositions[10]!.dy) / 2, monde: QuizData.mondes[3], label: '🥬 MONDE 4 : MARAÎCHAGE & EAU'),
      (y: (levelPositions[12]!.dy + levelPositions[13]!.dy) / 2, monde: QuizData.mondes[4], label: '💰 MONDE 5 : AGRO-BUSINESS'),
    ];

    for (final sep in separations) {
      widgets.add(
        Positioned(
          top: sep.y - 16,
          left: 20,
          right: 20,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5A2B), Color(0xFFA06D3B)], // Bois chaleureux
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4A373), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 3)),
                ],
              ),
              child: Text(
                sep.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                  shadows: const [
                    Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 2),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Trophée Sommet au-dessus du Niveau 15
    final summitY = levelPositions[15]!.dy - 100;
    widgets.add(
      Positioned(
        top: summitY,
        left: 0,
        right: 0,
        child: Column(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.orange.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Text(
                'SOMMET DE L\'EXPERT AGRICOLE',
                style: GoogleFonts.inter(
                  color: Colors.brown.shade900,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return widgets;
  }

  // ── Coffres aux Trésors aux Paliers (Niveaux 3, 6, 9, 12, 15) ──
  List<Widget> _buildCoffresTresors(Map<int, Offset> levelPositions) {
    final widgets = <Widget>[];
    final paliers = [
      (niveau: 3, mondeId: 1, decalageX: 58.0),
      (niveau: 6, mondeId: 2, decalageX: -58.0),
      (niveau: 9, mondeId: 3, decalageX: 58.0),
      (niveau: 12, mondeId: 4, decalageX: -58.0),
      (niveau: 15, mondeId: 5, decalageX: 58.0),
    ];

    for (final p in paliers) {
      final pos = levelPositions[p.niveau]!;
      final estDebloque = (_niveauMax > p.niveau);

      widgets.add(
        Positioned(
          left: pos.dx + p.decalageX - 22,
          top: pos.dy - 10,
          child: GestureDetector(
            onTap: () => _afficherDialogueCoffre(p.mondeId, p.niveau),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: estDebloque ? Colors.amber.shade100 : Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                border: Border.all(
                  color: estDebloque ? Colors.amber.shade600 : Colors.grey.shade400,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                estDebloque ? '🎁' : '🪙',
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}

// ── CustomPainter pour la Route Sinueuse, les Nuages et la Nature ──
class _RoadMapPainter extends CustomPainter {
  final Map<int, Offset> levelPositions;
  final double screenWidth;

  _RoadMapPainter({required this.levelPositions, required this.screenWidth});

  @override
  void paint(Canvas canvas, Size size) {
    _dessinerNuages(canvas, size);
    _dessinerRoute(canvas, size);
    _dessinerNature(canvas, size);
  }

  void _dessinerNuages(Canvas canvas, Size size) {
    final paintCloud = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    final cloudShade = Paint()
      ..color = const Color(0xFFD4ECFB).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // Coordonnées de quelques nuages flottants
    final clouds = [
      Offset(screenWidth * 0.15, size.height * 0.08),
      Offset(screenWidth * 0.82, size.height * 0.18),
      Offset(screenWidth * 0.12, size.height * 0.32),
      Offset(screenWidth * 0.85, size.height * 0.46),
      Offset(screenWidth * 0.18, size.height * 0.60),
      Offset(screenWidth * 0.84, size.height * 0.74),
      Offset(screenWidth * 0.14, size.height * 0.88),
    ];

    for (final c in clouds) {
      // Ombre légère sous le nuage
      canvas.drawCircle(Offset(c.dx, c.dy + 3), 26, cloudShade);
      canvas.drawCircle(Offset(c.dx - 18, c.dy + 5), 18, cloudShade);
      canvas.drawCircle(Offset(c.dx + 18, c.dy + 5), 18, cloudShade);

      // Corps du nuage blanc
      canvas.drawCircle(c, 26, paintCloud);
      canvas.drawCircle(Offset(c.dx - 18, c.dy + 2), 18, paintCloud);
      canvas.drawCircle(Offset(c.dx + 18, c.dy + 2), 18, paintCloud);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(c.dx, c.dy + 8), width: 56, height: 16),
          const Radius.circular(8),
        ),
        paintCloud,
      );
    }
  }

  void _dessinerRoute(Canvas canvas, Size size) {
    if (levelPositions.length < 2) return;

    // Construction du chemin sinueux C1 continu
    final path = Path();
    final p0 = levelPositions[1]!;

    // Prolongement inférieur sous le Niveau 1
    path.moveTo(p0.dx, p0.dy + 60);
    path.lineTo(p0.dx, p0.dy);

    for (int i = 1; i < QuizNiveauxScreen.kTotalNiveaux; i++) {
      final pStart = levelPositions[i]!;
      final pEnd = levelPositions[i + 1]!;
      final midY = (pStart.dy + pEnd.dy) / 2;

      path.cubicTo(
        pStart.dx, midY,
        pEnd.dx, midY,
        pEnd.dx, pEnd.dy,
      );
    }

    // Prolongement supérieur vers le Sommet
    final pTop = levelPositions[QuizNiveauxScreen.kTotalNiveaux]!;
    path.lineTo(pTop.dx, pTop.dy - 60);

    // 1. Contour / Ombre de la route en sable
    final borderPaint = Paint()
      ..color = const Color(0xFFC99446)
      ..strokeWidth = 42.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, borderPaint);

    // 2. Corps de la route en sable chaleureux (façon Bubble Shooter)
    final sandPaint = Paint()
      ..color = const Color(0xFFFBE49D)
      ..strokeWidth = 34.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, sandPaint);

    // 3. Trait intérieur plus clair
    final innerSandPaint = Paint()
      ..color = const Color(0xFFFFF2C2)
      ..strokeWidth = 24.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, innerSandPaint);

    // 4. Petits galets / pointillés de piste au centre
    final centerDottedPaint = Paint()
      ..color = const Color(0xFFDFB66E)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Dessin de petits points réguliers le long de chaque segment
    for (int i = 1; i < QuizNiveauxScreen.kTotalNiveaux; i++) {
      final pStart = levelPositions[i]!;
      final pEnd = levelPositions[i + 1]!;
      for (double t = 0.25; t <= 0.75; t += 0.25) {
        final midY = (pStart.dy + pEnd.dy) / 2;
        // Formule cubique Bezier à t
        final u = 1 - t;
        final x = u * u * u * pStart.dx +
            3 * u * u * t * pStart.dx +
            3 * u * t * t * pEnd.dx +
            t * t * t * pEnd.dx;
        final y = u * u * u * pStart.dy +
            3 * u * u * t * midY +
            3 * u * t * t * midY +
            t * t * t * pEnd.dy;
        canvas.drawCircle(Offset(x, y), 2.2, centerDottedPaint);
      }
    }
  }

  void _dessinerNature(Canvas canvas, Size size) {
    // Petites touffes d'herbe décoratives aux abords des courbes
    final grassPaint = Paint()
      ..color = const Color(0xFF4CAF50).withValues(alpha: 0.75)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 1; i <= QuizNiveauxScreen.kTotalNiveaux; i += 2) {
      final pos = levelPositions[i]!;
      final cote = (i % 4 == 1) ? 38.0 : -38.0;
      final gx = pos.dx + cote;
      final gy = pos.dy + 12;

      // Brins d'herbe
      canvas.drawLine(Offset(gx, gy), Offset(gx - 4, gy - 8), grassPaint);
      canvas.drawLine(Offset(gx, gy), Offset(gx, gy - 11), grassPaint);
      canvas.drawLine(Offset(gx, gy), Offset(gx + 4, gy - 8), grassPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoadMapPainter oldDelegate) {
    return oldDelegate.levelPositions != levelPositions || oldDelegate.screenWidth != screenWidth;
  }
}
