// Écran d'accueil et de démarrage du Jungle Quiz Adventure.
// Reproduit fidèlement la maquette "Jungle Quiz Adventure with Germain.png" :
// - Barre supérieure avec Germain_Ahobli, Niveau, Pièces d'or, Gemmes et Réglages
// - Pipeline des 5 Rangs (Novice -> Légende)
// - Scène immersive Jungle avec Germain héros, Panneau en bois 3D "Quiz" & Chapeau diplômé
// - Carte parchemin "Réponds aux questions, gagne des étoiles et atteins le rang Légende !"
// - Bouton 3D doré éclatant "▶ Commencer" menant à la Roadmap des 100 niveaux
// - Conteneur à 3 atouts (Étoiles, Récompenses, Rang)
// - Barre de navigation inférieure (Accueil, Stats, Quiz, Récompenses, Classement)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/quiz_service.dart';
import '../../services/quiz_sound_service.dart';
import 'quiz_jungle_top_bar.dart';
import 'quiz_jungle_ranks_bar.dart';
import 'quiz_niveaux_screen.dart';
import 'quiz_league_screen.dart';
import 'quiz_daily_screen.dart';

class QuizWelcomeScreen extends StatefulWidget {
  const QuizWelcomeScreen({super.key});

  @override
  State<QuizWelcomeScreen> createState() => QuizWelcomeScreenState();
}

class QuizWelcomeScreenState extends State<QuizWelcomeScreen> with TickerProviderStateMixin {
  final _quizService = QuizService();
  final _soundService = QuizSoundService();

  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _signFloat;

  // ── Animations d'entrée spectaculaire du jeu ──
  late AnimationController _entranceController;
  late Animation<double> _topOffsetAnimation;
  late Animation<double> _bottomOffsetAnimation;
  late Animation<double> _opacityAnimation;

  int _niveauMax = 1;
  int _totalGrains = 2350;
  int _totalEtoiles = 0;
  int _streak = 0;
  final int _gemmes = 75;

