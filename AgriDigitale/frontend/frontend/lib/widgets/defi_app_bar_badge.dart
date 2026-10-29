// Widget animé positionné dans l'AppBar au niveau de la cloche de notification.
// "Fait signe" aux utilisateurs via une pulsation douce (respiration + oscillation)
// pour les inciter à cliquer et entrer sur l'écran du Défi Agricole (Quiz & Niveaux).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/quiz_service.dart';
import '../screens/quiz/quiz_niveaux_screen.dart';

class DefiAppBarBadge extends StatefulWidget {
  const DefiAppBarBadge({super.key});

  @override
  State<DefiAppBarBadge> createState() => _DefiAppBarBadgeState();
}

class _DefiAppBarBadgeState extends State<DefiAppBarBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _rotationAnim;

  final QuizService _quizService = QuizService();
  int _streak = 0;

  @override
  void initState() {
    super.initState();

    // Animation continue douce : respiration (scale) + léger balancement (rotation)
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.94, end: 1.08).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );

    _rotationAnim = Tween<double>(begin: -0.06, end: 0.06).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOutSine),
    );

    _chargerStreak();
    _quizService.changeNotifier.addListener(_chargerStreak);
  }

  Future<void> _chargerStreak() async {
    final s = await _quizService.getStreakJours();
    if (mounted) setState(() => _streak = s);
  }

  @override
  void dispose() {
    _quizService.changeNotifier.removeListener(_chargerStreak);
    _animCtrl.dispose();
    super.dispose();
  }

  void _ouvrirDefi() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuizNiveauxScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Transform.rotate(
            angle: _rotationAnim.value,
            child: child,
          ),
        );
      },
      child: Tooltip(
        message: 'Défi Agricole (1 min) : Quiz, niveaux & grains',
        child: InkWell(
          onTap: _ouvrirDefi,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5722).withValues(alpha: 0.45),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 3),
                Text(
                  _streak > 0 ? '$_streak j' : 'DÉFI',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 4),
                // Petit point vert clignotant
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF76FF03),
                    shape: BoxShape.circle,
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
