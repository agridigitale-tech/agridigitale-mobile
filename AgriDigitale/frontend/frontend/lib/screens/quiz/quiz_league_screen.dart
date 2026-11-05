// Écran de Tournoi Virtuel Éphémère "Ligue Argent" fidèle à la maquette officielle (Image 1).
// Intègre :
// - En-tête avec compteur de QI ("IQ: 149.4")
// - Bannière flamboyante "Ligue Argent" avec compte à rebours tournoi en temps réel
// - Statuette trophée en argent sur piédestal avec livre
// - Barre de progression segmentée (10 barres) et message d'encouragement
// - Classement dynamique (simulation du yoyo des rangs) avec joueur mis en vedette (GOAT 🇹🇬)
// - Bouton 3D vert "Continuer"
// - Barre d'actions & boosters inférieure (Mélange: 38, Annuler: 2, Indice: 17, Retour: 31)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/quiz_sound_service.dart';
import '../../services/quiz_tournament_service.dart';

class QuizLeagueScreen extends StatefulWidget {
  final VoidCallback? onContinuer;
  const QuizLeagueScreen({super.key, this.onContinuer});

  static void afficher(BuildContext context, {VoidCallback? onContinuer}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, __, ___) => QuizLeagueScreen(onContinuer: onContinuer),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  State<QuizLeagueScreen> createState() => _QuizLeagueScreenState();
}

class _QuizLeagueScreenState extends State<QuizLeagueScreen> with TickerProviderStateMixin {
  final _tournamentService = QuizTournamentService();
  final _soundService = QuizSoundService();

  double _iq = 149.4;
  String _ligueNom = 'Ligue Argent';
  Duration _tempsRestant = const Duration(hours: 23, minutes: 51, seconds: 35);
  Timer? _countdownTimer;

  List<JoueurTournoi> _classement = [];
  bool _chargement = true;

  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  String? _pseudoJoueur;
  bool _dialogueDejaAffiche = false;

  @override
  void initState() {
    super.initState();
    _soundService.playCorrect();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _chargerDonnees();
    _lancerCompteARebours();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _lancerCompteARebours() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_tempsRestant.inSeconds > 0) {
        setState(() {
          _tempsRestant = _tempsRestant - const Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _chargerDonnees() async {
    final iq = await _tournamentService.getIQ();
    final ligue = await _tournamentService.getLigueNom();
    final temps = await _tournamentService.getTempsRestantLigue();
    final pseudo = await _tournamentService.getPseudoJoueur();
    final classement = await _tournamentService.getClassementTournoi(pseudoJoueur: pseudo);

    if (mounted) {
      setState(() {
        _iq = iq;
        _ligueNom = ligue;
        _tempsRestant = temps;
        _pseudoJoueur = pseudo;
        _classement = classement;
        _chargement = false;
      });

      // Si le joueur n'a pas encore configuré son pseudo, on lui propose de le faire avec style
      if (pseudo == null && !_dialogueDejaAffiche) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _afficherDialogueChoisirPseudo(premierLancement: true);
        });
      }
    }
  }

