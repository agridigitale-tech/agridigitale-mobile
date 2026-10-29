// Vue dédiée pour l'onglet "CONSEIL DU JOUR".
// Affiche UNIQUEMENT le conseil agronomique du jour (1 seul par jour)
// avec lecture vocale TTS en 30s, astuce clé, récompenses en grains et partage WhatsApp.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/design/app_colors.dart';
import '../data/conseils_data.dart';
import '../services/quiz_service.dart';
import 'conseil_du_jour_overlay.dart';

class ConseilDuJourSection extends StatefulWidget {
  final VoidCallback? onReafficherOverlay;

  const ConseilDuJourSection({
    super.key,
    this.onReafficherOverlay,
  });

  @override
  State<ConseilDuJourSection> createState() => _ConseilDuJourSectionState();
}

class _ConseilDuJourSectionState extends State<ConseilDuJourSection> {
  final ConseilAgricole _conseilDuJour = ConseilsData.getConseilDuJour();
  final FlutterTts _tts = FlutterTts();
  final QuizService _quizService = QuizService();

  bool _enLecture = false;
  bool _dejaEcoute = false;
  int _streak = 0;
  int _grains = 0;

  @override
  void initState() {
    super.initState();
    _initTts();
    _chargerStats();
  }

  Future<void> _chargerStats() async {
    final s = await _quizService.getStreakJours();
    final g = await _quizService.getTotalGrains();
    if (mounted) {
      setState(() {
        _streak = s;
        _grains = g;
      });
    }
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
      final texte = '${_conseilDuJour.titre}. ${_conseilDuJour.texte}. Astuce clé : ${_conseilDuJour.astuceCle}';
      await _tts.speak(texte);

      if (!_dejaEcoute) {
        _dejaEcoute = true;
        // Attribution de +5 grains
        final act = await _quizService.getTotalGrains();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('quiz_agri_grains', act + 5);
        _quizService.changeNotifier.value++;
        _chargerStats();
      }
    }
  }

  void _partagerConseil() {
    final texte = '🌾 Conseil AgriDigitale du Jour : ${_conseilDuJour.titre}\n\n'
        '${_conseilDuJour.texte}\n\n'
        '💡 Astuce clé : ${_conseilDuJour.astuceCle}\n\n'
        'Chaque matin, retrouvez un nouveau conseil et les cours des marchés sur l\'app AgriDigitale : https://agridigitale.net';
    Share.share(texte);
  }

  String _dateAujourdhui() {
    final now = DateTime.now();
    const jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    const mois = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${jours[now.weekday - 1]} ${now.day} ${mois[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de section avec date du jour
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Le Conseil du Jour',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.4),
                    ),
                    Text(
                      _dateAujourdhui(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.vertPrimaire,
                      ),
                    ),
                  ],
                ),
              ),
              // Bouton pour rouvrir en mode pop-up superposition
              TextButton.icon(
                onPressed: () {
                  if (widget.onReafficherOverlay != null) {
                    widget.onReafficherOverlay!();
                  } else {
                    ConseilDuJourOverlay.afficher(context);
                  }
                },
                icon: const Icon(Icons.fullscreen, size: 18, color: AppColors.vertPrimaire),
                label: const Text(
                  'Mode Pop-up',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.vertPrimaire),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Grande carte héro du conseil UNIQUE du jour
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E3A2B), const Color(0xFF152A1F)]
                    : [const Color(0xFFF1F8E9), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.vertPrimaire.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('☀️', style: TextStyle(fontSize: 12)),
                          SizedBox(width: 4),
                          Text(
                            'CONSEIL DU JOUR',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.vertPrimaire.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _conseilDuJour.categorie.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.vertPrimaire,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 20, color: AppColors.vertPrimaire),
                      tooltip: 'Partager',
                      onPressed: _partagerConseil,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Titre du conseil
                Text(
                  _conseilDuJour.titre,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                    color: isDark ? Colors.white : AppColors.texteFort,
                  ),
                ),
                const SizedBox(height: 12),

                // Texte explicatif
                Text(
                  _conseilDuJour.texte,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: isDark ? Colors.white70 : AppColors.grisTexte,
                  ),
                ),
                const SizedBox(height: 16),

                // Encadré Astuce clé
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD54F)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'L\'astuce clé du paysan :',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8D6E63),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _conseilDuJour.astuceCle,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4E342E),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Bouton lecteur audio TTS interactif
                InkWell(
                  onTap: _basculerLecture,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _enLecture
                            ? [Colors.orange, Colors.deepOrange]
                            : [AppColors.vertPrimaire, const Color(0xFF4CAF50)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: (_enLecture ? Colors.orange : AppColors.vertPrimaire)
                              .withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _enLecture ? Icons.pause_circle_filled : Icons.play_circle_fill,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _enLecture
                              ? 'Pause la lecture audio'
                              : 'Écouter le conseil à haute voix (30s)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Encadré rituel quotidien : 1 conseil par jour
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceSombre : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('⏰', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'Rendez-vous quotidien de 06h00',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.texteFort,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Chaque matin à 06h00, l\'application débloque automatiquement 1 nouveau conseil agronomique pratique adapté aux réalités de nos terroirs. Revenez demain matin pour découvrir l\'astuce suivante !',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: isDark ? Colors.white60 : AppColors.grisTexte,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Text(
                            'Série : $_streak jour(s)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.vertPrimaire.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🌾', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Text(
                            'Solde : $_grains grains',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.vertPrimaire,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
