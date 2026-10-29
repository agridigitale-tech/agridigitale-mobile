// Carte interactive "Le Conseil du Jour" avec lecture audio TTS intégrée.
// Permet d'écouter ou lire le conseil pratique quotidien en 30 secondes.
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/design/app_colors.dart';
import '../data/conseils_data.dart';
import '../services/quiz_service.dart';

class ConseilDuJourCard extends StatefulWidget {
  const ConseilDuJourCard({super.key});

  @override
  State<ConseilDuJourCard> createState() => _ConseilDuJourCardState();
}

class _ConseilDuJourCardState extends State<ConseilDuJourCard> {
  final ConseilAgricole _conseil = ConseilsData.getConseilDuJour();
  final FlutterTts _tts = FlutterTts();
  final _quizService = QuizService();

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
      await _tts.setSpeechRate(0.48); // Vitesse posée et claire
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
    if (_enLecture) {
      await _tts.stop();
      if (mounted) setState(() => _enLecture = false);
    } else {
      if (mounted) setState(() => _enLecture = true);
      final texteALire = '${_conseil.titre}. ${_conseil.texte}. Astuce clé : ${_conseil.astuceCle}';
      await _tts.speak(texteALire);

      if (!_dejaEcoute) {
        _dejaEcoute = true;
        // Récompense : +5 grains pour avoir écouté le conseil
        final sp = await _quizService.getTotalGrains();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('quiz_agri_grains', sp + 5);
        _quizService.changeNotifier.value++;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceSombre : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.vertClair : AppColors.vertPrimaire).withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : Badge Conseil du jour + Catégorie + Bouton audio
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE65100), Colors.amber],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('☀️', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text(
                      'CONSEIL DU JOUR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.vertClair : AppColors.vertPrimaire).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _conseil.categorie,
                  style: TextStyle(
                    color: isDark ? AppColors.vertClair : AppColors.vertPrimaire,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              // Bouton Écouter Audio (TTS)
              InkWell(
                onTap: _basculerLecture,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _enLecture
                        ? AppColors.vertPrimaire
                        : (isDark ? AppColors.surfaceSombreLegere : Colors.green.shade50),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.vertPrimaire.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _enLecture ? Icons.pause : Icons.volume_up,
                        size: 15,
                        color: _enLecture ? Colors.white : AppColors.vertPrimaire,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _enLecture ? 'Pause' : 'Écouter (30s)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _enLecture ? Colors.white : AppColors.vertPrimaire,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Titre du conseil
          Text(
            _conseil.titre,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),

          // Texte du conseil
          Text(
            _conseil.texte,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.texteSombreFort : AppColors.texteFort,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),

          // Astuce Clé
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.vertClair.withValues(alpha: 0.08)
                  : const Color(0xFFF0F7F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates, size: 14, color: AppColors.vertPrimaire),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Astuce : ${_conseil.astuceCle}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.vertClair : AppColors.vertFonce,
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
}
