// Carte "Le Conseil du Jour" modernisée en citation professionnelle et minimaliste.
// Style Glassmorphisme (flou d'arrière-plan, transparence, bordure brillante et lueur subtile),
// griffes de citation décoratives, typographie éditoriale Playfair Display,
// et strictement minimaliste : uniquement les icônes Écouter (TTS) et Partager (sans l'astuce clé).

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/design/app_colors.dart';
import '../data/conseils_data.dart';
import '../services/quiz_service.dart';

class ConseilDuJourCard extends StatefulWidget {
  final ConseilAgricole? conseil;
  final VoidCallback? onFermer;
  final EdgeInsetsGeometry margin;

  const ConseilDuJourCard({
    super.key,
    this.conseil,
    this.onFermer,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  State<ConseilDuJourCard> createState() => _ConseilDuJourCardState();
}

class _ConseilDuJourCardState extends State<ConseilDuJourCard>
    with SingleTickerProviderStateMixin {
  late final ConseilAgricole _conseil;
  final FlutterTts _tts = FlutterTts();
  final QuizService _quizService = QuizService();

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool _enLecture = false;
  bool _dejaEcoute = false;

  @override
  void initState() {
    super.initState();
    _conseil = widget.conseil ?? ConseilsData.getConseilDuJour();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.48); // Vitesse posée et claire
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setCompletionHandler(() {
        if (mounted) {
          setState(() => _enLecture = false);
          _pulseController.stop();
          _pulseController.reset();
        }
      });
      _tts.setErrorHandler((_) {
        if (mounted) {
          setState(() => _enLecture = false);
          _pulseController.stop();
          _pulseController.reset();
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _basculerLecture() async {
    HapticFeedback.lightImpact();
    if (_enLecture) {
      await _tts.stop();
      if (mounted) {
        setState(() => _enLecture = false);
        _pulseController.stop();
        _pulseController.reset();
      }
    } else {
      if (mounted) {
        setState(() => _enLecture = true);
        _pulseController.repeat(reverse: true);
      }
      // Lecture vocale sans l'astuce clé (minimaliste)
      final texteALire = '${_conseil.titre}. ${_conseil.texte}.';
      await _tts.speak(texteALire);

      if (!_dejaEcoute) {
        _dejaEcoute = true;
        // Récompense : +5 grains pour avoir écouté la citation du jour
        final sp = await _quizService.getTotalGrains();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('quiz_agri_grains', sp + 5);
        _quizService.changeNotifier.value++;
      }
    }
  }

  void _partagerCitation() {
    HapticFeedback.lightImpact();
    final textePartage = '🌾 « ${_conseil.texte} »\n\n'
        '— ${_conseil.titre} (${_conseil.categorie})\n\n'
        'Conseil du jour AgriDigitale : https://agridigitale.net';
    Share.share(textePartage);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: widget.margin,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lueur diffuse d'arrière-plan (lumière ambrée en haut, vert émeraude en bas) pour le rendu glassmorphism
          Positioned(
            top: 0,
            right: 24,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFB300).withValues(alpha: isDark ? 0.12 : 0.20),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.vertPrimaire.withValues(alpha: isDark ? 0.14 : 0.18),
              ),
            ),
          ),

          // Conteneur en verre dépoli (Frosted Glass)
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF1E3527).withValues(alpha: 0.72),
                            const Color(0xFF0F1E15).withValues(alpha: 0.60),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.82),
                            const Color(0xFFF3FAF5).withValues(alpha: 0.68),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.white.withValues(alpha: 0.85),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.40)
                          : const Color(0xFF1B5E20).withValues(alpha: 0.08),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // En-tête : Badge Catégorie minimaliste + bouton fermeture optionnel
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '🌱',
                                style: TextStyle(fontSize: 10),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _conseil.categorie.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: isDark ? AppColors.vertClair : AppColors.vertPrimaire,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.onFermer != null)
                          InkWell(
                            onTap: widget.onFermer,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: isDark ? Colors.white70 : AppColors.texteFort,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // "Griffes" de citation : grands guillemets stylisés
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '“',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 48,
                            height: 0.7,
                            fontWeight: FontWeight.bold,
                            color: (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
                                .withValues(alpha: 0.50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Titre du conseil en typographie Playfair Display
                    Text(
                      _conseil.titre,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.3,
                        color: isDark ? Colors.white : const Color(0xFF162A1D),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Corps de la citation en italique éditorial
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '« ${_conseil.texte} »',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 15.5,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w400,
                          height: 1.6,
                          letterSpacing: 0.15,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.88)
                              : const Color(0xFF2D4033),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Barre d'action minimaliste : UNIQUEMENT écouter (audio) et partager
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Bouton ÉCOUTER (Lecture vocale TTS)
                        Tooltip(
                          message: _enLecture ? 'Pause la lecture' : 'Écouter la citation',
                          child: InkWell(
                            onTap: _basculerLecture,
                            borderRadius: BorderRadius.circular(28),
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _enLecture ? _pulseAnimation.value : 1.0,
                                  child: child,
                                );
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: _enLecture
                                        ? [Colors.orange, Colors.deepOrange]
                                        : [
                                            (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
                                                .withValues(alpha: 0.18),
                                            (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
                                                .withValues(alpha: 0.08),
                                          ],
                                  ),
                                  border: Border.all(
                                    color: _enLecture
                                        ? Colors.orangeAccent
                                        : (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
                                            .withValues(alpha: 0.45),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_enLecture
                                              ? Colors.orange
                                              : AppColors.vertPrimaire)
                                          .withValues(alpha: isDark ? 0.35 : 0.18),
                                      blurRadius: _enLecture ? 16 : 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _enLecture ? Icons.pause_rounded : Icons.volume_up_rounded,
                                  color: _enLecture
                                      ? Colors.white
                                      : (isDark ? AppColors.vertClair : AppColors.vertPrimaire),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Bouton PARTAGER (Partage direct)
                        Tooltip(
                          message: 'Partager la citation',
                          child: InkWell(
                            onTap: _partagerCitation,
                            borderRadius: BorderRadius.circular(28),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
                                        .withValues(alpha: 0.18),
                                    (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
                                        .withValues(alpha: 0.08),
                                  ],
                                ),
                                border: Border.all(
                                  color: (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
                                      .withValues(alpha: 0.45),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
                                        .withValues(alpha: isDark ? 0.25 : 0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.share_outlined,
                                color: isDark ? AppColors.vertClair : AppColors.vertPrimaire,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
