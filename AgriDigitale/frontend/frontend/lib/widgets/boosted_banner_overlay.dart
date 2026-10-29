import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/design/app_colors.dart';

/// Overlay affichant une bannière publicitaire boostée au milieu de l'écran :
/// - Format carré arrondi avec légère ombre portée
/// - Animation d'entrée douce (scale + fade)
/// - Bouton X au coin supérieur pour fermer manuellement
/// - Reste au milieu pendant 2 secondes, puis s'envole gracieusement vers le haut
/// - Clic sur la bannière -> ouvre le lien externe si présent
class BoostedBannerOverlay extends StatefulWidget {
  final Map<String, dynamic> banniere;
  final VoidCallback onDismissed;

  const BoostedBannerOverlay({
    super.key,
    required this.banniere,
    required this.onDismissed,
  });

  /// Affiche la bannière boostée sous forme d'overlay par-dessus n'importe quel écran (utile pour test/aperçu admin)
  static void afficherApercu(BuildContext context, Map<String, dynamic> banniere) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => BoostedBannerOverlay(
        banniere: banniere,
        onDismissed: () {
          entry.remove();
        },
      ),
    );
    Overlay.of(context).insert(entry);
  }

  @override
  State<BoostedBannerOverlay> createState() => _BoostedBannerOverlayState();
}

class _BoostedBannerOverlayState extends State<BoostedBannerOverlay>
    with TickerProviderStateMixin {
  // Contrôleur pour l'animation d'entrée (scale & fade in)
  late final AnimationController _entreeCtrl;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  // Contrôleur pour le départ vers le haut (slide out vers le haut & fade out)
  late final AnimationController _departCtrl;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _departFadeAnimation;

  Timer? _timerPause;
  bool _fermetureInitiee = false;

  @override
  void initState() {
    super.initState();

    // 1. Animation d'entrée : douce, 400ms avec léger rebond élastique
    _entreeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _entreeCtrl, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entreeCtrl, curve: Curves.easeOut),
    );

    // 2. Animation de départ vers le haut : 550ms
    _departCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -1.8),
    ).animate(
      CurvedAnimation(parent: _departCtrl, curve: Curves.easeInOutCubic),
    );
    _departFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _departCtrl, curve: Curves.easeIn),
    );

    // Lancement de la séquence
    _demarrerSequence();
  }

  void _demarrerSequence() async {
    // Entrée
    await _entreeCtrl.forward();

    // Reste affichée au milieu pendant 2 secondes
    _timerPause = Timer(const Duration(milliseconds: 2000), () {
      if (mounted && !_fermetureInitiee) {
        _partirEnHaut();
      }
    });
  }

  // Animation de départ vers le haut
  void _partirEnHaut() async {
    if (_fermetureInitiee || !mounted) return;
    _fermetureInitiee = true;
    _timerPause?.cancel();

    await _departCtrl.forward();

    if (mounted) {
      widget.onDismissed();
    }
  }

  // Fermeture manuelle immédiate via le bouton X
  void _fermer() {
    if (_fermetureInitiee || !mounted) return;
    _partirEnHaut();
  }

  // Ouverture du lien au clic sur la bannière
  Future<void> _ouvrirLien() async {
    final lien = widget.banniere['lien']?.toString().trim();
    if (lien != null && lien.isNotEmpty) {
      final uri = Uri.tryParse(lien);
      if (uri != null) {
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }
    }
    _fermer();
  }

  @override
  void dispose() {
    _timerPause?.cancel();
    _entreeCtrl.dispose();
    _departCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Dimension carré arrondi : environ 82% de la largeur d'écran, max 330px
    final cardSize = (size.width * 0.82).clamp(260.0, 330.0);
    final imageUrl = widget.banniere['image']?.toString() ?? '';

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: Listenable.merge([_entreeCtrl, _departCtrl]),
          builder: (context, child) {
            final opaciteFond = (_fadeAnimation.value * _departFadeAnimation.value * 0.45)
                .clamp(0.0, 1.0);

            return Stack(
              children: [
                // Arrière-plan semi-transparent pour détacher la bannière
                GestureDetector(
                  onTap: _fermer,
                  child: Container(
                    color: Colors.black.withValues(alpha: opaciteFond),
                  ),
                ),

                // Bannière centrée avec animations
                Center(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _departFadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          child: Container(
            width: cardSize,
            height: cardSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 28,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Carte carrée arrondie cliquable
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: GestureDetector(
                      onTap: _ouvrirLien,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imageUrl.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.vertPrimaire,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 48,
                                  color: AppColors.grisIcone,
                                ),
                              ),
                            )
                          else
                            Container(
                              color: AppColors.vertPrimaire,
                              child: const Center(
                                child: Icon(Icons.campaign, size: 54, color: Colors.white),
                              ),
                            ),

                          // Légère bordure blanche interne pour un rendu net et élégant
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bouton X au coin supérieur droit
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: _fermer,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.white,
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
  }
}
