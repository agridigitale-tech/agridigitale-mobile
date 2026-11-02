// Barre de progression des 5 Rangs / Grades de l'aventure Jungle Quiz.
// Reproduit fidèlement le pipeline horizontal présent sur les 3 maquettes :
// - Novice (Vert feuille)
// - Apprenti (Bleu végétal)
// - Expert (Bronze étoilé)
// - Maître (Violet couronne)
// - Légende (Or trophée / lauriers)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizJungleRanksBar extends StatelessWidget {
  final int niveauActuel;
  final Function(int tierIndex)? onRankTap;

  const QuizJungleRanksBar({
    super.key,
    required this.niveauActuel,
    this.onRankTap,
  });

  /// Détermine l'index du rang actif (0: Novice, 1: Apprenti, 2: Expert, 3: Maître, 4: Légende)
  int get activeTierIndex {
    if (niveauActuel <= 19) return 0;
    if (niveauActuel <= 39) return 1;
    if (niveauActuel <= 59) return 2;
    if (niveauActuel <= 79) return 3;
    return 4;
  }

  static const List<({String nom, IconData icone, Color couleurBase, Color couleurAccent, String intervalle})> _ranks = [
    (
      nom: 'Novice',
      icone: Icons.eco_rounded,
      couleurBase: Color(0xFF00E676),
      couleurAccent: Color(0xFF1B5E20),
      intervalle: 'Niveaux 1 à 19',
    ),
    (
      nom: 'Apprenti',
      icone: Icons.spa_rounded,
      couleurBase: Color(0xFF42A5F5),
      couleurAccent: Color(0xFF0D47A1),
      intervalle: 'Niveaux 20 à 39',
    ),
    (
      nom: 'Expert',
      icone: Icons.star_rounded,
      couleurBase: Color(0xFFFF9800),
      couleurAccent: Color(0xFFE65100),
      intervalle: 'Niveaux 40 à 59',
    ),
    (
      nom: 'Maître',
      icone: Icons.military_tech_rounded,
      couleurBase: Color(0xFFBA68C8),
      couleurAccent: Color(0xFF4A148C),
      intervalle: 'Niveaux 60 à 79',
    ),
    (
      nom: 'Légende',
      icone: Icons.emoji_events_rounded,
      couleurBase: Color(0xFFFFD54F),
      couleurAccent: Color(0xFFFF6F00),
      intervalle: 'Niveaux 80 à 100',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final active = activeTierIndex;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xDD0A2326),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.35), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ligne de connexion dorée en pointillé / continu au milieu des écussons
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              height: 2.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00E676).withValues(alpha: 0.7),
                    const Color(0xFFFFD54F).withValues(alpha: 0.9),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),

          // Les 5 Rangs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_ranks.length, (i) {
              final r = _ranks[i];
              final estActif = (i == active);
              final estPasse = (i < active);

              return GestureDetector(
                onTap: () => onRankTap != null ? onRankTap!(i) : _afficherDetailRang(context, r, estActif),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Écusson de grade
                    _buildEcusson(r, estActif, estPasse),
                    const SizedBox(height: 5),
                    // Pilule avec le nom du rang
                    _buildPiluleNom(r, estActif),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Écusson stylisé avec bouclier, halo et icône
  Widget _buildEcusson(
    ({String nom, IconData icone, Color couleurBase, Color couleurAccent, String intervalle}) r,
    bool estActif,
    bool estPasse,
  ) {
    final double taille = estActif ? 42.0 : 36.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: estActif
              ? [r.couleurBase, r.couleurAccent]
              : (estPasse
                  ? [r.couleurBase.withValues(alpha: 0.7), r.couleurAccent.withValues(alpha: 0.7)]
                  : [Colors.white24, Colors.black45]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: estActif ? Colors.white : (estPasse ? r.couleurBase : Colors.white24),
          width: estActif ? 2.5 : 1.5,
        ),
        boxShadow: estActif
            ? [
                BoxShadow(
                  color: r.couleurBase.withValues(alpha: 0.8),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
                const BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
              ]
            : (estPasse
                ? [BoxShadow(color: r.couleurBase.withValues(alpha: 0.4), blurRadius: 6)]
                : const []),
      ),
      child: Center(
        child: Icon(
          r.icone,
          color: estActif || estPasse ? Colors.white : Colors.white54,
          size: estActif ? 22 : 18,
        ),
      ),
    );
  }

  /// Pilule avec le nom du rang (Novice, Apprenti...)
  Widget _buildPiluleNom(
    ({String nom, IconData icone, Color couleurBase, Color couleurAccent, String intervalle}) r,
    bool estActif,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
        horizontal: estActif ? 8 : 6,
        vertical: estActif ? 2.5 : 1.5,
      ),
      decoration: BoxDecoration(
        color: estActif
            ? r.couleurBase
            : (const Color(0xFF07191B).withValues(alpha: 0.85)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: estActif ? Colors.white : r.couleurBase.withValues(alpha: 0.4),
          width: estActif ? 1.5 : 1.0,
        ),
        boxShadow: estActif
            ? [
                BoxShadow(
                  color: r.couleurBase.withValues(alpha: 0.6),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Text(
        r.nom,
        style: GoogleFonts.poppins(
          fontSize: estActif ? 10.5 : 9.5,
          fontWeight: FontWeight.w900,
          color: estActif
              ? (r.couleurBase == const Color(0xFFFFD54F) ? const Color(0xFF3E2723) : Colors.white)
              : Colors.white70,
          shadows: estActif ? [const Shadow(color: Colors.black45, blurRadius: 2)] : null,
        ),
      ),
    );
  }

  void _afficherDetailRang(
    BuildContext context,
    ({String nom, IconData icone, Color couleurBase, Color couleurAccent, String intervalle}) r,
    bool estActif,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF0F3025),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: r.couleurBase, width: 2),
          boxShadow: [
            BoxShadow(color: r.couleurBase.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [r.couleurBase, r.couleurAccent]),
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: Icon(r.icone, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              'Rang ${r.nom}',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              r.intervalle,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: r.couleurBase),
            ),
            const SizedBox(height: 12),
            Text(
              estActif
                  ? 'Vous êtes actuellement à ce rang prestigieux ! Continuez à gravir les échelons du Quiz Agricole.'
                  : 'Terminez les niveaux requis avec succès pour décrocher le titre de ${r.nom}.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: r.couleurBase,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('CONTINUER', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
