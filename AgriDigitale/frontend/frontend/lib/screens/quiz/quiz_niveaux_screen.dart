// Écran interactif du Roadmap / Monde du Quiz Agricole (100 Niveaux).
// Design inspiré du Bubble Shooter / Candy Crush :
// - Ciel bleu avec nuages flottants
// - Route sinueuse (S-curve) en sable reliant les niveaux 1 (en bas) à 100 (au sommet)
// - Bulles 3D immersives (Bleu brillant pour débloqué, pierre grise pour verrouillé)
// - Étoiles au-dessus des niveaux réussis, halo lumineux & pin joueur "Vous êtes ici !"
// - Coffres aux trésors aux paliers des 10 mondes (Niveaux 10, 20, 30, ..., 100)
// - Panneau de prévisualisation ergonomique avant de lancer un niveau
// - Barre supérieure anti-débordement avec FittedBox responsive

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design/app_colors.dart';
import '../../data/quiz_data.dart';
import '../../models/quiz_grade.dart';
import '../../services/quiz_service.dart';
import '../../services/quiz_sound_service.dart';
import '../../widgets/quiz/quiz_rank_up_dialog.dart';
import 'quiz_screen.dart';
import 'quiz_jungle_top_bar.dart';
import 'quiz_jungle_ranks_bar.dart';
import 'quiz_league_screen.dart';
import 'quiz_daily_screen.dart';

class QuizNiveauxScreen extends StatefulWidget {
  static int get kTotalNiveaux => QuizData.totalNiveaux;
  const QuizNiveauxScreen({super.key});

  @override
  State<QuizNiveauxScreen> createState() => _QuizNiveauxScreenState();
}

class _QuizNiveauxScreenState extends State<QuizNiveauxScreen> with TickerProviderStateMixin {
  final _quizService = QuizService();
  final _soundService = QuizSoundService();
  final _scrollController = ScrollController();

  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;

  // Animation d'entrée spectaculaire pour le roadmap du jeu
  late AnimationController _entranceController;
  late Animation<double> _topOffsetAnimation;
  late Animation<double> _bottomOffsetAnimation;
  late Animation<double> _opacityAnimation;

  int _niveauMax = 1;
  int _totalGrains = 0;
  int _streak = 0;
  Map<int, int> _etoilesMap = {};
  List<String> _badgesDebloques = [];
  QuizGrade _gradeActuel = QuizGrade.tousLesGrades.first;
  bool _chargement = true;

  // Géométrie de la carte
  static int get kTotalNiveaux => QuizData.totalNiveaux;
  static const double kTopPadding = 200.0;
  static const double kStepY = 115.0;
  static const double kBottomPadding = 180.0;
  double get kTotalHeight => kTopPadding + (kTotalNiveaux - 1) * kStepY + kBottomPadding;

  // Oscillation serpentine harmonieuse et continue (0.0 = bord gauche, 1.0 = bord droit)
  static double getXRatio(int index) {
    if (index == 0 || index >= kTotalNiveaux - 1) return 0.50; // Niveaux 1 et 100 centrés

    // Amortissement doux au départ (niveaux 1-3) et à l'arrivée (niveaux 97-100)
    double taper = 1.0;
    if (index < 3) taper = index / 3.0;
    if (index > kTotalNiveaux - 4) taper = (kTotalNiveaux - 1 - index) / 3.0;

    // Onde sinusoïdale continue et ample (période de 7 niveaux pour de beaux virages amples)
    final angle = index * (2 * math.pi / 7.0);
    return (0.50 + 0.33 * math.sin(angle) * taper).clamp(0.16, 0.84);
  }

