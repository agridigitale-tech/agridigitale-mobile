// Widget de suivi de lecture audio en temps réel (Karaoké / Prompteur)
// Affiche l'animation mot par mot synchronisée avec la synthèse vocale (TTS).

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/design/app_colors.dart';

// ── Modèle d'un mot dans le texte en cours de lecture ──
class MotLecture {
  final String mot;
  final int debut;
  final int fin;

  const MotLecture({
    required this.mot,
    required this.debut,
    required this.fin,
  });

  static List<MotLecture> extraireMots(String texte) {
    final List<MotLecture> mots = [];
    final regex = RegExp(r'\S+');
    for (final match in regex.allMatches(texte)) {
      mots.add(MotLecture(
        mot: match.group(0)!,
        debut: match.start,
        fin: match.end,
      ));
    }
    return mots;
  }
}

// ── État global de la lecture audio ──
class EtatLectureAudio {
  final bool estActif;
  final bool estEnLecture;
  final bool estEnPause;
  final double vitesse;
  final int indexMorceau;
  final int totalMorceaux;
  final String morceauTexte;
  final List<MotLecture> mots;
  final int indexMotActuel;
  final String titreArticle;
  final bool estReduit;

  const EtatLectureAudio({
    this.estActif = false,
    this.estEnLecture = false,
    this.estEnPause = false,
    this.vitesse = 0.5,
    this.indexMorceau = 0,
    this.totalMorceaux = 0,
    this.morceauTexte = '',
    this.mots = const [],
    this.indexMotActuel = -1,
    this.titreArticle = '',
    this.estReduit = false,
  });

  factory EtatLectureAudio.initial() => const EtatLectureAudio();

  EtatLectureAudio copyWith({
    bool? estActif,
    bool? estEnLecture,
    bool? estEnPause,
    double? vitesse,
    int? indexMorceau,
    int? totalMorceaux,
    String? morceauTexte,
    List<MotLecture>? mots,
    int? indexMotActuel,
    String? titreArticle,
    bool? estReduit,
  }) {
    return EtatLectureAudio(
      estActif: estActif ?? this.estActif,
      estEnLecture: estEnLecture ?? this.estEnLecture,
      estEnPause: estEnPause ?? this.estEnPause,
      vitesse: vitesse ?? this.vitesse,
      indexMorceau: indexMorceau ?? this.indexMorceau,
      totalMorceaux: totalMorceaux ?? this.totalMorceaux,
      morceauTexte: morceauTexte ?? this.morceauTexte,
      mots: mots ?? this.mots,
      indexMotActuel: indexMotActuel ?? this.indexMotActuel,
      titreArticle: titreArticle ?? this.titreArticle,
      estReduit: estReduit ?? this.estReduit,
    );
  }
}

// ── Barres d'égaliseur animées (Spectre sonore) ──
class BarresEgaliseur extends StatefulWidget {
  final bool enLecture;
  final Color couleur;
  final double taille;

  const BarresEgaliseur({
    super.key,
    required this.enLecture,
    this.couleur = AppColors.vertPrimaire,
    this.taille = 18.0,
  });

  @override
  State<BarresEgaliseur> createState() => _BarresEgaliseurState();
}

