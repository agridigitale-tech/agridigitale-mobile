// Vue dédiée pour l'onglet "CONSEIL DU JOUR".
// Affiche la citation agronomique du jour au format Glassmorphisme minimaliste
// avec griffes de citation, police Playfair Display, lecture vocale TTS et partage.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/design/app_colors.dart';
import '../data/conseils_data.dart';
import '../services/quiz_service.dart';
import 'conseil_du_jour_card.dart';
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
  final QuizService _quizService = QuizService();

  int _streak = 0;
  int _grains = 0;

  @override
  void initState() {
    super.initState();
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
          // En-tête de section avec date du jour et bouton pop-up
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
                    Text(
                      'Le Conseil du Jour',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
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
              // Bouton pour rouvrir en superposition
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.vertPrimaire,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Carte citation modernisée en Glassmorphisme minimaliste
          ConseilDuJourCard(
            conseil: _conseilDuJour,
            margin: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),

          // Encadré rituel quotidien avec streak et solde de grains
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceSombre : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
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
                  'Chaque matin à 06h00, l\'application débloque automatiquement une nouvelle citation et sagesse agronomique pour nos terroirs.',
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
