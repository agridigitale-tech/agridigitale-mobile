// Mini graphe étincelle (sparkline) pour afficher la tendance des prix agricoles.
// - Rouge pour hausse (monté)
// - Vert pour baisse
// - Gris pour stable
import 'package:flutter/material.dart';
import '../data/marches_data.dart';

class MiniGrapheTendance extends StatelessWidget {
  final TendancePrix tendance;
  final List<int>? points;
  final Color couleur;
  final double width;
  final double height;

  const MiniGrapheTendance({
    super.key,
    required this.tendance,
    required this.couleur,
    this.points,
    this.width = 52.0,
    this.height = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        size: Size(width, height),
        painter: _SparklinePainter(
          tendance: tendance,
          points: points,
          couleur: couleur,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final TendancePrix tendance;
  final List<int>? points;
  final Color couleur;

  _SparklinePainter({
    required this.tendance,
    required this.points,
    required this.couleur,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    // Calcul ou génération des 5 points normalisés (0.0 en haut, 1.0 en bas)
    List<double> normalized;
    if (points != null && points!.length >= 2) {
      final minVal = points!.reduce((a, b) => a < b ? a : b).toDouble();
      final maxVal = points!.reduce((a, b) => a > b ? a : b).toDouble();
      final diff = maxVal - minVal;

      if (diff == 0) {
        normalized = List.filled(points!.length, 0.5);
      } else {
        // En coordonnées canvas : 0.0 est le haut (prix max), 1.0 est le bas (prix min)
        normalized = points!
            .map((p) => 1.0 - ((p - minVal) / diff).clamp(0.0, 1.0))
            .toList();
      }
    } else {
      switch (tendance) {
        case TendancePrix.hausse:
          // Part du bas (0.85) et monte vers le haut (0.15)
          normalized = const [0.85, 0.70, 0.75, 0.35, 0.15];
          break;
        case TendancePrix.baisse:
          // Part du haut (0.15) et descend vers le bas (0.85)
          normalized = const [0.15, 0.30, 0.25, 0.65, 0.85];
          break;
        case TendancePrix.stable:
          normalized = const [0.50, 0.45, 0.55, 0.48, 0.50];
          break;
      }
    }

    final n = normalized.length;
    final stepX = w / (n - 1);
    final offsets = <Offset>[];

    for (int i = 0; i < n; i++) {
      final x = i * stepX;
      // Marge de 2px en haut et bas pour ne pas tronquer le trait
      final y = 2.0 + (normalized[i] * (h - 4.0));
      offsets.add(Offset(x, y));
    }

    // Construction du chemin courbe lisse (Bézier cubique)
    final path = Path();
    path.moveTo(offsets[0].dx, offsets[0].dy);

    for (int i = 0; i < n - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // 1. Dégradé de remplissage sous la courbe
    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          couleur.withValues(alpha: 0.25),
          couleur.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 2. Trait de la courbe
    final strokePaint = Paint()
      ..color = couleur
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // 3. Point lumineux final (dernière valeur)
    final lastPoint = offsets.last;
    canvas.drawCircle(
      lastPoint,
      3.2,
      Paint()..color = couleur.withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      lastPoint,
      2.0,
      Paint()..color = couleur,
    );
    canvas.drawCircle(
      lastPoint,
      0.9,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.tendance != tendance ||
        oldDelegate.couleur != couleur ||
        oldDelegate.points != points;
  }
}