  @override
  void initState() {
    super.initState();
    _soundService.init();
    _soundService.setEstSurEcranJeu(true);

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

    // Initialisation de l'animation d'arrivée du monde du jeu (-700px et +700px)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _topOffsetAnimation = Tween<double>(
      begin: -700.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
      ),
    );

    _bottomOffsetAnimation = Tween<double>(
      begin: 700.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Déclenchement dès que le rendu écran est prêt pour être 100% visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _entranceController.forward(from: 0.0);
      }
    });

    _chargerDonnees();
    _quizService.changeNotifier.addListener(_chargerDonnees);
  }

  @override
  void dispose() {
    _animController.dispose();
    _entranceController.dispose();
    _scrollController.dispose();
    _soundService.setEstSurEcranJeu(false);
    _soundService.stopAll();
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
        _gradeActuel = QuizGrade.getGradePourNiveau(max);
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
    // Niveau 1 est en bas, Niveau 100 est en haut
    return kTopPadding + (kTotalNiveaux - 1 - index) * kStepY;
  }

  double _calculerXPourNiveau(int niveauId, double screenWidth) {
    final index = (niveauId - 1).clamp(0, kTotalNiveaux - 1);
    const margin = 56.0;
    final trackWidth = screenWidth - (margin * 2);
    return margin + (getXRatio(index) * trackWidth);
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

    final grade = QuizGrade.getGradePourNiveau(niveau.id);

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
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
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
              const SizedBox(height: 14),

              // Bannière Illustration en ligne thématique du niveau / grade
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        grade.illustrationUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: grade.couleurFond,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                color: grade.couleur,
                                strokeWidth: 2.5,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: grade.degrade,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Icon(grade.icone, size: 48, color: Colors.white.withValues(alpha: 0.85)),
                            ),
                          );
                        },
                      ),
                      // Filtre progressif pour le contraste des pastilles
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                      // Pastilles Grade et Monde (Anti-collision et anti-débordement)
                      Positioned(
                        top: 10,
                        left: 10,
                        right: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(grade.icone, size: 13, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        grade.titre.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 10.5,
                                          color: Colors.white,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (mondeParent != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: grade.couleur.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(mondeParent.iconeData, size: 13, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Monde ${mondeParent.id}',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Nom de zone en bas de l'illustration
                      Positioned(
                        left: 12,
                        bottom: 8,
                        child: Text(
                          grade.nomZone,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                            shadows: const [
                              Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Écriture du niveau en GRAND et GRAS
              Text(
                'NIVEAU ${niveau.id}',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: grade.couleur,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),

              // Titre du Niveau
              Text(
                niveau.titre,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.texteFort,
                ),
              ),
              const SizedBox(height: 6),

              // Description
              Text(
                niveau.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.grisTexte,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),

              // Étoiles obtenues
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final active = (i < etoiles);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(
                      Icons.star_rounded,
                      size: 38,
                      color: active ? Colors.amber : Colors.grey.shade300,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
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
              const SizedBox(height: 16),

              // Piliers de récompense (Zéro émoticône)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6FAF6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grisLigne),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildModalBadge(Icons.timer_outlined, '3 questions', '1 min')),
                    Expanded(child: _buildModalBadge(Icons.grain_rounded, '+15 à +25', 'Grains')),
                    Expanded(child: _buildModalBadge(Icons.local_fire_department_rounded, 'Série +1', 'Boost')),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Bouton Jouer aux couleurs du Grade
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _lancerNiveau(niveau);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: grade.couleur,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: grade.couleur.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(etoiles > 0 ? Icons.replay_rounded : Icons.play_arrow_rounded, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        etoiles > 0 ? 'REJOUER LE NIVEAU' : 'COMMENCER LE NIVEAU',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
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
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(titre, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.texteFort)),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(sousTitre, style: GoogleFonts.inter(fontSize: 11, color: AppColors.grisTexte)),
        ),
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
            Icon(
              estDebloque ? Icons.card_giftcard_rounded : Icons.lock_rounded,
              size: 28,
              color: estDebloque ? Colors.amber.shade800 : Colors.blueGrey,
            ),
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
                const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Trophées & Badges',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
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
                        Icon(
                          estDebloque ? b.icone : Icons.lock_rounded,
                          size: 28,
                          color: estDebloque ? Colors.amber.shade800 : Colors.grey.shade400,
                        ),
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

  void _afficherModalGrades() {
    HapticFeedback.lightImpact();
    final prochain = QuizGrade.getProchainGrade(_niveauMax);
    final restants = QuizGrade.getNiveauxRestants(_niveauMax);
    final progression = QuizGrade.getProgressionVersProchainGrade(_niveauMax);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poignée supérieure
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            // En-tête
            Row(
              children: [
                const Icon(Icons.military_tech_rounded, size: 24, color: AppColors.vertPrimaire),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Les 10 Grades Agricoles',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.vertPrimaire.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Niv. $_niveauMax/100',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.vertPrimaire, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Carte du Grade Actuel avec barre de progression vers le prochain rang
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_gradeActuel.couleurFond, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _gradeActuel.couleur, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _gradeActuel.couleur.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: _gradeActuel.couleur.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Icon(_gradeActuel.icone, size: 28, color: _gradeActuel.couleur),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VOTRE RANG ACTUEL',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: _gradeActuel.couleur,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              _gradeActuel.titre,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.texteFort),
                            ),
                            Text(
                              _gradeActuel.sousTitre,
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.grisTexte),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _gradeActuel.description,
                    style: GoogleFonts.inter(fontSize: 12.5, color: Colors.black87, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  if (prochain != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Prochain rang : ${prochain.titre}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: prochain.couleur),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$restants niveau${restants > 1 ? 'x' : ''} restant${restants > 1 ? 's' : ''}',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.grisTexte, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progression,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(prochain.couleur),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.workspace_premium_rounded, size: 18, color: Colors.amber.shade900),
                          const SizedBox(width: 6),
                          Text(
                            'Rang Suprême Débloqué ! Vous êtes une Légende.',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Bouton pour afficher la célébration festive de ce grade
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      QuizRankUpDialog.afficher(context, nouveauGrade: _gradeActuel);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: _gradeActuel.degrade),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _gradeActuel.couleur.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.workspace_premium_rounded, size: 18, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Voir la Célébration de Rang',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'L\'Échelle de Progression (10 Grades)',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.texteFort),
            ),
            const SizedBox(height: 8),

            // Liste des 10 grades
            Expanded(
              child: ListView.separated(
                itemCount: QuizGrade.tousLesGrades.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final g = QuizGrade.tousLesGrades[i];
                  final estAtteint = (_niveauMax >= g.niveauRequis);
                  final estActuel = (g.titre == _gradeActuel.titre);

                  return GestureDetector(
                    onTap: estAtteint
                        ? () {
                            Navigator.pop(ctx);
                            QuizRankUpDialog.afficher(context, nouveauGrade: g);
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: estActuel
                            ? g.couleurFond
                            : (estAtteint ? Colors.grey.shade50 : Colors.grey.shade100.withValues(alpha: 0.6)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: estActuel
                              ? g.couleur
                              : (estAtteint ? g.couleur.withValues(alpha: 0.4) : Colors.grey.shade300),
                          width: estActuel ? 1.8 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: g.couleur.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(g.icone, size: 22, color: g.couleur),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        g.titre,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                          color: estAtteint ? AppColors.texteFort : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                    if (estActuel) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: g.couleur,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Actuel',
                                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${g.sousTitre} • Requis : Niv. ${g.niveauRequis}',
                                  style: GoogleFonts.inter(fontSize: 11, color: estAtteint ? AppColors.grisTexte : Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          if (estAtteint)
                            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)
                          else
                            Icon(Icons.lock_rounded, color: Colors.grey.shade400, size: 18),
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

  @override
  Widget build(BuildContext context) {
    final totalEtoiles = _etoilesMap.values.fold(0, (sum, val) => sum + val);

    return Scaffold(
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire))
          : Stack(
              children: [
                // ── Fond Jungle Visuel Immersif (Misty Sunbeams in a Lush Rainforest) ──
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/quiz_jungle_roadmap_bg.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF0F3827),
                            Color(0xFF0A231C),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Voile sombre progressif pour sublimer les rayons solaires et faire ressortir la route
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.28),
                          Colors.black.withValues(alpha: 0.12),
                          Colors.black.withValues(alpha: 0.28),
                        ],
                      ),
                    ),
                  ),
                ),

                // Canvas scrollable avec la route en S et les 100 bulles 3D
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = constraints.maxWidth;

                      // Pré-calculer les positions des 100 niveaux
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
                              // 1. Dessin de la route sinueuse organique, dorée & élégante
                              CustomPaint(
                                size: Size(screenWidth, kTotalHeight),
                                painter: _RoadMapPainter(
                                  levelPositions: levelPositions,
                                  screenWidth: screenWidth,
                                  totalNiveaux: kTotalNiveaux,
                                  niveauMax: _niveauMax,
                                ),
                              ),

                              // Panneau en bois sur la gauche (comme sur la maquette)
                              if (levelPositions.containsKey(1))
                                Positioned(
                                  top: levelPositions[1]!.dy - 70,
                                  left: 12,
                                  child: _buildPanneauSignalisationBois(),
                                ),

                              // Indicateur "^ Jusqu'au Niveau 100" au-dessus du niveau 3
                              if (levelPositions.containsKey(3))
                                Positioned(
                                  top: levelPositions[3]!.dy - 70,
                                  left: levelPositions[3]!.dx - 45,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 22),
                                      Text(
                                        'Jusqu\'au\nNiveau 100',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          height: 1.1,
                                          shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // 2. Panneaux de Mondes et Bannières
                              ..._buildBannieresMondes(screenWidth, levelPositions),

                              // 3. Coffres au trésor aux paliers des mondes
                              ..._buildCoffresTresors(screenWidth, levelPositions),

                              // 4. Les 100 bulles de niveau 3D
                              for (int n = 1; n <= kTotalNiveaux; n++)
                                _buildNiveauBubble(n, levelPositions[n]!),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Barre supérieure fixe avec Stats du Joueur & Rangs (surgit de -700px)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _entranceController,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _topOffsetAnimation.value),
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: child,
                      ),
                    ),
                    child: _buildHeaderFlottant(totalEtoiles),
                  ),
                ),

                // Bouton indicateur en bas de l'écran "Fais défiler pour continuer..." (surgit de +700px)
                Positioned(
                  bottom: 16,
                  left: 20,
                  right: 20,
                  child: AnimatedBuilder(
                    animation: _entranceController,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _bottomOffsetAnimation.value),
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: child,
                      ),
                    ),
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _scrollerVersNiveauActuel(anime: true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8D5B28), Color(0xFF5D3A1A)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFFFD54F), size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'Fais défiler pour continuer jusqu\'au niveau 100',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  shadows: const [Shadow(color: Colors.black45, blurRadius: 2)],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Boutons Flottants Rapides : Tournoi / Ligue & Quotidien
                Positioned(
                  left: 16,
                  bottom: 68,
                  child: Row(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'fab_league',
                        onPressed: () => QuizLeagueScreen.afficher(context),
                        backgroundColor: const Color(0xFF2E2218),
                        foregroundColor: const Color(0xFFFFD54F),
                        elevation: 5,
                        child: const Icon(Icons.leaderboard_rounded, size: 20),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.small(
                        heroTag: 'fab_daily',
                        onPressed: () => QuizDailyScreen.afficher(context),
                        backgroundColor: const Color(0xFF1B4D3E),
                        foregroundColor: const Color(0xFF69F0AE),
                        elevation: 5,
                        child: const Icon(Icons.calendar_month_rounded, size: 20),
                      ),
                    ],
                  ),
                ),

                // Bouton Flottant "Mon Niveau" pour recentrer immédiatement
                Positioned(
                  right: 16,
                  bottom: 68,
                  child: FloatingActionButton.extended(
                    heroTag: 'fab_current_level',
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

  Widget _buildPanneauSignalisationBois() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8D5B28), Color(0xFF5D3A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.eco_rounded, color: Color(0xFF00E676), size: 18),
          const SizedBox(height: 2),
          Text(
            'Apprends\nProgresse\nDeviens une\nlégende !',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.15,
              shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
          if (_streak > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF7043), size: 14),
                const SizedBox(width: 2),
                Text(
                  '$_streak j de série',
                  style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFFFFD54F)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Barre Supérieure Jungle Quiz (Fidèle à la Maquette) ──
  Widget _buildHeaderFlottant(int totalEtoiles) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 2,
        bottom: 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QuizJungleTopBar(
            afficherLogo: true,
            userName: 'Germain',
            niveau: _niveauMax,
            pieces: _totalGrains > 0 ? _totalGrains : 2450,
            gemmes: 75,
            onSettingsTap: () {
              _afficherBadges();
            },
          ),
          QuizJungleRanksBar(
            niveauActuel: _niveauMax,
            onRankTap: (tierIndex) {
              final activeIndex = _niveauMax <= 19 ? 0 : (_niveauMax <= 39 ? 1 : (_niveauMax <= 59 ? 2 : (_niveauMax <= 79 ? 3 : 4)));
              if (tierIndex == activeIndex) {
                QuizRankUpDialog.afficher(context, nouveauGrade: _gradeActuel);
              } else {
                _afficherModalGrades();
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Disques de Niveaux 3D Jungle Quiz Adventure ──
  Widget _buildNiveauBubble(int niveauId, Offset pos) {
    final estDebloque = (niveauId <= _niveauMax);
    final estNiveauActuel = (niveauId == _niveauMax);
    final etoiles = _etoilesMap[niveauId] ?? 0;
    const bubbleSize = 68.0;

    return Positioned(
      left: pos.dx - (bubbleSize / 2),
      top: pos.dy - (bubbleSize / 2),
      child: SizedBox(
        width: bubbleSize,
        height: bubbleSize + 46,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // A. Halo lumineux pulsant si niveau actuel
            if (estNiveauActuel)
              Positioned(
                top: 22,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: bubbleSize + 18,
                        height: bubbleSize + 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E676).withValues(alpha: 0.75),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // B. Bouton 3D du podium / disque
            Positioned(
              top: 22,
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
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Rebord 3D inférieur
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: bubbleSize - 4,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: estDebloque
                                ? const Color(0xFF1B5E20)
                                : const Color(0xFF37474F),
                            boxShadow: [
                              BoxShadow(
                                color: (estDebloque ? const Color(0xFF1B5E20) : Colors.black).withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 2. Corps du disque
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: bubbleSize - 5,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: estDebloque
                                ? const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF00E676),
                                      Color(0xFF2E7D32),
                                    ],
                                  )
                                : const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF90A4AE),
                                      Color(0xFF546E7A),
                                    ],
                                  ),
                            border: Border.all(
                              color: estDebloque ? const Color(0xFFFFD54F) : Colors.white54,
                              width: estDebloque ? 2.5 : 2.0,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Reflet supérieur
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

                              // Numéro en GRAND & GRAS
                              Text(
                                '$niveauId',
                                style: GoogleFonts.poppins(
                                  fontSize: niveauId >= 100 ? 19 : 24,
                                  fontWeight: FontWeight.w900,
                                  color: estDebloque ? Colors.white : Colors.white70,
                                  shadows: const [
                                    Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Cadenas argenté sur les niveaux verrouillés
                      if (!estDebloque)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF455A64),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: const [
                                BoxShadow(color: Colors.black54, blurRadius: 4),
                              ],
                            ),
                            child: const Icon(Icons.lock_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // C. Étoiles au-dessus pour les niveaux complétés
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
                        color: brille ? const Color(0xFFFFD54F) : Colors.grey.shade400.withValues(alpha: 0.6),
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

            // D. Avatar joueur "Germain" flottant sur le niveau actif
            if (estNiveauActuel)
              Positioned(
                top: -18,
                child: AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _bounceAnimation.value),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFFD54F), width: 2.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD54F).withValues(alpha: 0.8),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/germain_avatar.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 20),
                          ),
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

  // ── Bannières des 10 Mondes & Grand Sommet (Zéro Émoticônes) ──
  List<Widget> _buildBannieresMondes(double screenWidth, Map<int, Offset> levelPositions) {
    final widgets = <Widget>[];

    for (final monde in QuizData.mondes) {
      final premierNiveau = monde.niveaux.first.id;
      final pos = levelPositions[premierNiveau];
      if (pos == null) continue;

      final yPos = (premierNiveau == 1)
          ? pos.dy + 80
          : (levelPositions[premierNiveau - 1]!.dy + pos.dy) / 2;

      final gradeMonde = QuizGrade.getGradePourNiveau(premierNiveau);

      widgets.add(
        Positioned(
          top: yPos - 16,
          left: 16,
          right: 16,
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: screenWidth - 32),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gradeMonde.couleurOmbre, gradeMonde.couleur],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 3)),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(monde.iconeData, size: 16, color: Colors.white),
                    const SizedBox(width: 7),
                    Text(
                      'MONDE ${monde.id} : ${monde.nom.toUpperCase()}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.4,
                        shadows: const [
                          Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Grand Trophée Sommet au-dessus du Niveau 100
    final summitPos = levelPositions[kTotalNiveaux];
    if (summitPos != null) {
      widgets.add(
        Positioned(
          top: summitPos.dy - 100,
          left: 16,
          right: 16,
          child: Column(
            children: [
              const Icon(Icons.emoji_events_rounded, size: 48, color: Color(0xFFFFD700)),
              const SizedBox(height: 4),
              Container(
                constraints: BoxConstraints(maxWidth: screenWidth - 32),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.orange.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'GRAND SOMMET DU MAÎTRE AGRONOME',
                    style: GoogleFonts.inter(
                      color: Colors.brown.shade900,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  // ── Coffres aux Trésors aux Paliers des 10 Mondes ──
  List<Widget> _buildCoffresTresors(double screenWidth, Map<int, Offset> levelPositions) {
    final widgets = <Widget>[];

    for (final monde in QuizData.mondes) {
      final dernierNiveauId = monde.niveaux.last.id;
      final pos = levelPositions[dernierNiveauId];
      if (pos == null) continue;

      // Décalage adaptatif vers le centre de l'écran pour un centrage anti-débordement
      final decalageX = (pos.dx > screenWidth * 0.5) ? -54.0 : 54.0;
      final estDebloque = (_niveauMax > dernierNiveauId);

      widgets.add(
        Positioned(
          left: pos.dx + decalageX - 22,
          top: pos.dy - 10,
          child: GestureDetector(
            onTap: () => _afficherDialogueCoffre(monde.id, dernierNiveauId),
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
              child: Icon(
                estDebloque ? Icons.card_giftcard_rounded : Icons.lock_clock_rounded,
                size: 22,
                color: estDebloque ? Colors.amber.shade900 : Colors.blueGrey.shade700,
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}

// ── Segment de Spline Cubique pour Continuité C1 Parfaite ──
class _SplineSegment {
  final Offset p1;
  final Offset cp1;
  final Offset cp2;
  final Offset p2;
  final int niveauDepart;

  const _SplineSegment({
    required this.p1,
    required this.cp1,
    required this.cp2,
    required this.p2,
    required this.niveauDepart,
  });
}

// ── CustomPainter pour la Route Sinueuse Organique, Pierres & Ambiance Jungle Rainforest ──
class _RoadMapPainter extends CustomPainter {
  final Map<int, Offset> levelPositions;
  final double screenWidth;
  final int totalNiveaux;
  final int niveauMax;

  _RoadMapPainter({
    required this.levelPositions,
    required this.screenWidth,
    required this.totalNiveaux,
    required this.niveauMax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (levelPositions.length < 2) return;

    // 1. Calcul des segments de la spline Catmull-Rom (courbure 100% fluide et C1 continue)
    final segments = _calculerSegmentsSpline();

    // 2. Lucioles lumineuses & brume solaire tropicale (harmonisées avec Misty Sunbeams)
    _dessinerLuciolesEtBrume(canvas, size);

    // 3. Dessin du chemin principal multicouches (ombres profondes, remblai terre, sentier doré)
    _dessinerRoute(canvas, segments);

    // 4. Trace lumineuse dorée et émeraude sur les niveaux déjà conquis par le joueur
    _dessinerProgression(canvas, segments);

    // 5. Galets et pierres de gué tout le long de la piste
    _dessinerPierresDeSentier(canvas, segments);

    // 6. Touches végétales de fougères tropicales sur les virages extérieurs
    _dessinerFougeresEtFeuillages(canvas, segments);
  }

  List<_SplineSegment> _calculerSegmentsSpline() {
    final pts = <Offset>[];
    final p1 = levelPositions[1]!;
    final pTop = levelPositions[totalNiveaux]!;

    // Prolongements sous le niveau 1 et au-dessus du niveau 100
    pts.add(Offset(p1.dx, p1.dy + 80));
    pts.add(Offset(p1.dx, p1.dy + 35));
    for (int i = 1; i <= totalNiveaux; i++) {
      pts.add(levelPositions[i] ?? Offset(screenWidth * 0.5, 0));
    }
    pts.add(Offset(pTop.dx, pTop.dy - 35));
    pts.add(Offset(pTop.dx, pTop.dy - 80));

    final segments = <_SplineSegment>[];
    const alpha = 0.85; // Tension Catmull-Rom optimale pour courbes douces sans pincement

    for (int i = 1; i < pts.length - 2; i++) {
      final p0 = pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = pts[i + 2];

      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6.0 * alpha,
        p1.dy + (p2.dy - p0.dy) / 6.0 * alpha,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6.0 * alpha,
        p2.dy - (p3.dy - p1.dy) / 6.0 * alpha,
      );

      final niveauIndex = i - 1; // 0 pour l'amorce, 1 pour Niv 1->2, etc.

      segments.add(_SplineSegment(
        p1: p1,
        cp1: cp1,
        cp2: cp2,
        p2: p2,
        niveauDepart: niveauIndex,
      ));
    }

    return segments;
  }

  void _dessinerRoute(Canvas canvas, List<_SplineSegment> segments) {
    final fullPath = Path();
    fullPath.moveTo(segments.first.p1.dx, segments.first.p1.dy);
    for (final seg in segments) {
      fullPath.cubicTo(seg.cp1.dx, seg.cp1.dy, seg.cp2.dx, seg.cp2.dy, seg.p2.dx, seg.p2.dy);
    }

    // A. Ombres portées au sol (donne une vraie profondeur 3D sur le sol de la jungle)
    final shadowPaint1 = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 46.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final shadowPaint2 = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..strokeWidth = 56.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.translate(0, 7);
    canvas.drawPath(fullPath, shadowPaint1);
    canvas.restore();

    canvas.save();
    canvas.translate(0, 14);
    canvas.drawPath(fullPath, shadowPaint2);
    canvas.restore();

    // B. Remblai de terre sombre et racines tropicales
    final earthPaint1 = Paint()
      ..color = const Color(0xFF3E2723)
      ..strokeWidth = 40.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(fullPath, earthPaint1);

    final earthPaint2 = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 36.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(fullPath, earthPaint2);

    // C. Corps du sentier en sable doré chaud / pierre de rivière
    final sandPaint1 = Paint()
      ..color = const Color(0xFFD49B44)
      ..strokeWidth = 30.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(fullPath, sandPaint1);

    final sandPaint2 = Paint()
      ..color = const Color(0xFFF7CF76)
      ..strokeWidth = 24.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(fullPath, sandPaint2);

    // D. Crête ensoleillée centrale (effet arrondi 3D baigné de lumière)
    final sandHighlight = Paint()
      ..color = const Color(0xFFFFF3CA)
      ..strokeWidth = 14.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(fullPath, sandHighlight);

    final sandSpine = Paint()
      ..color = const Color(0xFFFFFDF5)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(fullPath, sandSpine);
  }

  void _dessinerProgression(Canvas canvas, List<_SplineSegment> segments) {
    if (niveauMax <= 1) return;

    final progressPath = Path();
    bool first = true;

    for (final seg in segments) {
      if (seg.niveauDepart >= 1 && seg.niveauDepart < niveauMax) {
        if (first) {
          progressPath.moveTo(seg.p1.dx, seg.p1.dy);
          first = false;
        }
        progressPath.cubicTo(seg.cp1.dx, seg.cp1.dy, seg.cp2.dx, seg.cp2.dy, seg.p2.dx, seg.p2.dy);
      }
    }

    if (!first) {
      // Halo émeraude magique
      final glowPaint = Paint()
        ..color = const Color(0xFF00E676).withValues(alpha: 0.28)
        ..strokeWidth = 32.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(progressPath, glowPaint);

      // Traînée dorée triomphante
      final goldPaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.65)
        ..strokeWidth = 10.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(progressPath, goldPaint);

      // Cœur lumineux blanc éclatant
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(progressPath, corePaint);
    }
  }

  void _dessinerPierresDeSentier(Canvas canvas, List<_SplineSegment> segments) {
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.22);
    final stoneDark = Paint()..color = const Color(0xFF9E7D47);
    final stoneLight = Paint()..color = const Color(0xFFEED7A1);
    final stoneHighlight = Paint()..color = const Color(0xFFFFF7DC);
    final activeStoneGold = Paint()..color = const Color(0xFFFFD54F);

    for (final seg in segments) {
      if (seg.niveauDepart < 1 || seg.niveauDepart >= totalNiveaux) continue;
      final estComplete = (seg.niveauDepart < niveauMax);

      // 3 galets de gué le long du virage
      for (final t in const [0.28, 0.50, 0.72]) {
        final pos = _evaluerBezier(seg, t);
        final alt = ((seg.niveauDepart * 3 + (t * 10).round()) % 2 == 0);
        final w = alt ? 11.0 : 13.0;
        final h = w * 0.62;

        // Ombre sous la pierre
        canvas.drawOval(
          Rect.fromCenter(center: Offset(pos.dx, pos.dy + 1.8), width: w + 1, height: h),
          shadowPaint,
        );

        // Corps du galet
        canvas.drawOval(
          Rect.fromCenter(center: pos, width: w, height: h),
          estComplete ? stoneLight : stoneDark,
        );

        // Reflet clair supérieur
        canvas.drawOval(
          Rect.fromCenter(center: Offset(pos.dx, pos.dy - 1.2), width: w * 0.65, height: h * 0.45),
          estComplete ? activeStoneGold : stoneHighlight,
        );
      }
    }
  }

  void _dessinerLuciolesEtBrume(Canvas canvas, Size size) {
    final paintHalo = Paint()..style = PaintingStyle.fill;
    final paintCore = Paint()..style = PaintingStyle.fill..color = Colors.white;

    // Particules lumineuses féeriques le long de la hauteur (effet "Misty Sunbeams")
    for (double y = 80.0; y < size.height - 80.0; y += 140.0) {
      final seed = (y * 1.618).toInt();
      final rx = (seed % 100) / 100.0;
      final x = screenWidth * (0.10 + 0.80 * rx);
      final tailleHalo = 7.0 + (seed % 6);

      final estDore = (seed % 2 == 0);
      paintHalo.color = estDore
          ? const Color(0xFFFFD54F).withValues(alpha: 0.30)
          : const Color(0xFF76FF03).withValues(alpha: 0.25);

      canvas.drawCircle(Offset(x, y), tailleHalo, paintHalo);
      canvas.drawCircle(Offset(x, y), tailleHalo * 0.35, paintCore);
    }
  }

  void _dessinerFougeresEtFeuillages(Canvas canvas, List<_SplineSegment> segments) {
    final fougereFoncee = Paint()
      ..color = const Color(0xFF1B5E20).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final fougereClaire = Paint()
      ..color = const Color(0xFF43A047).withValues(alpha: 0.90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    for (int i = 1; i <= totalNiveaux; i += 2) {
      final pos = levelPositions[i];
      if (pos == null) continue;

      final estADroite = (pos.dx > screenWidth * 0.5);
      final sens = estADroite ? 1.0 : -1.0;
      final xBase = pos.dx + (sens * 38.0);
      final yBase = pos.dy + 8.0;

      // Palme / Fougère tropicale stylisée
      canvas.drawLine(Offset(xBase, yBase), Offset(xBase + (sens * 16), yBase - 12), fougereFoncee);
      canvas.drawLine(Offset(xBase, yBase), Offset(xBase + (sens * 10), yBase - 16), fougereClaire);
      canvas.drawLine(Offset(xBase, yBase), Offset(xBase + (sens * 18), yBase - 4), fougereClaire);
    }
  }

  Offset _evaluerBezier(_SplineSegment seg, double t) {
    final u = 1.0 - t;
    final x = u * u * u * seg.p1.dx +
        3 * u * u * t * seg.cp1.dx +
        3 * u * t * t * seg.cp2.dx +
        t * t * t * seg.p2.dx;
    final y = u * u * u * seg.p1.dy +
        3 * u * u * t * seg.cp1.dy +
        3 * u * t * t * seg.cp2.dy +
        t * t * t * seg.p2.dy;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant _RoadMapPainter oldDelegate) {
    return oldDelegate.levelPositions != levelPositions ||
        oldDelegate.screenWidth != screenWidth ||
        oldDelegate.totalNiveaux != totalNiveaux ||
        oldDelegate.niveauMax != niveauMax;
  }
}
