// Overlay pop-up "Conseil du Jour" affiché chaque matin en superposition sur l'écran.
// Dispose d'un bouton X au coin supérieur pour le fermer, d'un lecteur audio TTS et de récompenses en grains.
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/design/app_colors.dart';
import '../data/conseils_data.dart';
import '../services/quiz_service.dart';

class ConseilDuJourOverlay extends StatefulWidget {
  final ConseilAgricole conseil;
  final VoidCallback? onFermer;

  const ConseilDuJourOverlay({
    super.key,
    required this.conseil,
    this.onFermer,
  });

  static const String _kKeyDernierConseilDate = 'dernier_popup_conseil_date';

  /// Affiche l'overlay automatiquement le matin au premier lancement de la journée
  static Future<bool> afficherSiNouveauMatin(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final aujourdhui = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final derniereDate = prefs.getString(_kKeyDernierConseilDate);

      if (derniereDate != aujourdhui) {
        await prefs.setString(_kKeyDernierConseilDate, aujourdhui);
        if (context.mounted) {
          afficher(context);
          return true;
        }
      }
    } catch (e) {
      debugPrint('[ConseilDuJourOverlay] Erreur vérification date matin: $e');
    }
    return false;
  }

  /// Affiche l'overlay manuellement à l'écran
  static void afficher(BuildContext context, [ConseilAgricole? conseilPersonnalise]) {
    final c = conseilPersonnalise ?? ConseilsData.getConseilDuJour();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fermer le conseil du jour',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim1, anim2) {
        return ConseilDuJourOverlay(
          conseil: c,
          onFermer: () => Navigator.of(ctx).pop(),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4 * anim1.value, sigmaY: 4 * anim1.value),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curve),
            child: FadeTransition(
              opacity: anim1,
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  State<ConseilDuJourOverlay> createState() => _ConseilDuJourOverlayState();
}

class _ConseilDuJourOverlayState extends State<ConseilDuJourOverlay> {
  final FlutterTts _tts = FlutterTts();
  final QuizService _quizService = QuizService();

  bool _enLecture = false;
  bool _dejaEcoute = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _enLecture = false);
      });
      _tts.setErrorHandler((_) {
        if (mounted) setState(() => _enLecture = false);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _basculerLecture() async {
    HapticFeedback.lightImpact();
    if (_enLecture) {
      await _tts.stop();
      if (mounted) setState(() => _enLecture = false);
    } else {
      if (mounted) setState(() => _enLecture = true);
      final texteALire = '${widget.conseil.titre}. ${widget.conseil.texte}. Astuce clé : ${widget.conseil.astuceCle}';
      await _tts.speak(texteALire);

      if (!_dejaEcoute) {
        _dejaEcoute = true;
        // Récompense : +5 grains
        final act = await _quizService.getTotalGrains();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('quiz_agri_grains', act + 5);
        _quizService.changeNotifier.value++;
      }
    }
  }

  void _fermer() {
    _tts.stop();
    if (widget.onFermer != null) {
      widget.onFermer!();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _partager() {
    final texte = '🌾 Conseil AgriDigitale du Jour : ${widget.conseil.titre}\n\n'
        '${widget.conseil.texte}\n\n'
        '💡 Astuce clé : ${widget.conseil.astuceCle}\n\n'
        'Retrouvez chaque matin votre conseil et le cours des marchés sur l\'app AgriDigitale : https://agridigitale.net';
    Share.share(texte);
  }

  String _dateDuJourFormatee() {
    final now = DateTime.now();
    const mois = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${now.day} ${mois[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceSombre : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.vertPrimaire.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tête supérieur avec bannière dégradée et bouton X
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1B3B2B), const Color(0xFF2A533E)]
                          : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Badge Soleil "CONSEIL DU MATIN"
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB300),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('☀️', style: TextStyle(fontSize: 13)),
                            SizedBox(width: 4),
                            Text(
                              'CONSEIL DU MATIN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _dateDuJourFormatee(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppColors.grisTexte,
                        ),
                      ),
                      const Spacer(),
                      // Bouton X circulaire pour fermer en superposition
                      InkWell(
                        onTap: _fermer,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black38 : Colors.white.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: isDark ? Colors.white : AppColors.texteFort,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Corps du conseil défilable si besoin
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Catégorie
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.vertPrimaire.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.conseil.categorie.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.vertPrimaire,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Titre
                        Text(
                          widget.conseil.titre,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                            color: isDark ? AppColors.texteSombreFort : AppColors.texteFort,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Texte explicatif
                        Text(
                          widget.conseil.texte,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: isDark ? AppColors.texteSombreMoyen : AppColors.grisTexte,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Encadré "Astuce clé"
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFD54F)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('💡', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.conseil.astuceCle,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF5D4037),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Lecteur audio interactif TTS avec récompense en grains
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : const Color(0xFFF1F8E9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.vertPrimaire.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: _basculerLecture,
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _enLecture
                                          ? [Colors.orange, Colors.deepOrange]
                                          : [AppColors.vertPrimaire, const Color(0xFF4CAF50)],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_enLecture ? Colors.orange : AppColors.vertPrimaire).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _enLecture ? Icons.pause : Icons.volume_up,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _enLecture ? 'Lecture en cours (audio)...' : 'Écouter le conseil (30s)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : AppColors.texteFort,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Row(
                                      children: [
                                        Text('🌾', style: TextStyle(fontSize: 11)),
                                        SizedBox(width: 4),
                                        Text(
                                          '+5 grains offerts à l\'écoute',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.vertPrimaire,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Barre d'actions inférieure : Partager + Bouton principal "Bien compris"
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Bouton WhatsApp Partager
                      IconButton(
                        onPressed: _partager,
                        icon: const Icon(Icons.share_outlined, color: AppColors.vertPrimaire),
                        tooltip: 'Partager le conseil',
                      ),
                      const SizedBox(width: 6),
                      // Bouton d'action principal
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _fermer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.vertPrimaire,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Bien compris !',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
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
      ),
    );
  }
}
