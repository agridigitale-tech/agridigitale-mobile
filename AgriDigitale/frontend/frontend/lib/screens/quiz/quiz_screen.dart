// Écran officiel de question du Jungle Quiz Adventure.
// Reproduit fidèlement la maquette "Jungle Quiz Adventure Interface.png" :
// - Barre supérieure unifiée (Profil, Pièces d'or, Gemmes, Réglages)
// - Pipeline des 5 Rangs (Novice -> Légende)
// - Germain héros pointant du doigt avec ampoule lumineuse
// - En-tête avec Bannière en bois "Question X / 100" et Minuteur doré "00:45"
// - Grand panneau 3D parchemin en bois sculpté avec la question en grand et gras
// - 4 Grilles de réponse (Grille 2x2 avec A, B, C, D, textes et icônes thématiques)
// - Effet lumineux vert néon éclatant sur l'option sélectionnée (comme l'option A)
// - Barre d'actions inférieure : Bouton en bois "Retour", Récompense "+10 Bonne réponse", Bouton 3D vert "Valider"
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/quiz_data.dart';
import '../../models/quiz_grade.dart';
import '../../providers/auth_provider.dart';
import '../../services/quiz_service.dart';
import '../../services/quiz_sound_service.dart';
import '../../widgets/confetti_overlay.dart';
import '../../widgets/quiz/quiz_animated_host.dart';
import '../../widgets/quiz/quiz_coin_gain_overlay.dart';
import '../../widgets/quiz/quiz_rank_up_dialog.dart';
import 'quiz_jungle_top_bar.dart';
import 'quiz_jungle_ranks_bar.dart';

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

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  final _quizService = QuizService();
  final _soundService = QuizSoundService();
  final GlobalKey _coinTargetKey = GlobalKey();
  final GlobalKey<QuizCoinGainOverlayState> _coinOverlayKey = GlobalKey<QuizCoinGainOverlayState>();
  final GlobalKey<ConfettiOverlayState> _confettiKey = GlobalKey<ConfettiOverlayState>();

  int _questionIndex = 0;
  int _bonnesReponses = 0;
  int? _reponseSelectionnee;
  bool _repondu = false;
  int _secondesRestantes = 45;
  Timer? _countdownTimer;

  // Stats joueur
  int _pieces = 2350;
  final int _gemmes = 75;
  int _niveauMax = 7;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // ── Animations d'entrée spectaculaire et instantanée ──
  late AnimationController _entranceController;
  late Animation<double> _topOffsetAnimation;
  late Animation<double> _bottomOffsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _soundService.init();
    _soundService.setEstSurEcranJeu(true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Initialisation de l'animation d'entrée où le haut surgit du haut (-800px) et le bas du bas (+800px)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _topOffsetAnimation = Tween<double>(
      begin: -800.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
      ),
    );

    _bottomOffsetAnimation = Tween<double>(
      begin: 800.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Déclenchement dès que le premier affichage écran est prêt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _entranceController.forward(from: 0.0);
      }
    });

    _chargerStats();
    _demarrerMinuteur();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _glowController.dispose();
    _entranceController.dispose();
    _soundService.setEstSurEcranJeu(false);
    _soundService.stopAll();
    super.dispose();
  }

  Future<void> _chargerStats() async {
    final max = await _quizService.getNiveauMaxDebloque();
    final grains = await _quizService.getTotalGrains();
    if (mounted) {
      setState(() {
        _niveauMax = max;
        _pieces = grains > 0 ? grains : 2350;
      });
    }
  }

  void _demarrerMinuteur() {
    _countdownTimer?.cancel();
    _secondesRestantes = 45;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondesRestantes > 0) {
        setState(() => _secondesRestantes--);
        // Joue le tic-tac du chronomètre
        _soundService.playTick();
      } else {
        timer.cancel();
        if (!_repondu) {
          _validerReponseParTimeout();
        }
      }
    });
  }

  QuestionQuiz get _questionActuelle => widget.questions[_questionIndex];

  void _selectionnerOption(int index) {
    if (_repondu) return;
    _soundService.vibrateLight();
    setState(() {
      _reponseSelectionnee = index;
    });
  }

  void _validerReponse() {
    if (_reponseSelectionnee == null || _repondu) return;

    _countdownTimer?.cancel();
    final estCorrect = (_reponseSelectionnee == _questionActuelle.bonneReponseIndex);

    setState(() {
      _repondu = true;
      if (estCorrect) {
        _bonnesReponses++;
      }
    });

    if (estCorrect) {
      _soundService.playCorrect();
      _soundService.vibrateMedium();
      _confettiKey.currentState?.exploser();

      // Déclenche l'animation de jet de pièces volantes 3D
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final size = MediaQuery.of(context).size;
        final depart = Offset(size.width / 2, size.height * 0.70);
        final box = _coinTargetKey.currentContext?.findRenderObject() as RenderBox?;
        final cible = box != null
            ? box.localToGlobal(box.size.center(Offset.zero))
            : Offset(size.width * 0.62, 52);

        _coinOverlayKey.currentState?.animerGain(
          depart: depart,
          cible: cible,
          montant: 10,
          nombrePieces: 7,
          onComplete: () {
            if (mounted) {
              setState(() {
                _pieces += 10;
              });
            }
          },
        );
      });
    } else {
      _soundService.playWrong();
      _soundService.vibrateError();
    }

    // Affiche l'explication après l'animation festive
    Future.delayed(Duration(milliseconds: estCorrect ? 1400 : 900), () {
      if (mounted) {
        _afficherModalExplication(estCorrect);
      }
    });
  }

  void _validerReponseParTimeout() {
    setState(() {
      _repondu = true;
    });
    _soundService.playWrong();
    _soundService.vibrateError();
    _afficherModalExplication(false, estTempsEcoule: true);
  }

  void _passerQuestionSuivante() {
    if (_questionIndex < widget.questions.length - 1) {
      setState(() {
        _questionIndex++;
        _reponseSelectionnee = null;
        _repondu = false;
      });
      _demarrerMinuteur();
    } else {
      _terminerSessionQuiz();
    }
  }

  Future<void> _terminerSessionQuiz() async {
    int etoiles = 0;
    if (_bonnesReponses == widget.questions.length) {
      etoiles = 3;
    } else if (_bonnesReponses >= (widget.questions.length * 0.6).ceil()) {
      etoiles = 2;
    } else if (_bonnesReponses > 0) {
      etoiles = 1;
    }

    QuizGrade? nouveauGrade;
    int grainsGagnes = _bonnesReponses * 10;

    if (widget.niveauId != null) {
      final res = await _quizService.enregistrerResultatNiveau(
        niveauId: widget.niveauId!,
        bonnesReponses: _bonnesReponses,
      );
      nouveauGrade = res.nouveauGrade;
      grainsGagnes = res.grainsGagnes;
    } else if (widget.estQuizDuJour) {
      final res = await _quizService.enregistrerResultatQuizDuJour(
        bonnesReponses: _bonnesReponses,
      );
      grainsGagnes = res.grainsGagnes;
    }

    if (mounted) {
      _afficherVictoireModal(
        etoiles: etoiles,
        grainsGagnes: grainsGagnes,
        nouveauGrade: nouveauGrade,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nomAffiche = auth.nomUtilisateur ?? 'Germain_Ahobli';

    return ConfettiOverlay(
      key: _confettiKey,
      child: QuizCoinGainOverlay(
        key: _coinOverlayKey,
        child: Scaffold(
          backgroundColor: const Color(0xFF0A231C),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // ── Fond Jungle Visuel Immersif ──
              Image.asset(
                'assets/images/quiz_jungle_roadmap_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF0F3827),
                ),
              ),

              // Voile sombre pour lisibilité maximale des questions et cartes
              Container(
                color: Colors.black.withValues(alpha: 0.35),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // 1 & 2. Haut : Barre supérieure & Barre des 5 Rangs (surgit de -800px)
                    AnimatedBuilder(
                      animation: _entranceController,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _topOffsetAnimation.value),
                        child: Opacity(
                          opacity: _opacityAnimation.value,
                          child: child,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QuizJungleTopBar(
                            coinKey: _coinTargetKey,
                            userName: nomAffiche,
                            niveau: _niveauMax,
                            pieces: _pieces,
                            gemmes: _gemmes,
                            afficherLogo: false,
                          ),
                          QuizJungleRanksBar(
                            niveauActuel: _niveauMax,
                            onRankTap: (_) {
                              QuizRankUpDialog.afficher(
                                context,
                                nouveauGrade: QuizGrade.getGradePourNiveau(_niveauMax),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),

                    // 3. Zone Centrale (Question en haut, Grille de réponses en bas)
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Column(
                          children: [
                            // En-tête de la question (Bannière, Minuteur, Germain, Parchemin - surgit de -800px)
                            AnimatedBuilder(
                              animation: _entranceController,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(0, _topOffsetAnimation.value),
                                child: Opacity(
                                  opacity: _opacityAnimation.value,
                                  child: child,
                                ),
                              ),
                              child: _buildSectionQuestionHeader(),
                            ),
                            const SizedBox(height: 10),
                            // Grille 2x2 des 4 Réponses (surgit de +800px)
                            AnimatedBuilder(
                              animation: _entranceController,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(0, _bottomOffsetAnimation.value),
                                child: Opacity(
                                  opacity: _opacityAnimation.value,
                                  child: child,
                                ),
                              ),
                              child: _buildGrilleReponses(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 4. Barre d'Actions Inférieure (Retour, +10 Récompense, Valider - surgit de +800px)
                    AnimatedBuilder(
                      animation: _entranceController,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _bottomOffsetAnimation.value),
                        child: Opacity(
                          opacity: _opacityAnimation.value,
                          child: child,
                        ),
                      ),
                      child: _buildBarreActionInferieure(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// En-tête de la question : Germain qui pointe, Bannière Question X/100, Minuteur doré, et Panneau Parchemin
  Widget _buildSectionQuestionHeader() {
    return Column(
      children: [
        // Ligne Bannière Question X/100 + Minuteur Doré
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Bannière en bois Question X/100
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8D5B28), Color(0xFF5D3A1A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD54F), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Question ${_questionIndex + 1} / ${widget.questions.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ],
              ),
            ),

            // Minuteur doré "00:45"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _secondesRestantes <= 10
                      ? [const Color(0xFFFF5252), const Color(0xFFC62828)]
                      : [const Color(0xFFFFD54F), const Color(0xFFFF8F00)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: (_secondesRestantes <= 10 ? Colors.red : Colors.amber).withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '00:${_secondesRestantes.toString().padLeft(2, '0')}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: const [Shadow(color: Colors.black45, blurRadius: 2)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Ligne avec l'Animatrice de Quiz et le Panneau Parchemin de Question
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Animatrice animée (yeux clignotants, bouche parlante et lecture TTS automatique)
            QuizAnimatedHost(
              texteQuestion: _questionActuelle.question,
              largeur: 95,
              hauteur: 130,
            ),

            const SizedBox(width: 8),

            // Panneau 3D en bois avec parchemin contenant la Question
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8C7), // Texture parchemin beige chaud
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF7A4A21), width: 3.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
                    BoxShadow(color: Color(0xFF5D3A1A), blurRadius: 0, offset: Offset(0, 3)),
                  ],
                ),
                child: Text(
                  _questionActuelle.question,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2E1A0E),
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Grille 2x2 des 4 Réponses avec A, B, C, D et illustrations thématiques
  Widget _buildGrilleReponses() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, i) {
        final optionTexte = i < _questionActuelle.options.length ? _questionActuelle.options[i] : 'Option ${i + 1}';
        final lettre = ['A', 'B', 'C', 'D'][i];
        final estSelectionnee = (_reponseSelectionnee == i);
        final estCorrecte = (_repondu && i == _questionActuelle.bonneReponseIndex);
        final estFausse = (_repondu && estSelectionnee && !estCorrecte);

        return GestureDetector(
          onTap: () => _selectionnerOption(i),
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: estCorrecte
                        ? [const Color(0xFF2E7D32), const Color(0xFF1B5E20)]
                        : (estFausse
                            ? [const Color(0xFFD32F2F), const Color(0xFFB71C1C)]
                            : (estSelectionnee
                                ? [const Color(0xFFFFF9C4), const Color(0xFFFFECB3)]
                                : [const Color(0xFFFBF4E2), const Color(0xFFF3E5AB)])),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: estCorrecte
                        ? const Color(0xFF00E676)
                        : (estFausse
                            ? Colors.redAccent
                            : (estSelectionnee
                                ? const Color(0xFF00E676)
                                : const Color(0xFFB07D48))),
                    width: estSelectionnee || estCorrecte || estFausse ? 3.0 : 2.0,
                  ),
                  boxShadow: [
                    if (estSelectionnee || estCorrecte)
                      BoxShadow(
                        color: const Color(0xFF00E676).withValues(alpha: estSelectionnee ? _glowAnimation.value * 0.75 : 0.8),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    const BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    // Badge rond vert avec lettre A, B, C, D
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: estCorrecte
                              ? [const Color(0xFF00E676), const Color(0xFF1B5E20)]
                              : (estFausse
                                  ? [Colors.red, Colors.red.shade900]
                                  : [const Color(0xFF00E676), const Color(0xFF2E7D32)]),
                        ),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1)),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          lettre,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Texte de la réponse
                    Expanded(
                      child: Text(
                        optionTexte,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: estCorrecte || estFausse ? Colors.white : const Color(0xFF2E1A0E),
                          height: 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // Illustration thématique automatique (Plante, Mégaphone, Ampoule, Vache...)
                    _buildIconeThematique(optionTexte, i, estCorrecte || estFausse),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Icône vectorielle thématique adaptée au contenu de l'option
  Widget _buildIconeThematique(String texte, int index, bool inverserCouleur) {
    final t = texte.toLowerCase();
    IconData icone = Icons.eco_rounded;
    Color couleur = const Color(0xFF2E7D32);

    if (t.contains('bruit') || t.contains('son') || t.contains('parler')) {
      icone = Icons.campaign_rounded;
      couleur = Colors.redAccent;
    } else if (t.contains('lumière') || t.contains('soleil') || t.contains('chaleur')) {
      icone = Icons.wb_sunny_rounded;
      couleur = const Color(0xFFFFB300);
    } else if (t.contains('animal') || t.contains('animaux') || t.contains('vache') || t.contains('bête')) {
      icone = Icons.pets_rounded;
      couleur = const Color(0xFF6D4C41);
    } else if (t.contains('eau') || t.contains('pluie') || t.contains('arroser')) {
      icone = Icons.water_drop_rounded;
      couleur = Colors.blue;
    } else if (t.contains('terre') || t.contains('sol') || t.contains('compost')) {
      icone = Icons.landscape_rounded;
      couleur = const Color(0xFF8D6E63);
    } else {
      // Variantes d'icônes par défaut
      const defaultIcons = [Icons.eco_rounded, Icons.spa_rounded, Icons.grass_rounded, Icons.park_rounded];
      icone = defaultIcons[index % defaultIcons.length];
    }

    return Icon(
      icone,
      color: inverserCouleur ? Colors.white : couleur,
      size: 26,
    );
  }

  /// Barre d'actions inférieure (Retour, +10 Bonne Réponse, Valider)
  Widget _buildBarreActionInferieure() {
    final bool peutValider = (_reponseSelectionnee != null && !_repondu);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bouton en bois "⬅ Retour"
          GestureDetector(
            onTap: _confirmerRetour,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8D5B28), Color(0xFF5D3A1A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    'Retour',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bannière centrale en bois "+10 🪙 Bonne réponse"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8D5B28), Color(0xFF5D3A1A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '+ 10',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD54F), size: 16),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 13),
                    const SizedBox(width: 2),
                    Text(
                      'Bonne réponse',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFD54F),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Grand Bouton 3D Vert "✔ Valider"
          GestureDetector(
            onTap: peutValider ? _validerReponse : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: peutValider
                      ? [const Color(0xFF00E676), const Color(0xFF1B5E20)]
                      : [Colors.grey.shade600, Colors.grey.shade800],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: peutValider ? Colors.white : Colors.white24,
                  width: 2.2,
                ),
                boxShadow: [
                  if (peutValider)
                    BoxShadow(
                      color: const Color(0xFF00E676).withValues(alpha: 0.6),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  const BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: peutValider ? Colors.white : Colors.white54,
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Valider',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: peutValider ? Colors.white : Colors.white54,
                      shadows: peutValider ? [const Shadow(color: Colors.black45, blurRadius: 2)] : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmerRetour() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F3025),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFFD54F), width: 1.5),
        ),
        title: Text(
          'Quitter le niveau ?',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Votre progression actuelle sur ce niveau sera perdue si vous quittez maintenant.',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CONTINUER', style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('QUITTER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _afficherModalExplication(bool estCorrect, {bool estTempsEcoule = false}) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF0F3025),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: estCorrect ? const Color(0xFF00E676) : Colors.redAccent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (estCorrect ? const Color(0xFF00E676) : Colors.redAccent).withValues(alpha: 0.5),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  estCorrect
                      ? Icons.check_circle_rounded
                      : (estTempsEcoule ? Icons.timer_off_rounded : Icons.cancel_rounded),
                  color: estCorrect ? const Color(0xFF00E676) : Colors.redAccent,
                  size: 34,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    estCorrect
                        ? 'Excellente réponse ! +10 Pièces 🪙'
                        : (estTempsEcoule ? 'Temps écoulé !' : 'Oups, ce n\'est pas tout à fait ça !'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _questionActuelle.explication,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _passerQuestionSuivante();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _questionIndex < widget.questions.length - 1 ? 'QUESTION SUIVANTE ➔' : 'VOIR LES RÉSULTATS',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _afficherVictoireModal({
    required int etoiles,
    required int grainsGagnes,
    QuizGrade? nouveauGrade,
  }) {
    if (etoiles > 0) {
      _soundService.playVictory();
      _soundService.vibrateHeavy();
    } else {
      _soundService.playWrong();
      _soundService.vibrateError();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F3025),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0xFFFFD54F), width: 3),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD54F), size: 54),
            const SizedBox(height: 8),
            Text(
              'NIVEAU TERMINÉ !',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final estEtoileGagnee = (i < etoiles);
                return Icon(
                  Icons.star_rounded,
                  size: 38,
                  color: estEtoileGagnee ? const Color(0xFFFFD54F) : Colors.white24,
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              'Bonnes réponses : $_bonnesReponses / ${widget.questions.length}',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF071913),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QuizCoinGainOverlay.build3DCoin(taille: 20),
                  const SizedBox(width: 8),
                  Text(
                    '+$grainsGagnes Pièces d\'or remportées',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFFFFD54F),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (nouveauGrade != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: nouveauGrade.degrade),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: nouveauGrade.couleur.withValues(alpha: 0.6),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(nouveauGrade.icone, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'PROMOTION : ${nouveauGrade.titre.toUpperCase()}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            // Bouton de célébration du Rang (avec distinction si promotion ou rang actuel)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                final gradeAffiche = nouveauGrade ?? QuizGrade.getGradePourNiveau(_niveauMax);
                QuizRankUpDialog.afficher(
                  context,
                  nouveauGrade: gradeAffiche,
                  onContinuer: () {
                    Navigator.pop(context, true);
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD54F),
                foregroundColor: const Color(0xFF2E1A0E),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.workspace_premium_rounded, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    nouveauGrade != null
                        ? 'VOIR MON NOUVEAU RANG ➔'
                        : 'VOIR MON RANG (${QuizGrade.getGradePourNiveau(_niveauMax).titre.toUpperCase()}) ➔',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (nouveauGrade != null) {
                  QuizRankUpDialog.afficher(
                    context,
                    nouveauGrade: nouveauGrade,
                    onContinuer: () {
                      Navigator.pop(context, true);
                    },
                  );
                } else {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'RETOUR À LA ROADMAP',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
