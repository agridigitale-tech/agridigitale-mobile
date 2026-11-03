// Service audio et de réglages officiel pour le Quiz Jungle Adventure.
// - Persistance SharedPreferences (effets sonores, ambiance rivière & oiseaux, kalimba/marimba, lecture vocale, vibrations)
// - Gestion stricte du cycle de vie (WidgetsBindingObserver) : coupe net la musique dès la sortie de l'application
// - Suivi d'état d'écran (_estSurEcranJeu) : coupe la musique dès qu'on navigue vers d'autres écrans hors jeu
// - Gestion résiliente des lecteurs audio (recréation automatique si libérés)
// - Méthode stopAll() pour couper tous les sons
// - ChangeNotifier pour mise à jour instantanée des écrans et composants
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizSoundService extends ChangeNotifier with WidgetsBindingObserver {
  static final QuizSoundService _instance = QuizSoundService._internal();
  factory QuizSoundService() => _instance;
  QuizSoundService._internal() {
    WidgetsBinding.instance.addObserver(this);
    chargerReglages();
  }

  static const String _kKeyEffetsSonores = 'quiz_reglage_effets_sonores';
  static const String _kKeyLectureVocale = 'quiz_reglage_lecture_vocale';
  static const String _kKeyVibrations = 'quiz_reglage_vibrations';
  static const String _kKeyMusique = 'quiz_reglage_musique';
  static const String _kKeyTypeMusique = 'quiz_reglage_type_musique';

  AudioPlayer? _tickPlayer;
  AudioPlayer? _sfxPlayer;
  AudioPlayer? _bgmPlayer;

  bool _soundEnabled = true;
  bool _voiceEnabled = true;
  bool _hapticsEnabled = true;
  bool _musicEnabled = true;
  // Par défaut : rivière qui coule avec gazouillis d'oiseaux doux
  String _musicType = 'riviere'; // 'riviere', 'kalimba', 'marimba'
  bool _estSurEcranJeu = false;

  bool get soundEnabled => _soundEnabled;
  bool get voiceEnabled => _voiceEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get musicEnabled => _musicEnabled;
  String get musicType => _musicType;
  bool get estSurEcranJeu => _estSurEcranJeu;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      // L'utilisateur quitte l'application ou l'envoie en arrière-plan : coupure immédiate
      stopBgm();
    } else if (state == AppLifecycleState.resumed) {
      // Reprise uniquement si on est activement sur un écran de jeu
      if (_estSurEcranJeu && _musicEnabled) {
        playBgm();
      }
    }
  }

  /// Indique si l'utilisateur est actuellement sur un écran de jeu (Quiz, Niveaux, Accueil Jeu).
  /// Coupe instantanément la musique dès qu'on passe sur un autre écran (Home, Météo, etc.).
  void setEstSurEcranJeu(bool valeur) {
    _estSurEcranJeu = valeur;
    if (!valeur) {
      stopBgm();
    } else if (_musicEnabled) {
      playBgm();
    }
  }

  Future<void> chargerReglages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool(_kKeyEffetsSonores) ?? true;
      _voiceEnabled = prefs.getBool(_kKeyLectureVocale) ?? true;
      _hapticsEnabled = prefs.getBool(_kKeyVibrations) ?? true;
      _musicEnabled = prefs.getBool(_kKeyMusique) ?? true;
      _musicType = prefs.getString(_kKeyTypeMusique) ?? 'riviere';
      notifyListeners();
    } catch (_) {
      _soundEnabled = true;
      _voiceEnabled = true;
      _hapticsEnabled = true;
      _musicEnabled = true;
      _musicType = 'riviere';
    }
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    notifyListeners();
    if (!value) {
      stopAll();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kKeyEffetsSonores, value);
    } catch (_) {}
  }

  Future<void> setMusicEnabled(bool value) async {
    _musicEnabled = value;
    notifyListeners();
    if (value && _estSurEcranJeu) {
      await playBgm();
    } else {
      await stopBgm();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kKeyMusique, value);
    } catch (_) {}
  }

  Future<void> setMusicType(String type) async {
    _musicType = type;
    notifyListeners();
    if (_musicEnabled && _estSurEcranJeu) {
      await stopBgm();
      await playBgm();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kKeyTypeMusique, type);
    } catch (_) {}
  }

  Future<void> setVoiceEnabled(bool value) async {
    _voiceEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kKeyLectureVocale, value);
    } catch (_) {}
  }

  Future<void> setHapticsEnabled(bool value) async {
    _hapticsEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kKeyVibrations, value);
    } catch (_) {}
  }

  AudioPlayer _getTickPlayer() {
    _tickPlayer ??= AudioPlayer();
    return _tickPlayer!;
  }

  AudioPlayer _getSfxPlayer() {
    _sfxPlayer ??= AudioPlayer();
    return _sfxPlayer!;
  }

  AudioPlayer _getBgmPlayer() {
    _bgmPlayer ??= AudioPlayer();
    return _bgmPlayer!;
  }

  Future<void> init() async {
    await chargerReglages();
    try {
      await _getTickPlayer().setReleaseMode(ReleaseMode.stop);
      await _getSfxPlayer().setReleaseMode(ReleaseMode.stop);
      await _getBgmPlayer().setReleaseMode(ReleaseMode.loop);
    } catch (_) {}
  }

  /// Joue la boucle de relaxation (Bruit de rivière & oiseaux doux par défaut)
  Future<void> playBgm({String? assetPath}) async {
    if (!_musicEnabled) return;
    String path;
    if (assetPath != null) {
      path = assetPath;
    } else {
      switch (_musicType) {
        case 'kalimba':
          path = 'sounds/quiz_jungle_kalimba_loop.mp3';
          break;
        case 'marimba':
          path = 'sounds/quiz_jungle_marimba_loop.mp3';
          break;
        case 'riviere':
        default:
          path = 'sounds/quiz_jungle_river_birds_loop.mp3';
          break;
      }
    }

    try {
      final player = _getBgmPlayer();
      if (player.state == PlayerState.playing) {
        return; // Déjà en cours de lecture continue
      }
      await player.stop();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0.35); // Volume de fond doux et reposant
      await player.play(AssetSource(path));
    } catch (_) {
      try {
        _bgmPlayer = AudioPlayer();
        await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
        await _bgmPlayer!.setVolume(0.35);
        await _bgmPlayer!.play(AssetSource(path));
      } catch (_) {}
    }
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer?.stop();
    } catch (_) {}
  }

  Future<void> pauseBgm() async {
    try {
      await _bgmPlayer?.pause();
    } catch (_) {}
  }

  Future<void> resumeBgm() async {
    if (!_musicEnabled) return;
    try {
      await _bgmPlayer?.resume();
    } catch (_) {
      await playBgm();
    }
  }

  Future<void> playTick() async {
    if (!_soundEnabled) return;
    try {
      final player = _getTickPlayer();
      await player.stop();
      await player.play(AssetSource('sounds/quiz_clock_tick.wav'), volume: 0.5);
    } catch (_) {
      try {
        _tickPlayer = AudioPlayer();
        await _tickPlayer!.play(AssetSource('sounds/quiz_clock_tick.wav'), volume: 0.5);
      } catch (_) {}
    }
  }

  Future<void> playCorrect() async {
    if (!_soundEnabled) return;
    try {
      final player = _getSfxPlayer();
      await player.stop();
      await player.play(AssetSource('sounds/quiz_correct.wav'), volume: 0.9);
    } catch (_) {
      try {
        _sfxPlayer = AudioPlayer();
        await _sfxPlayer!.play(AssetSource('sounds/quiz_correct.wav'), volume: 0.9);
      } catch (_) {}
    }
  }

  Future<void> playWrong() async {
    if (!_soundEnabled) return;
    try {
      final player = _getSfxPlayer();
      await player.stop();
      await player.play(AssetSource('sounds/quiz_wrong.wav'), volume: 0.85);
    } catch (_) {
      try {
        _sfxPlayer = AudioPlayer();
        await _sfxPlayer!.play(AssetSource('sounds/quiz_wrong.wav'), volume: 0.85);
      } catch (_) {}
    }
  }

  Future<void> playCoin() async {
    if (!_soundEnabled) return;
    try {
      final player = _getSfxPlayer();
      await player.stop();
      await player.play(AssetSource('sounds/quiz_coin.wav'), volume: 0.85);
    } catch (_) {
      try {
        _sfxPlayer = AudioPlayer();
        await _sfxPlayer!.play(AssetSource('sounds/quiz_coin.wav'), volume: 0.85);
      } catch (_) {}
    }
  }

  Future<void> playVictory() async {
    if (!_soundEnabled) return;
    try {
      final player = _getSfxPlayer();
      await player.stop();
      await player.play(AssetSource('sounds/quiz_victory.wav'), volume: 0.9);
    } catch (_) {
      try {
        _sfxPlayer = AudioPlayer();
        await _sfxPlayer!.play(AssetSource('sounds/quiz_victory.wav'), volume: 0.9);
      } catch (_) {}
    }
  }

  /// Coupe immédiatement tous les sons en cours (sans détruire les lecteurs)
  void stopAll() {
    try {
      _tickPlayer?.stop();
      _sfxPlayer?.stop();
      _bgmPlayer?.stop();
    } catch (_) {}
  }

  /// Vibrations haptiques respectant le choix de l'utilisateur
  void vibrateLight() {
    if (_hapticsEnabled) {
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}
    }
  }

  void vibrateMedium() {
    if (_hapticsEnabled) {
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
    }
  }

  void vibrateHeavy() {
    if (_hapticsEnabled) {
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
    }
  }

  void vibrateError() {
    if (_hapticsEnabled) {
      try {
        HapticFeedback.vibrate();
      } catch (_) {}
    }
  }
}
