// Carte d'accueil interactive pour le Quiz Agricole et le parcours de Niveaux.
// Déclencheur visuel : streak, grains, et accès en 1 clic.
import 'package:flutter/material.dart';
import '../core/design/app_colors.dart';
import '../data/quiz_data.dart';
import '../models/quiz_grade.dart';
import '../services/quiz_service.dart';
import '../screens/quiz/quiz_screen.dart';
import '../screens/quiz/quiz_niveaux_screen.dart';

class QuizHomeCard extends StatefulWidget {
  const QuizHomeCard({super.key});

  @override
  State<QuizHomeCard> createState() => _QuizHomeCardState();
}

class _QuizHomeCardState extends State<QuizHomeCard> {
  final _quizService = QuizService();
  int _niveauMax = 1;
  int _streak = 0;
  int _grains = 0;
  bool _quizJourFait = false;

  @override
  void initState() {
    super.initState();
    _chargerStats();
    _quizService.changeNotifier.addListener(_chargerStats);
  }

  @override
  void dispose() {
    _quizService.changeNotifier.removeListener(_chargerStats);
    super.dispose();
  }

  Future<void> _chargerStats() async {
    final max = await _quizService.getNiveauMaxDebloque();
    final streak = await _quizService.getStreakJours();
    final grains = await _quizService.getTotalGrains();
    final fait = await _quizService.estQuizDuJourFaitAujourdhui();

    if (mounted) {
      setState(() {
        _niveauMax = max;
        _streak = streak;
        _grains = grains;
        _quizJourFait = fait;
      });
    }
  }

  void _lancerQuizDuJour() async {
    final questions = QuizData.getQuizDuJour();
    if (questions.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: questions,
          titre: 'Quiz du Jour',
          estQuizDuJour: true,
        ),
      ),
    );
    _chargerStats();
  }

  void _ouvrirNiveaux() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const QuizNiveauxScreen(),
      ),
    );
    _chargerStats();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grade = QuizGrade.getGradePourNiveau(_niveauMax);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E2F23), const Color(0xFF142018)]
              : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.vertClair : AppColors.vertPrimaire).withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Éléments décoratifs en arrière-plan
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              Icons.psychology_outlined,
              size: 110,
              color: (isDark ? Colors.white : AppColors.vertPrimaire).withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête : Titre + Streak + Grains
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.vertPrimaire,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.sports_esports, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Le Défi Agricole',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const Spacer(),
                    if (_streak > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department_rounded, size: 13, color: Colors.red.shade700),
                            const SizedBox(width: 2),
                            Text(
                              '$_streak j',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Colors.red.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: grade.couleurFond,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: grade.couleur.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(grade.icone, size: 13, color: grade.couleur),
                          const SizedBox(width: 4),
                          Text(
                            grade.titre.split(' ').first,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: grade.couleur,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.grain_rounded, size: 13, color: Colors.amber.shade900),
                          const SizedBox(width: 3),
                          Text(
                            '$_grains',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Texte incitatif
                Text(
                  _quizJourFait
                      ? 'Quiz du jour validé ! Continuez l\'aventure pour débloquer le Niveau ${_niveauMax + 1}.'
                      : 'Testez vos connaissances en 3 questions chrono (1 minute) et récoltez des grains !',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.texteSombreMoyen : Colors.black87,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),

                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        onPressed: _lancerQuizDuJour,
                        icon: Icon(_quizJourFait ? Icons.check_circle : Icons.play_arrow, size: 18),
                        label: Text(_quizJourFait ? 'Rejouer le Quiz' : 'Quiz du Jour (1 min)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.vertPrimaire,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        onPressed: _ouvrirNiveaux,
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: Text('Niveau $_niveauMax'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? AppColors.vertClair : AppColors.vertPrimaire,
                          side: BorderSide(
                            color: isDark ? AppColors.vertClair : AppColors.vertPrimaire,
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
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
