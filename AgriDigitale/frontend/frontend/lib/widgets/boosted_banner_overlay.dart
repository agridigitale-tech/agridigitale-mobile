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
    // Format de la bannière : affichée telle qu'elle est (sans rognage ni déformation)
    final maxCardWidth = (size.width * 0.92).clamp(280.0, 450.0);
    final maxCardHeight = (size.height * 0.65).clamp(200.0, 520.0);
    final imageUrl = widget.banniere['image']?.toString() ?? '';

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: Listenable.merge([_entreeCtrl, _departCtrl]),
          builder: (context, child) {
            final opaciteFond = (_fadeAnimation.value * _departFadeAnimation.value * 0.50)
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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxCardWidth,
              maxHeight: maxCardHeight,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.40),
                    blurRadius: 28,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Carte bannière affichée dans son format original sans coupure
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: GestureDetector(
                      onTap: _ouvrirLien,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 1.5,
                          ),
                        ),
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.contain, // Affiche toute la bannière telle qu'elle est
                                placeholder: (context, url) => Container(
                                  height: 160,
                                  color: Colors.grey[100],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.vertPrimaire,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 160,
                                  color: Colors.grey[200],
                                  padding: const EdgeInsets.all(16),
                                  child: const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.campaign,
                                          size: 44,
                                          color: AppColors.vertPrimaire,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Bannière AgriDigitale',
                                          style: TextStyle(
                                            color: AppColors.grisTexte,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                height: 160,
                                color: AppColors.vertPrimaire,
                                child: const Center(
                                  child: Icon(Icons.campaign, size: 54, color: Colors.white),
                                ),
                              ),
                      ),
                    ),
                  ),

                  // Bouton X au coin supérieur droit (légèrement décalé pour ne rien masquer)
                  Positioned(
                    top: -12,
                    right: -12,
                    child: GestureDetector(
                      onTap: _fermer,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 20,
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
      ),
    );
  }
}