  void _afficherDialogueChoisirPseudo({bool premierLancement = false}) {
    if (_dialogueDejaAffiche && premierLancement) return;
    if (premierLancement) _dialogueDejaAffiche = true;

    final controller = TextEditingController(text: _pseudoJoueur ?? 'Koffi_Agro 🇹🇬');

    showDialog(
      context: context,
      barrierDismissible: !premierLancement,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F2B1C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFFFD54F), width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.stars_rounded, color: Color(0xFFFFD54F), size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pseudo de Champion',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choisis le nom qui apparaîtra en haut du classement africain :',
                style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white70),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLength: 18,
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterStyle: const TextStyle(color: Colors.white54),
                  hintText: 'Ex: Koffi_Agro 🇹🇬',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF071A11),
                  prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFFFFD54F)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFFFD54F)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF00E676), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Suggestions rapides :',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFFFD54F)),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  'Koffi_Agro 🇹🇬',
                  'Epervier_Vert 🇹🇬',
                  'Champion_Togo 🇹🇬',
                  'Agri_Boss 🌾',
                  'Bio_Master 🌱',
                ].map((s) {
                  return ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: const Color(0xFF1B4D3E),
                    onPressed: () {
                      controller.text = s;
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          if (!premierLancement)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Annuler', style: GoogleFonts.poppins(color: Colors.white54)),
            ),
          ElevatedButton(
            onPressed: () async {
              final texte = controller.text.trim();
              if (texte.isNotEmpty) {
                await _tournamentService.setPseudoJoueur(texte);
                if (ctx.mounted) Navigator.pop(ctx);
                _chargerDonnees();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              'VALIDER MON PSEUDO',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  String _formaterTempsRestant() {
    final h = _tempsRestant.inHours.toString().padLeft(2, '0');
    final m = (_tempsRestant.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_tempsRestant.inSeconds % 60).toString().padLeft(2, '0');
    return '${h}h ${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071910), // Fond vert très sombre
      body: Stack(
        children: [
          // Arrière-plan dégradé ambiance jungle nuit
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.1,
                colors: [
                  Color(0xFF133620),
                  Color(0xFF092013),
                  Color(0xFF040F08),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. Barre supérieure (Retour, IQ, Menu)
                _buildTopBar(),

                // 2. Zone défilante : Trophée, Ligue et Classement
                Expanded(
                  child: _chargement
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              const SizedBox(height: 10),

                              // Bannière de la Ligue ("Ligue Argent")
                              _buildBanniereLigue(),

                              const SizedBox(height: 6),

                              // Compte à rebours
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.access_time_rounded, color: Colors.white70, size: 14),
                                  const SizedBox(width: 5),
                                  Text(
                                    _formaterTempsRestant(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // Trophée de la Ligue (Personnage érudit sur piédestal)
                              _buildTropheeArgent(),

                              const SizedBox(height: 14),

                              // Barre segmentée (10 segments)
                              _buildJaugeSegmentee(),

                              const SizedBox(height: 8),

                              // Message stimulant
                              Text(
                                'Tu es dans le Top 10 ! Tiens bon !',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1.5)),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Liste du classement des joueurs
                              _buildListeClassement(),

                              const SizedBox(height: 18),

                              // Bouton 3D vert "Continuer"
                              _buildBoutonContinuer(),

                              const SizedBox(height: 18),
                            ],
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bouton Retour circulaire rougeoyante
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFFE53935), Color(0xFF8E0000)],
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),

          // Score IQ
          Text(
            'IQ: ${_iq.toStringAsFixed(1)}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFFFE082),
              letterSpacing: 0.5,
            ),
          ),

          // Menu icône
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0xFFE53935), Color(0xFF8E0000)],
              ),
              boxShadow: [
                BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.format_list_bulleted_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBanniereLigue() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.4,
              colors: [
                const Color(0xFFFF9800).withValues(alpha: 0.8 * _glowAnimation.value),
                const Color(0xFFE65100).withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
          child: Text(
            _ligueNom,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFFFCC80),
              letterSpacing: 0.4,
              shadows: [
                Shadow(
                  color: const Color(0xFFFF6D00).withValues(alpha: 0.9),
                  blurRadius: 14,
                ),
                const Shadow(
                  color: Colors.black87,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTropheeArgent() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFFCFD8DC).withValues(alpha: 0.35),
            Colors.transparent,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Piédestal argenté étagé
          Positioned(
            bottom: 6,
            child: Container(
              width: 86,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFECEFF1),
                    Color(0xFFB0BEC5),
                    Color(0xFF78909C),
                    Color(0xFF455A64),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.white70, width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.diamond_rounded, color: Color(0xFF80DEEA), size: 16),
              ),
            ),
          ),

          // Mascotte argentée érudite
          Positioned(
            top: 10,
            child: Container(
              width: 74,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFECEFF1),
                    Color(0xFFCFD8DC),
                    Color(0xFF90A4AE),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB0BEC5).withValues(alpha: 0.8),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_rounded, color: Color(0xFF455A64), size: 28),
                  SizedBox(height: 2),
                  Icon(Icons.menu_book_rounded, color: Color(0xFF37474F), size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJaugeSegmentee() {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF04120A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(10, (i) {
          final estRempli = i < 6; // 6 segments allumés
          return Expanded(
            child: Container(
              height: 11,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: estRempli
                    ? const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFCFD8DC)],
                      )
                    : null,
                color: estRempli ? null : const Color(0xFF1E3326),
                boxShadow: estRempli
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.7),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildListeClassement() {
    return Column(
      children: _classement.map((joueur) {
        final estMoi = joueur.estJoueurActuel;

        return Container(
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: estMoi
                ? const Color(0xFF1E3A42) // Carte surlignée bleu foncé/cyan pour le joueur
                : const Color(0xFFFFF7E6), // Carte parchemin crème pour les adversaires
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: estMoi ? const Color(0xFF80DEEA) : const Color(0xFFE0D4BA),
              width: estMoi ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: estMoi ? 0.35 : 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 1. Rang
              SizedBox(
                width: 24,
                child: Text(
                  '${joueur.rang}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: estMoi ? const Color(0xFF80DEEA) : const Color(0xFF5D4037),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 2. Avatar avec badge de niveau
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: estMoi ? const Color(0xFF004D40) : const Color(0xFFFFE0B2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: estMoi ? const Color(0xFF00E676) : Colors.amber.shade700,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: _recupererAvatarIcone(joueur.avatar, estMoi),
                    ),
                  ),
                  Positioned(
                    top: -6,
                    left: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: estMoi ? const Color(0xFF00E676) : const Color(0xFF43A047),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${joueur.niveauBadge}',
                        style: GoogleFonts.poppins(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: estMoi ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // 3. Nom, Drapeau & Statut
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: estMoi ? () => _afficherDialogueChoisirPseudo() : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              joueur.nom,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: estMoi ? Colors.white : const Color(0xFF3E2723),
                              ),
                            ),
                          ),
                          if (estMoi) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD54F).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.edit_rounded, color: Color(0xFFFFD54F), size: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(joueur.drapeau, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF388E3C),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            joueur.statut,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 4. Tuile de score (comme sur la capture)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: estMoi ? const Color(0xFF0F262C) : const Color(0xFFEFEBE9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: estMoi ? const Color(0xFF80DEEA) : Colors.grey.shade400,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 15,
                      color: estMoi ? const Color(0xFF80DEEA) : const Color(0xFF5D4037),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${joueur.score}',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: estMoi ? Colors.white : const Color(0xFF3E2723),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 5. Cœur
              Column(
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    size: 16,
                    color: joueur.coeurs > 0 ? const Color(0xFFE53935) : Colors.grey.shade400,
                  ),
                  Text(
                    '${joueur.coeurs}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: estMoi ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _recupererAvatarIcone(String avatarCode, bool estMoi) {
    if (estMoi) {
      return const Text('🐼', style: TextStyle(fontSize: 20));
    }
    switch (avatarCode) {
      case 'elderly_woman':
      case 'grandma':
        return const Text('👵', style: TextStyle(fontSize: 20));
      case 'cat_warrior':
      case 'kitten':
        return const Text('🐱', style: TextStyle(fontSize: 20));
      case 'bunny':
        return const Text('🐰', style: TextStyle(fontSize: 20));
      case 'lion':
        return const Text('🦁', style: TextStyle(fontSize: 20));
      case 'bear':
        return const Text('🐻', style: TextStyle(fontSize: 20));
      case 'fox':
        return const Text('🦊', style: TextStyle(fontSize: 20));
      default:
        return const Text('🌾', style: TextStyle(fontSize: 20));
    }
  }

  Widget _buildBoutonContinuer() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          const BoxShadow(
            color: Color(0xFF1B5E20),
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.heavyImpact();
          _soundService.playVictory();
          if (widget.onContinuer != null) {
            widget.onContinuer!();
          } else {
            Navigator.pop(context);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF43A047),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: Color(0xFF81C784), width: 2),
          ),
        ),
        child: Text(
          'Continuer',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: const [
              Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}