class _BarresEgaliseurState extends State<BarresEgaliseur>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    if (widget.enLecture) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant BarresEgaliseur oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enLecture && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.enLecture && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        return SizedBox(
          width: widget.taille,
          height: widget.taille,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBarre(0.3 + 0.7 * math.sin(t * math.pi)),
              _buildBarre(0.2 + 0.8 * math.sin(((t + 0.3) % 1.0) * math.pi)),
              _buildBarre(0.4 + 0.6 * math.sin(((t + 0.6) % 1.0) * math.pi)),
              _buildBarre(0.25 + 0.75 * math.sin(((t + 0.85) % 1.0) * math.pi)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBarre(double facteur) {
    final hauteur = (widget.taille * facteur.clamp(0.18, 1.0)).toDouble();
    return Container(
      width: 2.8,
      height: hauteur,
      decoration: BoxDecoration(
        color: widget.couleur,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ── Widget Principal : Bandeau Karaoké Flottant ──
class BandeauKaraokeLecture extends StatefulWidget {
  final ValueNotifier<EtatLectureAudio> notifier;
  final VoidCallback onLectureToggle;
  final VoidCallback onPrecedent;
  final VoidCallback onSuivant;
  final VoidCallback onChangerVitesse;
  final VoidCallback onArreter;
  final VoidCallback onOuvrirPrompteur;
  final ValueChanged<int> onSauterVersMot;
  final VoidCallback onBasculerReduction;

  const BandeauKaraokeLecture({
    super.key,
    required this.notifier,
    required this.onLectureToggle,
    required this.onPrecedent,
    required this.onSuivant,
    required this.onChangerVitesse,
    required this.onArreter,
    required this.onOuvrirPrompteur,
    required this.onSauterVersMot,
    required this.onBasculerReduction,
  });

  @override
  State<BandeauKaraokeLecture> createState() => _BandeauKaraokeLectureState();
}

class _BandeauKaraokeLectureState extends State<BandeauKaraokeLecture> {
  final ScrollController _motsScrollCtrl = ScrollController();
  final GlobalKey _motActifKey = GlobalKey();
  bool _menuCasqueOuvert = false;

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_surChangementEtat);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_surChangementEtat);
    _motsScrollCtrl.dispose();
    super.dispose();
  }

  void _surChangementEtat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_motActifKey.currentContext != null) {
        Scrollable.ensureVisible(
          _motActifKey.currentContext!,
          alignment: 0.45,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<EtatLectureAudio>(
      valueListenable: widget.notifier,
      builder: (context, etat, child) {
        // ── CAS 1 : Aucune lecture démarrée (Mode veille) ──
        if (!etat.estActif) {
          return _buildBoutonCasqueVeille();
        }

        // ── CAS 2 : Lecture active mais réduite en bas à gauche ──
        if (etat.estReduit) {
          return _buildBoutonCasqueReduit(etat);
        }

        // ── CAS 3 : Lecteur Karaoké complet déployé ──
        return _buildBandeauComplet(etat);
      },
    );
  }

  // Bouton casque seul quand la lecture est en veille
  Widget _buildBoutonCasqueVeille() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.grey.shade300, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Bouton Casque Toggle
              InkWell(
                onTap: () {
                  setState(() => _menuCasqueOuvert = !_menuCasqueOuvert);
                },
                borderRadius: BorderRadius.circular(26),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.vertFonce, AppColors.vertPrimaire],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.headphones_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              // Dropdown horizontal animé
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  child: _menuCasqueOuvert
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                color: AppColors.vertPrimaire,
                                size: 28,
                              ),
                              tooltip: 'Écouter',
                              onPressed: widget.onLectureToggle,
                            ),
                            InkWell(
                              onTap: widget.onChangerVitesse,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.vertPrimaire.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${widget.notifier.value.vitesse == 0.5 ? '1.0' : (widget.notifier.value.vitesse == 0.65 ? '1.25' : '1.5')}x',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.vertPrimaire,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bouton casque compact quand le lecteur est minimisé
  Widget _buildBoutonCasqueReduit(EtatLectureAudio etat) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onBasculerReduction,
          borderRadius: BorderRadius.circular(26),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.vertPrimaire, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.vertPrimaire.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppColors.vertPrimaire,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.headphones_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                BarresEgaliseur(enLecture: etat.estEnLecture, taille: 16),
                const SizedBox(width: 8),
                Text(
                  etat.estEnLecture ? 'Lecture...' : 'En pause',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.vertPrimaire,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.expand_less_rounded, color: AppColors.vertPrimaire, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Bandeau complet avec suivi de lecture Karaoké mot par mot
  Widget _buildBandeauComplet(EtatLectureAudio etat) {
    final vitesseStr = etat.vitesse == 0.5 ? '1.0x' : (etat.vitesse == 0.65 ? '1.25x' : '1.5x');

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: etat.estEnLecture
                ? AppColors.vertPrimaire.withValues(alpha: 0.6)
                : Colors.grey.shade300,
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── En-tête : Égaliseur + État + Actions Rapides ──
            Row(
              children: [
                BarresEgaliseur(enLecture: etat.estEnLecture, taille: 16),
                const SizedBox(width: 8),
                Text(
                  etat.estEnLecture ? 'ÉCOUTE EN DIRECT' : 'EN PAUSE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: etat.estEnLecture ? AppColors.vertPrimaire : Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 6),
                if (etat.totalMorceaux > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.vertPrimaire.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${etat.indexMorceau + 1} / ${etat.totalMorceaux}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.vertPrimaire,
                      ),
                    ),
                  ),
                const Spacer(),
                // Bouton Mode Prompteur plein écran
                IconButton(
                  icon: const Icon(Icons.open_in_full_rounded, size: 18, color: AppColors.vertPrimaire),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Mode Prompteur (Plein écran)',
                  onPressed: widget.onOuvrirPrompteur,
                ),
                // Bouton Réduire
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Réduire le lecteur',
                  onPressed: widget.onBasculerReduction,
                ),
                // Bouton Fermer / Arrêter
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Colors.redAccent),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Arrêter la lecture',
                  onPressed: widget.onArreter,
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ── Zone Karaoké des mots en temps réel ──
            Container(
              height: 66,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.vertPrimaire.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.vertPrimaire.withValues(alpha: 0.15)),
              ),
              child: SingleChildScrollView(
                controller: _motsScrollCtrl,
                child: etat.mots.isEmpty
                    ? Center(
                        child: Text(
                          etat.morceauTexte.isNotEmpty ? etat.morceauTexte : 'Préparation de la lecture...',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      )
                    : Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: List.generate(etat.mots.length, (i) {
                          final m = etat.mots[i];
                          final estActif = i == etat.indexMotActuel;
                          final estPasse = i < etat.indexMotActuel;

                          return GestureDetector(
                            key: estActif ? _motActifKey : null,
                            onTap: () => widget.onSauterVersMot(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              padding: EdgeInsets.symmetric(
                                horizontal: estActif ? 7.0 : 3.0,
                                vertical: estActif ? 3.0 : 1.0,
                              ),
                              decoration: BoxDecoration(
                                color: estActif
                                    ? AppColors.vertPrimaire
                                    : (estPasse
                                        ? Colors.grey.withValues(alpha: 0.08)
                                        : Colors.transparent),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: estActif
                                    ? [
                                        BoxShadow(
                                          color: AppColors.vertPrimaire.withValues(alpha: 0.38),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 140),
                                scale: estActif ? 1.08 : 1.0,
                                child: Text(
                                  m.mot,
                                  style: TextStyle(
                                    fontSize: estActif ? 15.0 : 13.5,
                                    fontWeight: estActif
                                        ? FontWeight.bold
                                        : (estPasse ? FontWeight.normal : FontWeight.w500),
                                    color: estActif
                                        ? Colors.white
                                        : (estPasse ? Colors.grey[600] : Colors.black87),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Commandes de Lecture : Précédent, Lecture/Pause, Suivant, Vitesse ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Morceau précédent
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, color: AppColors.vertPrimaire, size: 26),
                  tooltip: 'Phrase précédente',
                  onPressed: etat.indexMorceau > 0 ? widget.onPrecedent : null,
                ),

                // Bouton Lecture / Pause
                InkWell(
                  onTap: widget.onLectureToggle,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: etat.estEnLecture
                            ? const [AppColors.vertPrimaire, Color(0xFF66BB6A)]
                            : const [AppColors.vertFonce, AppColors.vertPrimaire],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.vertPrimaire.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      etat.estEnLecture ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),

                // Morceau suivant
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, color: AppColors.vertPrimaire, size: 26),
                  tooltip: 'Phrase suivante',
                  onPressed: etat.indexMorceau < etat.totalMorceaux - 1 ? widget.onSuivant : null,
                ),

                // Vitesse
                InkWell(
                  onTap: widget.onChangerVitesse,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.vertPrimaire.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      vitesseStr,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.vertPrimaire,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Écran Modal : Mode Prompteur / Immersion Plein Écran ──
class PrompteurPleinEcranSheet extends StatefulWidget {
  final ValueNotifier<EtatLectureAudio> notifier;
  final VoidCallback onLectureToggle;
  final VoidCallback onPrecedent;
  final VoidCallback onSuivant;
  final VoidCallback onChangerVitesse;
  final VoidCallback onArreter;
  final ValueChanged<int> onSauterVersMot;

  const PrompteurPleinEcranSheet({
    super.key,
    required this.notifier,
    required this.onLectureToggle,
    required this.onPrecedent,
    required this.onSuivant,
    required this.onChangerVitesse,
    required this.onArreter,
    required this.onSauterVersMot,
  });

  @override
  State<PrompteurPleinEcranSheet> createState() => _PrompteurPleinEcranSheetState();
}

class _PrompteurPleinEcranSheetState extends State<PrompteurPleinEcranSheet> {
  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _motActifSheetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_surChangementEtat);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_surChangementEtat);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _surChangementEtat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_motActifSheetKey.currentContext != null) {
        Scrollable.ensureVisible(
          _motActifSheetKey.currentContext!,
          alignment: 0.5,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<EtatLectureAudio>(
      valueListenable: widget.notifier,
      builder: (context, etat, child) {
        final vitesseStr = etat.vitesse == 0.5 ? '1.0x' : (etat.vitesse == 0.65 ? '1.25x' : '1.5x');

        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Poignée supérieure
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // En-tête
              Row(
                children: [
                  BarresEgaliseur(enLecture: etat.estEnLecture, taille: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MODE PROMPTEUR (SUIVI DE LECTURE)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.vertPrimaire,
                          ),
                        ),
                        if (etat.titreArticle.isNotEmpty)
                          Text(
                            etat.titreArticle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                  if (etat.totalMorceaux > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.vertPrimaire.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Partie ${etat.indexMorceau + 1} / ${etat.totalMorceaux}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.vertPrimaire,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Corps de lecture grand format avec mots animés
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FBF9),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.vertPrimaire.withValues(alpha: 0.15)),
                  ),
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    child: etat.mots.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Text(
                                etat.morceauTexte.isNotEmpty ? etat.morceauTexte : 'Chargement du texte...',
                                style: const TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ),
                          )
                        : Wrap(
                            spacing: 6,
                            runSpacing: 8,
                            children: List.generate(etat.mots.length, (i) {
                              final m = etat.mots[i];
                              final estActif = i == etat.indexMotActuel;
                              final estPasse = i < etat.indexMotActuel;

                              return GestureDetector(
                                key: estActif ? _motActifSheetKey : null,
                                onTap: () => widget.onSauterVersMot(i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: estActif ? 10.0 : 4.0,
                                    vertical: estActif ? 5.0 : 2.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: estActif
                                        ? AppColors.vertPrimaire
                                        : (estPasse
                                            ? Colors.grey.withValues(alpha: 0.10)
                                            : Colors.transparent),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: estActif
                                        ? [
                                            BoxShadow(
                                              color: AppColors.vertPrimaire.withValues(alpha: 0.40),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 140),
                                    scale: estActif ? 1.10 : 1.0,
                                    child: Text(
                                      m.mot,
                                      style: TextStyle(
                                        fontSize: estActif ? 20.0 : 18.0,
                                        fontWeight: estActif
                                            ? FontWeight.bold
                                            : (estPasse ? FontWeight.normal : FontWeight.w500),
                                        color: estActif
                                            ? Colors.white
                                            : (estPasse ? Colors.grey[600] : AppColors.texteFort),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Commandes de Lecture en bas du Prompteur
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, color: AppColors.vertPrimaire, size: 32),
                    onPressed: etat.indexMorceau > 0 ? widget.onPrecedent : null,
                  ),
                  InkWell(
                    onTap: widget.onLectureToggle,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: etat.estEnLecture
                              ? const [AppColors.vertPrimaire, Color(0xFF66BB6A)]
                              : const [AppColors.vertFonce, AppColors.vertPrimaire],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.vertPrimaire.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        etat.estEnLecture ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, color: AppColors.vertPrimaire, size: 32),
                    onPressed: etat.indexMorceau < etat.totalMorceaux - 1 ? widget.onSuivant : null,
                  ),
                  InkWell(
                    onTap: widget.onChangerVitesse,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.vertPrimaire.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        vitesseStr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.vertPrimaire,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
