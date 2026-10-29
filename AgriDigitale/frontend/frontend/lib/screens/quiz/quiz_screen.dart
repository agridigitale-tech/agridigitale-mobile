// Écran interactif du Quiz Agricole (Mode Snack en 3 questions).
// Déclencheurs de dopamine : confettis, retour haptique, explications bienveillantes et progression.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/design/app_colors.dart';
import '../../data/quiz_data.dart';
import '../../services/quiz_service.dart';
import '../../widgets/confetti_overlay.dart';

class QuizScreen extends StatefulWidget {
  final List<QuestionQuiz> questions;
  final String titre;
  final int? niveauId;
  final bool estQuizDuJour;

  const QuizScreen({
    super.key,
    required this.questions,
    required this.titre,
    this.niveauId,
    this.estQuizDuJour = false,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _quizService = QuizService();
  int _questionIndex = 0;
  int _bonnesReponses = 0;
  int? _reponseSelectionnee;
  bool _repondu = false;
  bool _quizTermine = false;

  // Résultats finaux
  int _etoilesObtenues = 0;
  int _grainsGagnes = 0;
  int _streakActuel = 0;
  bool _nouveauNiveauDebloque = false;
  List<BadgeQuiz> _nouveauxBadges = [];

  QuestionQuiz get _questionActuelle => widget.questions[_questionIndex];

  void _validerReponse(int index) {
    if (_repondu) return;

    setState(() {
      _reponseSelectionnee = index;
      _repondu = true;
    });

    final estCorrect = (index == _questionActuelle.bonneReponseIndex);

    if (estCorrect) {
      _bonnesReponses++;
      HapticFeedback.mediumImpact();
      ConfettiOverlay.of(context)?.exploser();
    } else {
      HapticFeedback.vibrate();
    }
  }

  void _passerSuivant() {
    if (_questionIndex < widget.questions.length - 1) {
      setState(() {
        _questionIndex++;
        _reponseSelectionnee = null;
        _repondu = false;
      });
    } else {
      _finaliserQuiz();
    }
  }

  Future<void> _finaliserQuiz() async {
    if (widget.estQuizDuJour) {
      final res = await _quizService.enregistrerResultatQuizDuJour(
        bonnesReponses: _bonnesReponses,
      );
      if (!mounted) return;
      setState(() {
        _grainsGagnes = res.grainsGagnes;
        _streakActuel = res.streakActuel;
        _nouveauxBadges = res.nouveauxBadges;
        _quizTermine = true;
      });
    } else if (widget.niveauId != null) {
      final res = await _quizService.enregistrerResultatNiveau(
        niveauId: widget.niveauId!,
        bonnesReponses: _bonnesReponses,
      );
      final streak = await _quizService.getStreakJours();
      if (!mounted) return;
      setState(() {
        _etoilesObtenues = res.etoiles;
        _grainsGagnes = res.grainsGagnes;
        _nouveauNiveauDebloque = res.niveauDebloque;
        _nouveauxBadges = res.nouveauxBadges;
        _streakActuel = streak;
        _quizTermine = true;
      });
    } else {
      setState(() {
        _quizTermine = true;
      });
    }

    if (!mounted) return;

    // Explosion de célébration finale si au moins 2 bonnes réponses
    if (_bonnesReponses >= 2) {
      ConfettiOverlay.of(context)?.exploser();
    }
  }

  void _partagerResultat() {
    final note = '$_bonnesReponses/${widget.questions.length}';
    final texte = widget.estQuizDuJour
        ? '🌾 J\'ai obtenu $note au Quiz Agricole du Jour sur AgriDigitale ! 🔥 Série de $_streakActuel jours. Peux-tu faire mieux ? Télécharge l\'application : https://agridigitale.net'
        : '🌾 Je viens de réussir le "${widget.titre}" avec un score de $note sur l\'application AgriDigitale ! Peux-tu faire mieux ? https://agridigitale.net';
    Share.share(texte);
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiOverlay(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: _quizTermine ? _buildVueResultat() : _buildVueQuestion(),
        ),
      ),
    );
  }

  // ── Vue de la question en cours ──
  Widget _buildVueQuestion() {
    final total = widget.questions.length;
    final progression = (_questionIndex + 1) / total;
    const lettres = ['A', 'B', 'C', 'D'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barre de progression animée
          Row(
            children: [
              Text(
                'Question ${_questionIndex + 1}/$total',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.vertPrimaire, fontSize: 13),
              ),
              const Spacer(),
              const Icon(Icons.flash_on, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              const Text('1 min snack', style: TextStyle(color: AppColors.grisTexte, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progression,
              minHeight: 8,
              backgroundColor: AppColors.grisLigne,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.vertPrimaire),
            ),
          ),
          const SizedBox(height: 24),

          // Carte de la question
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              _questionActuelle.question,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, height: 1.4),
            ),
          ),
          const SizedBox(height: 20),

