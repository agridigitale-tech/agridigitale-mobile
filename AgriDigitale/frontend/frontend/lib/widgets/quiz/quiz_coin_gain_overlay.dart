// Animation spectaculaire de gain de pièces (Coin Gain Flying Animation).
// - Jet de pièces 3D dorées depuis la réponse validée jusqu'au compteur de pièces
// - Trajectoires paraboliques fluides avec rotation (spin 3D) des pièces
// - Badge flottant animé "+10 PIÈCES" avec halo doré éclatant
// - Effets sonores de pièces (chime) et micro-vibrations synchronisés

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/quiz_sound_service.dart';

class QuizCoinGainOverlay extends StatefulWidget {
  final Widget child;

  const QuizCoinGainOverlay({
    super.key,
    required this.child,
  });

  static QuizCoinGainOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<QuizCoinGainOverlayState>();
  }

  /// Widget visuel d'une pièce d'or 3D éclatante (réutilisable partout dans le Quiz)
  static Widget build3DCoin({double taille = 28}) {
    return QuizCoinGainOverlayState.build3DCoin(taille: taille);
  }

  @override
  State<QuizCoinGainOverlay> createState() => QuizCoinGainOverlayState();
}

class _FlyingCoin {
  final double delay;
  final Offset controlPoint;
  double spinAngle = 0.0;
  bool aAtteintCible = false;

  _FlyingCoin({
    required this.delay,
    required this.controlPoint,
  });
}

class QuizCoinGainOverlayState extends State<QuizCoinGainOverlay> with SingleTickerProviderStateMixin {
  final _soundService = QuizSoundService();

  late AnimationController _animController;
  late Animation<double> _progress;

  Offset _startOffset = Offset.zero;
  Offset _targetOffset = Offset.zero;
  int _montant = 10;
  List<_FlyingCoin> _coins = [];
  bool _enCours = false;
  VoidCallback? _onComplete;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _progress = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );

    _animController.addListener(_onAnimationTick);
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _enCours = false;
            _coins.clear();
          });
          _onComplete?.call();
        }
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onAnimationTick() {
    final tGlobal = _animController.value;
    for (int i = 0; i < _coins.length; i++) {
      final coin = _coins[i];
      final coinEnd = coin.delay + 0.45;
      if (tGlobal >= coinEnd && !coin.aAtteintCible) {
        coin.aAtteintCible = true;
        _soundService.playCoin();
        _soundService.vibrateLight();
      }
    }
  }

  /// Déclenche l'animation de jet de pièces depuis [depart] vers [cible]
  void animerGain({
    required Offset depart,
    required Offset cible,
    int montant = 10,
    int nombrePieces = 7,
    VoidCallback? onComplete,
  }) {
    if (!mounted) return;

    final rand = math.Random();
    final List<_FlyingCoin> newCoins = [];

    for (int i = 0; i < nombrePieces; i++) {
      final delay = i * 0.07;
      // Point de contrôle Bezier avec dispersion aléatoire vers l'extérieur
      final dxMid = (depart.dx + cible.dx) / 2 + (rand.nextDouble() - 0.5) * 160;
      final dyMid = math.min(depart.dy, cible.dy) - (60 + rand.nextDouble() * 90);

      newCoins.add(_FlyingCoin(
        delay: delay,
        controlPoint: Offset(dxMid, dyMid),
      ));
    }

    setState(() {
      _startOffset = depart;
      _targetOffset = cible;
      _montant = montant;
      _coins = newCoins;
      _enCours = true;
      _onComplete = onComplete;
    });

    _animController.forward(from: 0.0);
  }

  Offset _evaluerBezier(Offset p0, Offset p1, Offset p2, double t) {
    final clamped = t.clamp(0.0, 1.0);
    final u = 1.0 - clamped;
    final x = u * u * p0.dx + 2 * u * clamped * p1.dx + clamped * clamped * p2.dx;
    final y = u * u * p0.dy + 2 * u * clamped * p1.dy + clamped * clamped * p2.dy;
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // ── Rendu des pièces animées ──
        if (_enCours)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _progress,
                builder: (context, _) {
                  final tGlobal = _animController.value;

                  return Stack(
                    children: [
                      // Badge flottant "+10 PIÈCES"
                      _buildFloatingPill(tGlobal),

                      // Pièces volantes
                      ..._coins.map((coin) {
                        final duration = 0.45;
                        if (tGlobal < coin.delay) return const SizedBox.shrink();
                        if (tGlobal > coin.delay + duration + 0.08) return const SizedBox.shrink();

                        final tCoin = ((tGlobal - coin.delay) / duration).clamp(0.0, 1.0);
                        final pos = _evaluerBezier(_startOffset, coin.controlPoint, _targetOffset, tCoin);

                        // Échelle (jaillit grand puis rétrécit dans le compteur)
                        final scale = tCoin < 0.2
                            ? (tCoin / 0.2) * 1.25
                            : 1.25 - (tCoin - 0.2) * 0.45;

                        // Rotation 3D (flip horizontal)
                        final spin = math.cos(tCoin * math.pi * 5);

                        return Positioned(
                          left: pos.dx - 14,
                          top: pos.dy - 14,
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.diagonal3Values(
                              scale * spin.abs().clamp(0.25, 1.0),
                              scale,
                              1.0,
                            ),
                            child: build3DCoin(taille: 28),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  /// Badge flottant "+10 PIÈCES" avec éclat doré
  Widget _buildFloatingPill(double t) {
    final progressPill = (t / 0.65).clamp(0.0, 1.0);
    final opacity = progressPill < 0.15
        ? (progressPill / 0.15)
        : (1.0 - (progressPill - 0.15) / 0.85).clamp(0.0, 1.0);

    final yOffset = _startOffset.dy - (40 + progressPill * 70);
    final scale = 0.8 + 0.4 * math.sin(progressPill * math.pi);

    return Positioned(
      left: _startOffset.dx - 75,
      top: yOffset,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFEA00), Color(0xFFFF9100), Color(0xFFFF6D00)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9100).withValues(alpha: 0.8),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
                const BoxShadow(
                  color: Colors.black45,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                build3DCoin(taille: 20),
                const SizedBox(width: 6),
                Text(
                  '+$_montant PIÈCES',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                    shadows: const [
                      Shadow(color: Color(0xFFBF360C), offset: Offset(0, 1.5), blurRadius: 3),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget visuel d'une pièce d'or 3D éclatante
  static Widget build3DCoin({double taille = 28}) {
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.4),
          colors: [
            Color(0xFFFFFDE7),
            Color(0xFFFFEE58),
            Color(0xFFFFB300),
            Color(0xFFE65100),
          ],
          stops: [0.0, 0.45, 0.85, 1.0],
        ),
        border: Border.all(color: const Color(0xFFFFF9C4), width: taille * 0.06),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.8),
            blurRadius: taille * 0.3,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Colors.black38,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '\$',
          style: TextStyle(
            color: const Color(0xFF5D3A1A),
            fontWeight: FontWeight.w900,
            fontSize: taille * 0.48,
            shadows: const [
              Shadow(color: Color(0xFFFFF9C4), offset: Offset(0, 0.5), blurRadius: 1),
            ],
          ),
        ),
      ),
    );
  }
}
