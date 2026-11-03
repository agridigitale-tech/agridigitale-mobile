import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/marches_data.dart';
import '../services/prix_produits_service.dart';
import 'produit_image_widget.dart';

/// Bande jaune d'alerte en superposition (en haut de l'écran d'accueil)
/// Affiche la hausse ou la baisse d'un produit avec animation de saisie clavier,
/// et disparaît automatiquement après 1 minute (60 secondes).
class BandeAlertePrixOverlay extends StatefulWidget {
  final AlertePrixMarche alerte;
  final VoidCallback onFermer;
  final VoidCallback? onTap;

  const BandeAlertePrixOverlay({
    super.key,
    required this.alerte,
    required this.onFermer,
    this.onTap,
  });

  @override
  State<BandeAlertePrixOverlay> createState() => _BandeAlertePrixOverlayState();
}

class _BandeAlertePrixOverlayState extends State<BandeAlertePrixOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  Timer? _typewriterTimer;
  Timer? _countdownTimer;
  Timer? _cursorTimer;

  String _texteAffiche = '';
  int _caractereIndex = 0;
  bool _showCursor = true;
  int _secondesRestantes = 60;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);

    // Calcul du temps restant par rapport aux 60 secondes prévues
    final ecoulee = DateTime.now().difference(widget.alerte.date).inSeconds;
    _secondesRestantes = (60 - ecoulee).clamp(1, 60);

    _animCtrl.forward();

    // 1. Démarrer l'animation de saisie clavier (typewriter)
    _demarrerAnimationClavier();

    // 2. Clignotement du curseur de saisie
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (mounted) {
        setState(() => _showCursor = !_showCursor);
      }
    });

    // 3. Décompte d'une minute (60s)
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _secondesRestantes--;
        if (_secondesRestantes <= 0) {
          t.cancel();
          _fermer();
        }
      });
    });
  }

  void _demarrerAnimationClavier() {
    final texteComplet = widget.alerte.texteAlerteClavier;
    _texteAffiche = '';
    _caractereIndex = 0;

    // Vitesse de frappe au clavier : 30ms par caractère
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 28), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_caractereIndex < texteComplet.length) {
        _caractereIndex++;
        setState(() {
          _texteAffiche = texteComplet.substring(0, _caractereIndex);
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _fermer() async {
    _typewriterTimer?.cancel();
    _countdownTimer?.cancel();
    _cursorTimer?.cancel();
    if (mounted) {
      await _animCtrl.reverse();
      widget.onFermer();
    }
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _countdownTimer?.cancel();
    _cursorTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alerte = widget.alerte;
    final isHausse = alerte.tendance == TendancePrix.hausse;
    final isBaisse = alerte.tendance == TendancePrix.baisse;

    final badgeColor = isHausse
        ? const Color(0xFFD32F2F)
        : (isBaisse ? const Color(0xFF1B5E20) : Colors.blueGrey);

    final badgeIcon = isHausse
        ? Icons.trending_up_rounded
        : (isBaisse ? Icons.trending_down_rounded : Icons.trending_flat_rounded);

    final badgeLibelle = isHausse ? 'HAUSSE' : (isBaisse ? 'BAISSE' : 'COURS');

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFEE58), // Jaune vif chaleureux
                Color(0xFFFFCA28), // Ambre doré
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFB300), width: 1.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: const Color(0xFFFFC107).withValues(alpha: 0.35),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    // Vignette photo réelle du produit
                    ProduitImageWidget(
                      nomProduit: alerte.produit,
                      imageOuIcone: alerte.imageOuIcone,
                      size: 38,
                      borderRadius: 10,
                    ),
                    const SizedBox(width: 8),

                    // Badge Tendance
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: badgeColor.withValues(alpha: 0.35),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, color: Colors.white, size: 13),
                          const SizedBox(width: 3),
                          Text(
                            badgeLibelle,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Texte avec animation de saisie clavier
                    Expanded(
                      child: RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: _texteAffiche,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1E1600),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                            if (_caractereIndex < alerte.texteAlerteClavier.length || _showCursor)
                              TextSpan(
                                text: '▍',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFD32F2F),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Badge décompte 60 secondes (1 min)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_secondesRestantes}s',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF422E00),
                        ),
                      ),
                    ),

                    // Bouton de fermeture manuelle (croix)
                    InkWell(
                      onTap: _fermer,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF422E00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