          // Options de réponse
          Expanded(
            child: ListView.separated(
              itemCount: _questionActuelle.options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final optionTexte = _questionActuelle.options[i];
                final estSelectionnee = (_reponseSelectionnee == i);
                final estLaBonneReponse = (i == _questionActuelle.bonneReponseIndex);

                Color fond = Colors.white;
                Color bordure = AppColors.grisLigne;
                Color texteCouleur = AppColors.texteFort;
                IconData? iconeStatut;

                if (_repondu) {
                  if (estLaBonneReponse) {
                    fond = AppColors.vertClair.withValues(alpha: 0.18);
                    bordure = AppColors.vertPrimaire;
                    texteCouleur = AppColors.vertFonce;
                    iconeStatut = Icons.check_circle;
                  } else if (estSelectionnee) {
                    fond = Colors.red.shade50;
                    bordure = Colors.red.shade400;
                    texteCouleur = Colors.red.shade900;
                    iconeStatut = Icons.cancel;
                  }
                }

                return InkWell(
                  onTap: _repondu ? null : () => _validerReponse(i),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: fond,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: bordure, width: estSelectionnee || (_repondu && estLaBonneReponse) ? 2.0 : 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: (_repondu && estLaBonneReponse)
                                ? AppColors.vertPrimaire
                                : ((_repondu && estSelectionnee) ? Colors.red : AppColors.grisPastille),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              lettres[i],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: (_repondu && (estLaBonneReponse || estSelectionnee)) ? Colors.white : AppColors.texteFort,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            optionTexte,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: estSelectionnee ? FontWeight.bold : FontWeight.w500,
                              color: texteCouleur,
                            ),
                          ),
                        ),
                        if (iconeStatut != null) ...[
                          const SizedBox(width: 8),
                          Icon(iconeStatut, color: (_repondu && estLaBonneReponse) ? AppColors.vertPrimaire : Colors.red, size: 22),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Encadré d'explication bienveillante si répondu
          if (_repondu) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (_reponseSelectionnee == _questionActuelle.bonneReponseIndex)
                    ? AppColors.vertClair.withValues(alpha: 0.12)
                    : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_reponseSelectionnee == _questionActuelle.bonneReponseIndex)
                      ? AppColors.vertPrimaire.withValues(alpha: 0.3)
                      : Colors.amber.shade300,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (_reponseSelectionnee == _questionActuelle.bonneReponseIndex) ? '👏' : '💡',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (_reponseSelectionnee == _questionActuelle.bonneReponseIndex)
                              ? 'Excellent !'
                              : 'Bon à savoir :',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: (_reponseSelectionnee == _questionActuelle.bonneReponseIndex)
                                ? AppColors.vertFonce
                                : Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _questionActuelle.explication,
                          style: const TextStyle(fontSize: 13, height: 1.35),
                        ),
                        if (_questionActuelle.astuceBonus != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Astuce : ${_questionActuelle.astuceBonus!}',
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.vertFonce),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _passerSuivant,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vertPrimaire,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _questionIndex < widget.questions.length - 1 ? 'Question suivante →' : 'Voir mon score 🎉',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Vue finale des résultats avec récompenses ──
  Widget _buildVueResultat() {
    final total = widget.questions.length;
    final sansFaute = (_bonnesReponses == total);
    final reussi = (_bonnesReponses >= 2);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        children: [
          // Émoticône ou trophée
          Text(
            sansFaute ? '🏆' : (reussi ? '🌟' : '🌱'),
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 10),
          Text(
            sansFaute
                ? 'Score Parfait !'
                : (reussi ? 'Félicitations !' : 'Bel essai !'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            sansFaute
                ? 'Vous maîtrisez parfaitement ce sujet.'
                : (reussi
                    ? 'Vous avez validé cette étape avec brio.'
                    : 'Rejouez pour perfectionner vos connaissances.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.grisTexte, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Étoiles animées si mode niveau
          if (widget.niveauId != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final active = (i < _etoilesObtenues);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.star_rounded,
                    size: 48,
                    color: active ? Colors.amber : Colors.grey.shade300,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],

          // Carte récapitulative des gains
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Score', '$_bonnesReponses/$total', Icons.check_circle_outline, AppColors.vertPrimaire),
                _buildStatItem('Grains', '+$_grainsGagnes 🌾', Icons.monetization_on_outlined, Colors.orange),
                if (_streakActuel > 0)
                  _buildStatItem('Série', '$_streakActuel j 🔥', Icons.local_fire_department, Colors.redAccent),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Nouveau niveau débloqué
          if (_nouveauNiveauDebloque) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.vertClair.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.vertPrimaire),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_open, color: AppColors.vertPrimaire, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nouveau Niveau Débloqué !', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.vertFonce)),
                        Text('Continuez votre progression vers le statut d\'Expert.', style: TextStyle(fontSize: 12, color: AppColors.grisTexte)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Badges nouvellement obtenus
          if (_nouveauxBadges.isNotEmpty) ...[
            ..._nouveauxBadges.map((badge) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade400),
              ),
              child: Row(
                children: [
                  Text(badge.icone, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nouveau Badge : ${badge.nom} 🏆', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber.shade900)),
                        Text(badge.description, style: const TextStyle(fontSize: 12, color: AppColors.grisTexte)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],

          // Bouton de partage WhatsApp (viralité naturelle)
          OutlinedButton.icon(
            onPressed: _partagerResultat,
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Défier des amis sur WhatsApp'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF25D366),
              side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          // Bouton rejouer ou terminer
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vertPrimaire,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Terminer & Retour', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String valeur, IconData icone, Color couleur) {
    return Column(
      children: [
        Icon(icone, color: couleur, size: 24),
        const SizedBox(height: 4),
        Text(valeur, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        Text(label, style: const TextStyle(color: AppColors.grisTexte, fontSize: 11)),
      ],
    );
  }
}
