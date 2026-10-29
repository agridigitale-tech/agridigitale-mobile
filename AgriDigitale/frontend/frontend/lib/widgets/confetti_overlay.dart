// Effet de confettis léger et festif (purement Flutter, 0 dépendance externe).
import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  const ConfettiOverlay({super.key, required this.child});

  static ConfettiOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<ConfettiOverlayState>();
  }

  @override
  State<ConfettiOverlay> createState() => ConfettiOverlayState();
}

class _Particule {
  double x;
  double y;
  double vx;
  double vy;
  double taille;
  Color couleur;
  double rotation;
  double vRotation;

  _Particule({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.taille,
    required this.couleur,
    required this.rotation,
    required this.vRotation,
  });
}

class ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_Particule> _particules = [];
  final Random _rng = Random();

  static const List<Color> _couleurs = [
    Color(0xFF3CA35A), // Vert AgriDigitale
    Color(0xFF4ECB73), // Vert clair
    Color(0xFFFFC107), // Or / Ambre
    Color(0xFFFF9800), // Orange
    Color(0xFF29B6F6), // Bleu ciel
    Color(0xFFE91E63), // Rose festif
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addListener(() {
        for (final p in _particules) {
          p.x += p.vx;
          p.y += p.vy;
          p.vy += 0.28; // Gravité
          p.rotation += p.vRotation;
        }
        setState(() {});
      });
  }

  /// Déclenche l'explosion de confettis
  void exploser() {
    _particules.clear();
    final width = MediaQuery.of(context).size.width;
    final centerX = width / 2;
    const startY = 120.0;

    for (int i = 0; i < 65; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final vitesse = _rng.nextDouble() * 8.0 + 3.0;
      _particules.add(_Particule(
        x: centerX + (_rng.nextDouble() - 0.5) * 60,
        y: startY + (_rng.nextDouble() - 0.5) * 30,
        vx: cos(angle) * vitesse,
        vy: sin(angle) * vitesse - 5.0, // Impulsion vers le haut
        taille: _rng.nextDouble() * 7.0 + 5.0,
        couleur: _couleurs[_rng.nextInt(_couleurs.length)],
        rotation: _rng.nextDouble() * pi,
        vRotation: (_rng.nextDouble() - 0.5) * 0.25,
      ));
    }

    _ctrl.forward(from: 0.0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_ctrl.isAnimating)
          IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: _ConfettiPainter(
                particules: _particules,
                opacite: (1.0 - _ctrl.value).clamp(0.0, 1.0),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particule> particules;
  final double opacite;

  _ConfettiPainter({required this.particules, required this.opacite});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particules) {
      final paint = Paint()
        ..color = p.couleur.withValues(alpha: opacite)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.taille, height: p.taille * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