  @override
  void initState() {
    super.initState();
    _soundService.init();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _signFloat = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialisation de l'animation d'arrivée : le haut surgit du haut (-800px), le bas du bas (+800px)
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

    // Déclenchement dès que le rendu écran est prêt pour être visible à 100%
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        rejouerAnimationEntree();
      }
    });

    _chargerStats();
    _quizService.changeNotifier.addListener(_chargerStats);
  }

  /// Rejoue l'animation d'entrée chaque fois qu'on clique sur l'onglet Jeux
  void rejouerAnimationEntree() {
    if (!mounted) return;
    _entranceController.reset();
    _entranceController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entranceController.dispose();
    _quizService.changeNotifier.removeListener(_chargerStats);
    super.dispose();
  }

  Future<void> _chargerStats() async {
    final max = await _quizService.getNiveauMaxDebloque();
    final grains = await _quizService.getTotalGrains();
    final etoiles = await _quizService.getTotalEtoiles();
    final streak = await _quizService.getStreakJours();

    if (mounted) {
      setState(() {
        _niveauMax = max;
        // Si les grains sont à 0 par défaut, afficher une base de départ valorisante
        _totalGrains = grains > 0 ? grains : 2350;
        _totalEtoiles = etoiles;
        _streak = streak;
      });
    }
  }

  void _lancerAventure() {
    HapticFeedback.heavyImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const QuizNiveauxScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nomAffiche = auth.nomUtilisateur ?? 'Germain_Ahobli';

    return Scaffold(
      backgroundColor: const Color(0xFF071C17),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fond d'écran officiel Jungle Quiz Adventure (Misty Sunbeams Rainforest) ──
          Positioned.fill(
            child: Image.asset(
              'assets/images/quiz_jungle_roadmap_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F3827), Color(0xFF071C17)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // Voile sombre progressif pour sublimer la jungle tropicale et détacher l'interface
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.35),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── Contenu Interactif ──
          SafeArea(
            child: Column(
              children: [
                // 1 & 2. Haut : Barre supérieure & Pipeline des Rangs (surgit de -800px)
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
                        userName: nomAffiche,
                        niveau: _niveauMax,
                        pieces: _totalGrains,
                        gemmes: _gemmes,
                        afficherLogo: false,
                      ),
                      QuizJungleRanksBar(
                        niveauActuel: _niveauMax,
                      ),
                    ],
                  ),
                ),

                // ── Titre & Panneau Central 3D Jungle (surgit de -800px) ──
                Expanded(
                  child: AnimatedBuilder(
                    animation: _entranceController,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _topOffsetAnimation.value),
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: child,
                      ),
                    ),
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _signFloat,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, _signFloat.value),
                          child: child,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 280),
                            child: Image.asset(
                              'assets/images/quiz_jungle_logo_sign.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Bas : Carte Parchemin, Bouton Commencer, Atouts & Dock (surgit de +800px) ──
                AnimatedBuilder(
                  animation: _entranceController,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _bottomOffsetAnimation.value),
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: child,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 3. Carte Parchemin incitative
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3D6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFD4A373), width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                                  ),
                                ),
                                child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Réponds aux questions, gagne des étoiles et atteins le rang Légende !',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF3E2723),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 4. Grand Bouton 3D Doré "▶ Commencer"
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: AnimatedBuilder(
                          animation: _pulseScale,
                          builder: (context, child) => Transform.scale(
                            scale: _pulseScale.value,
                            child: child,
                          ),
                          child: GestureDetector(
                            onTap: _lancerAventure,
                            child: Container(
                              width: double.infinity,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFEA00), Color(0xFFFF9100), Color(0xFFFF6D00)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF9100).withValues(alpha: 0.75),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                  const BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFFF8F00), size: 30),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Commencer',
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                      shadows: const [
                                        Shadow(color: Color(0xFFBF360C), offset: Offset(0, 2), blurRadius: 4),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 5. Conteneur des 3 Atouts (Étoiles, Récompenses, Rang)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xCC06251E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.4), width: 1.2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildAtoutItem(
                                icone: Icons.star_rounded,
                                couleurIcone: const Color(0xFFFFD54F),
                                texteLigne1: 'Gagne',
                                texteLigne2: 'des étoiles',
                              ),
                              _buildSeparateurVertical(),
                              _buildAtoutItem(
                                icone: Icons.card_giftcard_rounded,
                                couleurIcone: const Color(0xFFFF7043),
                                texteLigne1: 'Débloque',
                                texteLigne2: 'des récompenses',
                              ),
                              _buildSeparateurVertical(),
                              _buildAtoutItem(
                                icone: Icons.trending_up_rounded,
                                couleurIcone: const Color(0xFF00E676),
                                texteLigne1: 'Améliore',
                                texteLigne2: 'ton rang',
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 6. Dock inférieur (Accueil, Stats, Quiz, Récompenses, Classement)
                      _buildBottomDock(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtoutItem({
    required IconData icone,
    required Color couleurIcone,
    required String texteLigne1,
    required String texteLigne2,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, color: couleurIcone, size: 26),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              texteLigne1,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.1,
              ),
            ),
            Text(
              texteLigne2,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeparateurVertical() {
    return Container(
      width: 1,
      height: 26,
      color: Colors.white24,
    );
  }

  Widget _buildBottomDock() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xEE041A28),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF0288D1).withValues(alpha: 0.5), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDockBouton(Icons.home_rounded, 'Accueil', onTap: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          }),
          _buildDockBouton(Icons.bar_chart_rounded, 'Stats', onTap: _afficherModalStats),
          // Onglet Quiz Actif Surélevé & Doré
          _buildDockBoutonQuizActif(),
          _buildDockBouton(Icons.card_giftcard_rounded, 'Récompenses', onTap: _afficherModalBadges),
          _buildDockBouton(Icons.emoji_events_rounded, 'Classement', onTap: _afficherModalClassement),
        ],
      ),
    );
  }

  Widget _buildDockBouton(IconData icone, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, color: Colors.white70, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockBoutonQuizActif() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1E88E5),
            ),
            child: const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 2),
          Text(
            'Quiz',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF3E2723),
            ),
          ),
        ],
      ),
    );
  }

  void _afficherModalStats() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Color(0xFF0F3025),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Vos Performances', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatPill('Niveau Max', '$_niveauMax / 100', Icons.flag_rounded, const Color(0xFF00E676)),
                _buildStatPill('Étoiles', '$_totalEtoiles', Icons.star_rounded, const Color(0xFFFFD54F)),
                _buildStatPill('Série', '$_streak j', Icons.local_fire_department_rounded, const Color(0xFFFF7043)),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String titre, String valeur, IconData icone, Color couleur) {
    return Column(
      children: [
        Icon(icone, color: couleur, size: 28),
        const SizedBox(height: 4),
        Text(valeur, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(titre, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  void _afficherModalBadges() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Color(0xFF0F3025),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Récompenses & Badges', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: QuizService.tousLesBadges.map((b) {
                return Chip(
                  avatar: Icon(b.icone, color: const Color(0xFFFFD54F), size: 18),
                  label: Text(b.nom, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: const Color(0xFF1B4D3E),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Accès direct aux Victoires Quotidiennes
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                QuizDailyScreen.afficher(context);
              },
              icon: const Icon(Icons.calendar_today_rounded, size: 20),
              label: const Text('✦ VICTOIRES QUOTIDIENNES ✦', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white24,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('FERMER', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _afficherModalClassement() {
    // Lance directement l'Écran officiel de Tournoi Virtuel Éphémère "Ligue Argent" (Image 1)
    QuizLeagueScreen.afficher(context);
  }
}
