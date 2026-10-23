// Primitives d'animation réutilisables pour une UI "premium" cohérente :
//  - FadeSlideIn : entrée en fondu + glissement, avec délai (effet "staggered").
//  - ShimmerBox : squelette de chargement animé (effet shimmer).
//  - PressScale : retour tactile subtil (léger zoom) au tap.
import 'package:flutter/material.dart';
import '../core/design/app_colors.dart';

/// Entrée animée : fondu + glissement vertical, déclenchée au montage du widget.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 480),
    this.offsetY = 24,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacite;
  late final Animation<Offset> _glissement;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    final courbe = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _opacite = Tween<double>(begin: 0, end: 1).animate(courbe);
    _glissement = Tween<Offset>(
      begin: Offset(0, widget.offsetY / 100),
      end: Offset.zero,
    ).animate(courbe);
    _demarrer();
  }

  Future<void> _demarrer() async {
    if (widget.delay > Duration.zero) {
      await Future.delayed(widget.delay);
    }
    if (mounted) _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacite,
      child: SlideTransition(position: _glissement, child: widget.child),
    );
  }
}

/// Squelette de chargement avec balayage lumineux (shimmer).
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.radius = 12,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
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
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 2, 0),
              end: Alignment(-0.4 + t * 2, 0),
              colors: const [
                Color(0xFFEDEDED),
                Color(0xFFF7F7F7),
                Color(0xFFEDEDED),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Enveloppe un widget cliquable d'un léger effet d'échelle au tap.
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PressScale({super.key, required this.child, this.onTap});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _presse = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _presse = true),
      onTapUp: (_) => setState(() => _presse = false),
      onTapCancel: () => setState(() => _presse = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _presse ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Barre d'accent décorative utilisée devant les titres de section.
class AccentBar extends StatelessWidget {
  final double height;
  final Color couleur;

  const AccentBar({super.key, this.height = 18, this.couleur = AppColors.vertPrimaire});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: couleur,
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}
