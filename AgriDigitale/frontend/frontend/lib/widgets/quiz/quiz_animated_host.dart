// Widget d'avatar animé interactif pour le Quiz Jungle Adventure.
// Représente l'animatrice avec le livre de questions (Colorful Quiz Host).
// Fonctionnalités :
// - Animation réaliste des yeux (clignotement naturel régulier)
// - Animation synchronisée de la bouche lors de la lecture (lip-sync)
// - Synthèse vocale automatique (TTS en français) pour lire les questions
// - Bouton interactif pour relancer la lecture ou couper le son
// - Micro-animations de respiration et hochement de tête chaleureux

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../services/quiz_sound_service.dart';

class QuizAnimatedHost extends StatefulWidget {
  final String texteQuestion;
  final bool lectureAutomatique;
  final double largeur;
  final double hauteur;
  final VoidCallback? onTap;

  const QuizAnimatedHost({
    super.key,
    required this.texteQuestion,
    this.lectureAutomatique = true,
    this.largeur = 95,
    this.hauteur = 125,
    this.onTap,
  });

  @override
  State<QuizAnimatedHost> createState() => QuizAnimatedHostState();
}

class QuizAnimatedHostState extends State<QuizAnimatedHost> with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();

  late AnimationController _respirationController;
  late Animation<double> _respirationAnimation;

  Timer? _blinkTimer;
  Timer? _mouthTimer;
  Timer? _safetyStopTimer;

  bool _isSpeaking = false;
  bool _isBlinking = false;
  bool _mouthOpen = false;

  @override
  void initState() {
    super.initState();
    QuizSoundService().addListener(_onSettingsChanged);

    _respirationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _respirationAnimation = Tween<double>(begin: 0.0, end: -3.0).animate(
      CurvedAnimation(parent: _respirationController, curve: Curves.easeInOut),
    );

    _initTts();
    _demarrerClignotementYeux();
  }

  void _onSettingsChanged() {
    if (!QuizSoundService().voiceEnabled && _isSpeaking) {
      _arreterLecture();
    }
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant QuizAnimatedHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.texteQuestion != widget.texteQuestion) {
      if (widget.lectureAutomatique && QuizSoundService().voiceEnabled) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) lireQuestion();
        });
      }
    }
  }

  @override
  void dispose() {
    QuizSoundService().removeListener(_onSettingsChanged);
    _blinkTimer?.cancel();
    _mouthTimer?.cancel();
    _safetyStopTimer?.cancel();
    _respirationController.dispose();
    _arreterLecture();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.05); // Voix féminine chaleureuse et dynamique

      _tts.setStartHandler(() {
        if (mounted) {
          setState(() => _isSpeaking = true);
          _demarrerAnimationBouche();
        }
      });

      _tts.setCompletionHandler(() {
        if (mounted) {
          _arreterLecture();
        }
      });

      _tts.setCancelHandler(() {
        if (mounted) {
          _arreterLecture();
        }
      });

      _tts.setErrorHandler((_) {
        if (mounted) {
          _arreterLecture();
        }
      });

      if (widget.lectureAutomatique && widget.texteQuestion.isNotEmpty && QuizSoundService().voiceEnabled) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) lireQuestion();
        });
      }
    } catch (_) {}
  }

  void _demarrerClignotementYeux() {
    _blinkTimer?.cancel();
    // Clignotement naturel visible toutes les 2.8 secondes
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 2800), (timer) {
      if (!mounted) return;
      setState(() => _isBlinking = true);
      Timer(const Duration(milliseconds: 220), () {
        if (mounted) setState(() => _isBlinking = false);
      });
    });
  }

  void _demarrerAnimationBouche() {
    _mouthTimer?.cancel();
    // Cycle de mouvement de lèvres au rythme de la parole (~160ms)
    _mouthTimer = Timer.periodic(const Duration(milliseconds: 160), (timer) {
      if (!mounted || !_isSpeaking) {
        timer.cancel();
        return;
      }
      setState(() => _mouthOpen = !_mouthOpen);
    });
  }

  Future<void> lireQuestion() async {
    if (!QuizSoundService().voiceEnabled) return;
    if (widget.texteQuestion.isEmpty) return;

    // Déclenche TOUJOURS l'animation visuelle de parole (lip-sync de la bouche)
    _safetyStopTimer?.cancel();
    if (mounted) {
      setState(() => _isSpeaking = true);
      _demarrerAnimationBouche();
    }

    // Durée estimée de lecture pour garantir l'animation même si le callback TTS tarde ou est silencieux
    final nbMots = widget.texteQuestion.split(' ').length;
    final dureeEstimeeMs = (nbMots * 280).clamp(2800, 7500);
    _safetyStopTimer = Timer(Duration(milliseconds: dureeEstimeeMs), () {
      if (mounted && _isSpeaking) {
        _arreterLecture();
      }
    });

    try {
      await _tts.stop();
      // Nettoie le texte des éventuelles balises pour une prononciation claire
      final textePropre = widget.texteQuestion
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (textePropre.isNotEmpty) {
        await _tts.speak(textePropre);
      }
    } catch (_) {}
  }

  Future<void> _arreterLecture() async {
    _safetyStopTimer?.cancel();
    _mouthTimer?.cancel();
    try {
      await _tts.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _mouthOpen = false;
      });
    }
  }

  void toggleLecture() {
    if (_isSpeaking) {
      _arreterLecture();
    } else {
      lireQuestion();
    }
  }

  String _selectionnerImageCadre() {
    if (_isBlinking) {
      return _isSpeaking && _mouthOpen
          ? 'assets/images/quiz_host_talk_blink.png'
          : 'assets/images/quiz_host_blink.png';
    }

    if (_isSpeaking && _mouthOpen) {
      return 'assets/images/quiz_host_talk.png';
    }

    return 'assets/images/quiz_host_idle.png';
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _selectionnerImageCadre();

    return GestureDetector(
      onTap: () {
        widget.onTap?.call();
        toggleLecture();
      },
      child: AnimatedBuilder(
        animation: _respirationAnimation,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _respirationAnimation.value),
          child: child,
        ),
        child: SizedBox(
          width: widget.largeur,
          height: widget.hauteur,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Halo lumineux d'aura / lecture active
              if (_isSpeaking)
                Positioned(
                  top: 8,
                  child: Container(
                    width: widget.largeur * 0.72,
                    height: widget.largeur * 0.72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.45),
                          blurRadius: 18,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

              // Image Avatar haute définition aux yeux et bouche animés
              Image.asset(
                imagePath,
                width: widget.largeur,
                height: widget.hauteur,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/quiz_host_avatar.png',
                  width: widget.largeur,
                  height: widget.hauteur,
                  fit: BoxFit.contain,
                ),
              ),

              // Badge indicateur vocal dynamique (onde sonore animée)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: _isSpeaking
                        ? const Color(0xFFFF8F00)
                        : (QuizSoundService().voiceEnabled ? const Color(0xCC000000) : const Color(0x99D32F2F)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isSpeaking ? const Color(0xFFFFD54F) : Colors.white70,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isSpeaking
                            ? const Color(0xFFFF8F00).withValues(alpha: 0.6)
                            : Colors.black45,
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isSpeaking
                        ? Icons.volume_up_rounded
                        : (QuizSoundService().voiceEnabled
                            ? Icons.record_voice_over_rounded
                            : Icons.volume_off_rounded),
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
