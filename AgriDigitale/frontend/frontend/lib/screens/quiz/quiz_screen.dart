// Écran interactif du Quiz Agricole (Mode Snack en 3 questions).
// Déclencheurs de dopamine : confettis, retour haptique, explications bienveillantes et progression.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/design/app_colors.dart';
import '../../data/quiz_data.dart';
import '../../models/quiz_grade.dart';
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
  QuizGrade? _nouveauGrade;
  QuizGrade? _gradeActuel;

  @override
  void initState() {
    super.initState();
    _chargerGradeInitial();
  }

  Future<void> _chargerGradeInitial() async {
    final grade = await _quizService.getGradeActuel();
    if (mounted) {
      setState(() {
        _gradeActuel = grade;
      });
    }
  }

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
      final grade = await _quizService.getGradeActuel();
      if (!mounted) return;
      setState(() {
        _grainsGagnes = res.grainsGagnes;
        _streakActuel = res.streakActuel;
        _nouveauxBadges = res.nouveauxBadges;
        _gradeActuel = grade;
        _quizTermine = true;
      });
    } else if (widget.niveauId != null) {
      final res = await _quizService.enregistrerResultatNiveau(
        niveauId: widget.niveauId!,
        bonnesReponses: _bonnesReponses,
      );
      final streak = await _quizService.getStreakJours();
      final grade = await _quizService.getGradeActuel();
      if (!mounted) return;
      setState(() {
        _etoilesObtenues = res.etoiles;
        _grainsGagnes = res.grainsGagnes;
        _nouveauNiveauDebloque = res.niveauDebloque;
        _nouveauxBadges = res.nouveauxBadges;
        _nouveauGrade = res.nouveauGrade;
        _gradeActuel = grade;
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
        ? 'J\'ai obtenu $note au Quiz Agricole du Jour sur AgriDigitale ! Série de $_streakActuel jours. Peux-tu faire mieux ? Télécharge l\'application : https://agridigitale.net'
        : 'Je viens de réussir le "${widget.titre}" avec un score de $note sur l\'application AgriDigitale ! Peux-tu faire mieux ? https://agridigitale.net';
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barre de progression animée
          Row(
            children: [
              Text(
                'Question ${_questionIndex + 1}/$total',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: AppColors.vertPrimaire,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              const Icon(Icons.flash_on, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                '1 min snack',
                style: GoogleFonts.inter(color: AppColors.grisTexte, fontSize: 12),
              ),
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
          const SizedBox(height: 20),

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
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.4,
                color: AppColors.texteFort,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Grille 2x2 des 4 options de réponse
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _questionActuelle.options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, i) {
              final optionTexte = _questionActuelle.options[i];
              final estSelectionnee = (_reponseSelectionnee == i);
              final estLaBonneReponse = (i == _questionActuelle.bonneReponseIndex);

              Color fond = Colors.white;
              Color bordure = AppColors.grisLigne;
              Color texteCouleur = AppColors.texteFort;
              Color badgeFond = AppColors.grisPastille;
              Color badgeTexte = AppColors.texteFort;
              IconData? iconeStatut;
              double opacite = 1.0;

              if (_repondu) {
                if (estLaBonneReponse) {
                  fond = AppColors.vertClair.withValues(alpha: 0.2);
                  bordure = AppColors.vertPrimaire;
                  texteCouleur = AppColors.vertFonce;
                  badgeFond = AppColors.vertPrimaire;
                  badgeTexte = Colors.white;
                  iconeStatut = Icons.check_circle;
                } else if (estSelectionnee) {
                  fond = Colors.red.shade50;
                  bordure = Colors.red.shade400;
                  texteCouleur = Colors.red.shade900;
                  badgeFond = Colors.red;
                  badgeTexte = Colors.white;
                  iconeStatut = Icons.cancel;
                } else {
                  opacite = 0.55;
                }
              }

              return Opacity(
                opacity: opacite,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _repondu ? null : () => _validerReponse(i),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: fond,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: bordure,
                          width: estSelectionnee || (_repondu && estLaBonneReponse) ? 2.0 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: badgeFond,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    lettres[i],
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: badgeTexte,
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (iconeStatut != null)
                                Icon(
                                  iconeStatut,
                                  color: estLaBonneReponse ? AppColors.vertPrimaire : Colors.red,
                                  size: 20,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Center(
                              child: Text(
                                optionTexte,
                                textAlign: TextAlign.center,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: estSelectionnee || (_repondu && estLaBonneReponse)
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: texteCouleur,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Encadré d'explication bienveillante si répondu
          if (_repondu) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_reponseSelectionnee == _questionActuelle.bonneReponseIndex)
                    ? AppColors.vertClair.withValues(alpha: 0.15)
                    : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (_reponseSelectionnee == _questionActuelle.bonneReponseIndex)
                      ? AppColors.vertPrimaire.withValues(alpha: 0.4)
                      : Colors.amber.shade300,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    (_reponseSelectionnee == _questionActuelle.bonneReponseIndex)
                        ? Icons.check_circle_rounded
                        : Icons.lightbulb_rounded,
                    size: 26,
                    color: (_reponseSelectionnee == _questionActuelle.bonneReponseIndex)
                        ? AppColors.vertPrimaire
                        : Colors.amber.shade800,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (_reponseSelectionnee == _questionActuelle.bonneReponseIndex)
                              ? 'Excellent !'
                              : 'Bon à savoir :',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: (_reponseSelectionnee == _questionActuelle.bonneReponseIndex)
                                ? AppColors.vertFonce
                                : Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _questionActuelle.explication,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.black87,
                          ),
                        ),
                        if (_questionActuelle.astuceBonus != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Astuce : ${_questionActuelle.astuceBonus!}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppColors.vertFonce,
                              fontWeight: FontWeight.w500,
                            ),
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: Text(
                _questionIndex < widget.questions.length - 1 ? 'Question suivante →' : 'Voir mon score',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
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
          // Icône trophée vectorielle
          Icon(
            sansFaute
                ? Icons.emoji_events_rounded
                : (reussi ? Icons.stars_rounded : Icons.eco_rounded),
            size: 64,
            color: sansFaute
                ? Colors.amber.shade700
                : (reussi ? AppColors.vertPrimaire : Colors.teal),
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
                _buildStatItem('Grains', '+$_grainsGagnes', Icons.grain_rounded, Colors.orange),
                if (_streakActuel > 0)
                  _buildStatItem('Série', '$_streakActuel j', Icons.local_fire_department_rounded, Colors.redAccent),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Promotion de Grade Exceptionnelle
          if (_nouveauGrade != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_nouveauGrade!.couleurFond, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _nouveauGrade!.couleur, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _nouveauGrade!.couleur.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(_nouveauGrade!.icone, size: 38, color: _nouveauGrade!.couleur),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PROMOTION DE GRADE',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: _nouveauGrade!.couleur,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _nouveauGrade!.titre,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: AppColors.texteFort,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _nouveauGrade!.sousTitre,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.grisTexte,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_gradeActuel != null) ...[
            // Grade actuel du joueur et progression vers le prochain rang
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grisLigne),
              ),
              child: Row(
                children: [
                  Icon(_gradeActuel!.icone, size: 26, color: _gradeActuel!.couleur),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Rang : ${_gradeActuel!.titre}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _gradeActuel!.couleur,
                              ),
                            ),
                            const Spacer(),
                            if (widget.niveauId != null && QuizGrade.getProchainGrade(widget.niveauId!) != null)
                              Text(
                                '${QuizGrade.getNiveauxRestants(widget.niveauId!)} niv. avant promotion',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.grisTexte,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        if (widget.niveauId != null) ...[
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: QuizGrade.getProgressionVersProchainGrade(widget.niveauId!),
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(_gradeActuel!.couleur),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

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
                  Icon(badge.icone, size: 32, color: Colors.amber.shade800),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nouveau Badge : ${badge.nom}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber.shade900)),
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
