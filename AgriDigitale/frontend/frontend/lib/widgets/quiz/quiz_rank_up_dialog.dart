// Dialogue festif de promotion de rang (Rank Up Celebration Dialog).
// Déclenché lorsqu'un joueur débloque un nouveau grade (de Novice à Légende).
// - Rayons dorés rotatifs (Sunburst rays)
// - Écusson 3D du nouveau grade avec halo lumineux
// - Comparateur Évolution : Ancien Rang ➔ Nouveau Rang
// - Zone géographique et thématique débloquée
// - Récompense bonus (+50 Pièces d'or)
// - Effets sonores de victoire et vibrations haptiques

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/quiz_grade.dart';
import '../../services/quiz_sound_service.dart';
import 'quiz_coin_gain_overlay.dart';

class QuizRankUpDialog extends StatefulWidget {
  final QuizGrade nouveauGrade;
  final QuizGrade? ancienGrade;
  final VoidCallback? onContinuer;

  const QuizRankUpDialog({
    super.key,
    required this.nouveauGrade,
    this.ancienGrade,
    this.onContinuer,
  });

  /// Méthode d'aide pour afficher le dialogue de promotion avec animation
  static Future<void> afficher(
    BuildContext context, {
    required QuizGrade nouveauGrade,
    QuizGrade? ancienGrade,
    VoidCallback? onContinuer,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (ctx, anim1, anim2) {
        return QuizRankUpDialog(
          nouveauGrade: nouveauGrade,
          ancienGrade: ancienGrade ??
              (nouveauGrade.niveauDebut > 1
                  ? QuizGrade.getGradePourNiveau(nouveauGrade.niveauDebut - 1)
                  : null),
          onContinuer: onContinuer,
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  State<QuizRankUpDialog> createState() => _QuizRankUpDialogState();
}

class _QuizRankUpDialogState extends State<QuizRankUpDialog> with TickerProviderStateMixin {
  final _soundService = QuizSoundService();

  late AnimationController _raysController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Rotation continue des rayons de lumière (sunburst)
    _raysController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    // Pulsation douce du halo de l'écusson
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Déclenche fanfare et vibration festive
    _soundService.playVictory();
    _soundService.vibrateHeavy();
  }

  @override
  void dispose() {
    _raysController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grade = widget.nouveauGrade;
    final ancien = widget.ancienGrade;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // ── Rayons dorés rotatifs en arrière-plan (Sunburst) ──
              Positioned(
                top: -30,
                child: AnimatedBuilder(
                  animation: _raysController,
                  builder: (context, _) {
                    return Transform.rotate(
                      angle: _raysController.value * 2 * math.pi,
                      child: CustomPaint(
                        size: const Size(340, 340),
                        painter: _SunburstRaysPainter(
                          couleur: grade.couleur.withValues(alpha: 0.28),
                          nbRayons: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Carte principale du dialogue en bois sculpté et or ──
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 390),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F3025), Color(0xFF071913)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: grade.couleur.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                    const BoxShadow(
                      color: Colors.black87,
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bannière titre "PROMOTION DE RANG !"
                    _buildBanniereTitre(),

                    const SizedBox(height: 18),

                    // Grand Écusson 3D animé du nouveau grade
                    _buildGrandEcusson3D(grade),

                    const SizedBox(height: 14),

                    // Titre du Grade (ex: "APPRENTI PLANTEUR")
                    Text(
                      grade.titre.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.6,
                        shadows: [
                          Shadow(
                            color: grade.couleurOmbre,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Sous-titre
                    Text(
                      grade.sousTitre,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFD54F),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Évolution Ancien Grade ➔ Nouveau Grade
                    if (ancien != null) _buildComparateurEvolution(ancien, grade),

                    const SizedBox(height: 14),

                    // Badge Zone Débloquée
                    _buildBadgeZone(grade),

                    const SizedBox(height: 12),

                    // Description agronomique
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        grade.description,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.35,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Récompense bonus de promotion (+50 Pièces d'or)
                    _buildPiluleRecompense(),

                    const SizedBox(height: 20),

                    // Bouton 3D vert "CONTINUER L'AVENTURE ➔"
                    _buildBoutonContinuer(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bannière dorée en-tête "PROMOTION DE RANG !"
  Widget _buildBanniereTitre() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEA00), Color(0xFFFF9100), Color(0xFFFF6D00)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(
            'PROMOTION DE RANG !',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.8,
              shadows: const [
                Shadow(color: Color(0xFFBF360C), blurRadius: 4, offset: Offset(0, 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Grand écusson 3D du nouveau grade avec pulsation
  Widget _buildGrandEcusson3D(QuizGrade grade) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: grade.degrade,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFFFD54F), width: 4),
          boxShadow: [
            BoxShadow(
              color: grade.couleur.withValues(alpha: 0.9),
              blurRadius: 22,
              spreadRadius: 3,
            ),
            const BoxShadow(
              color: Colors.black54,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Anneau intérieur brillant
            Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
              ),
            ),
            // Icône vectorielle du grade
            Icon(
              grade.icone,
              size: 54,
              color: Colors.white,
              shadows: const [
                Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Évolution : Ancien Rang ➔ Nouveau Rang
  Widget _buildComparateurEvolution(QuizGrade ancien, QuizGrade nouveau) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF071913),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          // Ancien rang
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(ancien.icone, color: Colors.white54, size: 20),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    ancien.titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white60,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.redAccent,
                      decorationThickness: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Flèche de promotion
          Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Color(0xFF00E676),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.black87,
              size: 15,
            ),
          ),

          // Nouveau rang
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(nouveau.icone, color: nouveau.couleur, size: 20),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    nouveau.titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF00E676),
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

  /// Badge de la zone débloquée
  Widget _buildBadgeZone(QuizGrade grade) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            grade.couleur.withValues(alpha: 0.25),
            grade.couleurOmbre.withValues(alpha: 0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: grade.couleur.withValues(alpha: 0.6), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.explore_rounded, color: grade.couleur, size: 16),
          const SizedBox(width: 6),
          Text(
            'NOUVELLE ZONE : ${grade.nomZone.toUpperCase()}',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Pilule bonus "+50 Pièces d'or"
  Widget _buildPiluleRecompense() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8D5B28), Color(0xFF5D3A1A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          QuizCoinGainOverlay.build3DCoin(taille: 24),
          const SizedBox(width: 8),
          Text(
            '+50 PIÈCES D\'OR BONUS DE PROMOTION',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFFFD54F),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Bouton 3D vert "CONTINUER L'AVENTURE ➔"
  Widget _buildBoutonContinuer(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        widget.onContinuer?.call();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00E676), Color(0xFF1B5E20)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 2.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E676).withValues(alpha: 0.6),
              blurRadius: 14,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
            const BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CONTINUER L\'AVENTURE',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.6,
                shadows: const [
                  Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1.5)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter pour les rayons de lumière rotatifs (Sunburst)
class _SunburstRaysPainter extends CustomPainter {
  final Color couleur;
  final int nbRayons;

  _SunburstRaysPainter({
    required this.couleur,
    this.nbRayons = 16,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(size.width, size.height) / 2;
    final paint = Paint()
      ..color = couleur
      ..style = PaintingStyle.fill;

    final angleStep = (2 * math.pi) / nbRayons;
    final halfRay = angleStep / 2;

    for (int i = 0; i < nbRayons; i++) {
      final startAngle = i * angleStep;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + radius * math.cos(startAngle),
          center.dy + radius * math.sin(startAngle),
        )
        ..lineTo(
          center.dx + radius * math.cos(startAngle + halfRay),
          center.dy + radius * math.sin(startAngle + halfRay),
        )
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SunburstRaysPainter oldDelegate) {
    return oldDelegate.couleur != couleur || oldDelegate.nbRayons != nbRayons;
  }
}
