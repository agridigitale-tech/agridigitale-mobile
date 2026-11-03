// Modalité de réglages interactive pour le Quiz Jungle Adventure.
// Permet d'activer/désactiver en temps réel :
// 1. La musique apaisante en boucle (Kalimba & Marimba - instruments en bois détente jungle)
// 2. Les effets sonores (tic-tac, bonne/mauvaise réponse, victoire)
// 3. La lecture vocale automatique des questions par l'animatrice
// 4. Les retours haptiques (vibrations)
// Persisté automatiquement dans SharedPreferences.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/quiz_sound_service.dart';

class QuizSettingsDialog extends StatefulWidget {
  const QuizSettingsDialog({super.key});

  static Future<void> afficher(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const QuizSettingsDialog(),
    );
  }

  @override
  State<QuizSettingsDialog> createState() => _QuizSettingsDialogState();
}

class _QuizSettingsDialogState extends State<QuizSettingsDialog> {
  final _soundService = QuizSoundService();

  @override
  void initState() {
    super.initState();
    _soundService.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    _soundService.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: const Color(0xFF0C2A20),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFFD54F), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF00E676).withValues(alpha: 0.15),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── En-tête Jungle ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF134233), Color(0xFF0C2A20)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF8F00).withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.settings_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OPTIONS DU JEU',
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Musique, Effets, Voix & Vibrations',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF00E676),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0x33FFFFFF), height: 1),

              // ── Liste des Réglages interactifs ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    // 1. Musique Zen Jungle (Kalimba & Marimba)
                    _buildMusiqueSection(),

                    const SizedBox(height: 10),

                    // 2. Effets Sonores
                    _buildReglageSwitch(
                      icone: Icons.volume_up_rounded,
                      couleurIcone: const Color(0xFFFFD54F),
                      titre: 'Effets Sonores',
                      description: 'Tic-tac, bonne & mauvaise réponse',
                      valeur: _soundService.soundEnabled,
                      onChanged: (val) {
                        _soundService.setSoundEnabled(val);
                        if (val) {
                          _soundService.playCorrect();
                        }
                      },
                    ),

                    const SizedBox(height: 10),

                    // 3. Lecture Vocale Automatique
                    _buildReglageSwitch(
                      icone: Icons.record_voice_over_rounded,
                      couleurIcone: const Color(0xFF00E676),
                      titre: 'Lecture Vocale',
                      description: 'L\'animatrice lit les questions',
                      valeur: _soundService.voiceEnabled,
                      onChanged: (val) {
                        _soundService.setVoiceEnabled(val);
                        if (val) {
                          _soundService.vibrateLight();
                        }
                      },
                    ),

                    const SizedBox(height: 10),

                    // 4. Vibrations & Retours Haptiques
                    _buildReglageSwitch(
                      icone: Icons.vibration_rounded,
                      couleurIcone: const Color(0xFFFF7043),
                      titre: 'Retours Haptiques',
                      description: 'Vibrations au clic et réponses',
                      valeur: _soundService.hapticsEnabled,
                      onChanged: (val) {
                        _soundService.setHapticsEnabled(val);
                        if (val) {
                          _soundService.vibrateMedium();
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    // 🌿 Carte explicative "Jeu de détente"
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF071C17),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF00E676).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.spa_rounded, color: Color(0xFF00E676), size: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pour un jeu de détente optimal, nous utilisons un son doux de rivière qui coule accompagné de légers chants d\'oiseaux paisibles sans cris. Vous pouvez choisir votre ambiance ou désactiver la musique à tout moment dans ces options.',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                color: const Color(0xFFE0E0E0),
                                height: 1.35,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bouton Fermer Doré ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'TERMINER',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF3E2723),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Section dédiée à la musique relaxante Jungle (Rivière & Oiseaux, Kalimba, Marimba)
  Widget _buildMusiqueSection() {
    final estActif = _soundService.musicEnabled;
    final typeActuel = _soundService.musicType;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x66081D16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: estActif ? const Color(0xFF00E676).withValues(alpha: 0.45) : Colors.white12,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF81D4FA).withValues(alpha: 0.15),
                  border: Border.all(color: const Color(0xFF81D4FA).withValues(alpha: 0.4), width: 1.2),
                ),
                child: const Icon(Icons.waves_rounded, color: Color(0xFF81D4FA), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ambiance Relaxante',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Rivière qui coule & chants d\'oiseaux doux',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: estActif,
                onChanged: (val) {
                  _soundService.setMusicEnabled(val);
                },
                activeTrackColor: const Color(0xFF00E676),
                activeThumbColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                inactiveThumbColor: Colors.white60,
              ),
            ],
          ),

          // Choix de l'ambiance si la musique est activée
          if (estActif) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildBoutonInstrument(
                          titre: 'Rivière & Oiseaux',
                          sousTitre: 'Doux & naturel (détente)',
                          estSelectionne: typeActuel == 'riviere',
                          onTap: () => _soundService.setMusicType('riviere'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBoutonInstrument(
                          titre: 'Kalimba Zen',
                          sousTitre: 'Méditatif',
                          estSelectionne: typeActuel == 'kalimba',
                          onTap: () => _soundService.setMusicType('kalimba'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildBoutonInstrument(
                          titre: 'Marimba Jungle',
                          sousTitre: 'Chaud & boisé',
                          estSelectionne: typeActuel == 'marimba',
                          onTap: () => _soundService.setMusicType('marimba'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBoutonInstrument({
    required String titre,
    required String sousTitre,
    required bool estSelectionne,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          gradient: estSelectionne
              ? const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: estSelectionne ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: estSelectionne ? const Color(0xFF00E676) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Text(
              titre,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: estSelectionne ? FontWeight.w800 : FontWeight.w600,
                color: estSelectionne ? Colors.white : Colors.white70,
              ),
            ),
            Text(
              sousTitre,
              style: GoogleFonts.poppins(
                fontSize: 9.5,
                color: estSelectionne ? const Color(0xFF00E676) : Colors.white38,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReglageSwitch({
    required IconData icone,
    required Color couleurIcone,
    required String titre,
    required String description,
    required bool valeur,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x66081D16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: valeur ? const Color(0xFF00E676).withValues(alpha: 0.4) : Colors.white12,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: couleurIcone.withValues(alpha: 0.15),
              border: Border.all(color: couleurIcone.withValues(alpha: 0.4), width: 1.2),
            ),
            child: Icon(icone, color: couleurIcone, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: valeur,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF00E676),
            activeThumbColor: Colors.white,
            inactiveTrackColor: Colors.white24,
            inactiveThumbColor: Colors.white60,
          ),
        ],
      ),
    );
  }
}
