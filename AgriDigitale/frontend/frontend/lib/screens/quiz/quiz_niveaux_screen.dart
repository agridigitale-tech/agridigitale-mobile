// Écran de sélection des Niveaux et Mondes du Quiz Agricole.
// Carte de progression façon Duolingo/Candy Crush avec déblocage progressif et étoiles.
import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../data/quiz_data.dart';
import '../../services/quiz_service.dart';
import 'quiz_screen.dart';

class QuizNiveauxScreen extends StatefulWidget {
  const QuizNiveauxScreen({super.key});

  @override
  State<QuizNiveauxScreen> createState() => _QuizNiveauxScreenState();
}

class _QuizNiveauxScreenState extends State<QuizNiveauxScreen> {
  final _quizService = QuizService();
  int _niveauMax = 1;
  int _totalGrains = 0;
  int _streak = 0;
  Map<int, int> _etoilesMap = {};
  List<String> _badgesDebloques = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
    _quizService.changeNotifier.addListener(_chargerDonnees);
  }

  @override
  void dispose() {
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

  void _afficherBadges() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🏆 Vos Trophées & Badges', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const Spacer(),
                Text('${_badgesDebloques.length}/${QuizService.tousLesBadges.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.vertPrimaire)),
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
                      color: estDebloque ? Colors.amber.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: estDebloque ? Colors.amber.shade400 : Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Text(estDebloque ? b.icone : '🔒', style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.nom,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: estDebloque ? Colors.black87 : Colors.grey.shade600),
                              ),
                              const SizedBox(height: 2),
                              Text(b.description, style: TextStyle(fontSize: 12, color: estDebloque ? AppColors.grisTexte : Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        if (estDebloque)
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
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
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        title: const Text('🎮 Défi Agricole : Niveaux', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined, color: Colors.amber),
            tooltip: 'Mes Badges',
            onPressed: _afficherBadges,
          ),
        ],
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire))
          : Column(
              children: [
                // Bandeau stats
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderStat('Étoiles', '$totalEtoiles/${QuizData.totalNiveaux * 3} ⭐', Colors.amber.shade800),
                      _buildHeaderStat('Grains', '$_totalGrains 🌾', Colors.orange.shade800),
                      _buildHeaderStat('Série', '$_streak j 🔥', Colors.redAccent),
                      _buildHeaderStat('Badges', '${_badgesDebloques.length} 🏆', AppColors.vertPrimaire),
                    ],
                  ),
                ),

                // Liste des Mondes et Niveaux
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: QuizData.mondes.length,
                    itemBuilder: (context, index) {
                      final monde = QuizData.mondes[index];
                      return _buildMondeCard(monde);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderStat(String label, String valeur, Color couleur) {
    return Column(
      children: [
        Text(valeur, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: couleur)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grisTexte)),
      ],
    );
  }

  Widget _buildMondeCard(MondeQuiz monde) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grisLigne),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du Monde
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.vertPrimaire.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(monde.icone, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monde ${monde.id} : ${monde.nom}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(monde.description, style: const TextStyle(fontSize: 11, color: AppColors.grisTexte)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Niveaux du monde
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: monde.niveaux.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, i) {
              final n = monde.niveaux[i];
              final estDebloque = (n.id <= _niveauMax);
              final etoiles = _etoilesMap[n.id] ?? 0;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: estDebloque ? (etoiles == 3 ? Colors.amber.shade100 : AppColors.vertClair.withValues(alpha: 0.2)) : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: estDebloque
                        ? Text('${n.id}', style: TextStyle(fontWeight: FontWeight.bold, color: etoiles == 3 ? Colors.amber.shade900 : AppColors.vertFonce))
                        : const Icon(Icons.lock, size: 18, color: Colors.grey),
                  ),
                ),
                title: Text(
                  n.titre,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: estDebloque ? AppColors.texteFort : Colors.grey.shade500,
                  ),
                ),
                subtitle: estDebloque
                    ? Row(
                        children: [
                          ...List.generate(3, (starIdx) => Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: starIdx < etoiles ? Colors.amber : Colors.grey.shade300,
                          )),
                          const SizedBox(width: 6),
                          Text(
                            etoiles > 0 ? '$etoiles/3 étoiles' : 'Non joué',
                            style: const TextStyle(fontSize: 11, color: AppColors.grisTexte),
                          ),
                        ],
                      )
                    : const Text('Verrouillé • Réussir le niveau précédent', style: TextStyle(fontSize: 11, color: Colors.grey)),
                trailing: estDebloque
                    ? ElevatedButton(
                        onPressed: () => _lancerNiveau(n),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: etoiles > 0 ? Colors.white : AppColors.vertPrimaire,
                          foregroundColor: etoiles > 0 ? AppColors.vertPrimaire : Colors.white,
                          side: etoiles > 0 ? const BorderSide(color: AppColors.vertPrimaire) : null,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: etoiles > 0 ? 0 : 2,
                        ),
                        child: Text(etoiles > 0 ? 'Rejouer' : 'Jouer', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
