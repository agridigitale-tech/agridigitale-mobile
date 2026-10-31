// Service de gestion du jeu Quiz Agricole.
// 100% autonome, fonctionne entièrement hors-ligne grâce à SharedPreferences.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/quiz_data.dart';
import '../models/quiz_grade.dart';

class BadgeQuiz {
  final String id;
  final String nom;
  final String description;
  final String icone;

  const BadgeQuiz({
    required this.id,
    required this.nom,
    required this.description,
    required this.icone,
  });
}

class QuizService {
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal();

  static const _kPrefix = 'quiz_agri_';
  static const _kKeyNiveauMax = '${_kPrefix}niveau_max';
  static const _kKeyEtoiles = '${_kPrefix}etoiles';
  static const _kKeyGrains = '${_kPrefix}grains';
  static const _kKeyStreak = '${_kPrefix}streak';
  static const _kKeyDernierJour = '${_kPrefix}dernier_jour';
  static const _kKeyQuizJourFait = '${_kPrefix}quiz_jour_fait';
  static const _kKeyBadges = '${_kPrefix}badges';

  // Badges disponibles dans le jeu
  static const List<BadgeQuiz> tousLesBadges = [
    BadgeQuiz(
      id: 'premier_pas',
      nom: 'Première Graine',
      description: 'Terminer votre toute première session de quiz',
      icone: '🌱',
    ),
    BadgeQuiz(
      id: 'streak_3',
      nom: 'Flamme Verte',
      description: 'Jouer 3 jours consécutifs au Quiz du Jour',
      icone: '🔥',
    ),
    BadgeQuiz(
      id: 'streak_7',
      nom: 'Agriculteur Passionné',
      description: 'Maintenir une série de 7 jours consécutifs',
      icone: '⚡',
    ),
    BadgeQuiz(
      id: 'maitre_sol',
      nom: 'Gardien du Sol',
      description: 'Obtenir 3 étoiles sur tous les niveaux du Monde 1',
      icone: '🌍',
    ),
    BadgeQuiz(
      id: 'expert_maraichage',
      nom: 'Maître Maraîcher',
      description: 'Compléter avec succès le Monde 2 (Tomates, Piments, Oignons)',
      icone: '🍅',
    ),
    BadgeQuiz(
      id: 'pro_cereales',
      nom: 'Seigneur des Moissons',
      description: 'Compléter avec succès le Monde 3 (Grandes Cultures)',
      icone: '🌽',
    ),
    BadgeQuiz(
      id: 'champion_bio',
      nom: 'Protecteur Écolo',
      description: 'Compléter le Monde 4 (Défense Naturelle & Neem)',
      icone: '🌿',
    ),
    BadgeQuiz(
      id: 'grand_agronome',
      nom: 'Grand Agronome',
      description: 'Accumuler plus de 35 étoiles sur l\'ensemble des mondes',
      icone: '🏆',
    ),
  ];

  /// Notifier global pour rafraîchir l'interface (carte d'accueil, étoiles, grains)
  final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  /// Récupère le niveau maximal débloqué (1 par défaut)
  Future<int> getNiveauMaxDebloque() async {
    final sp = await _prefs;
    return sp.getInt(_kKeyNiveauMax) ?? 1;
  }

  /// Récupère la carte des étoiles obtenues par niveau (ex: {1: 3, 2: 2})
  Future<Map<int, int>> getEtoilesParNiveau() async {
    final sp = await _prefs;
    final raw = sp.getString(_kKeyEtoiles);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(int.parse(k), v as int));
    } catch (_) {
      return {};
    }
  }

  /// Nombre d'étoiles pour un niveau spécifique (0 à 3)
  Future<int> getEtoilesPourNiveau(int niveauId) async {
    final map = await getEtoilesParNiveau();
    return map[niveauId] ?? 0;
  }

  /// Total d'étoiles accumulées
  Future<int> getTotalEtoiles() async {
    final map = await getEtoilesParNiveau();
    return map.values.fold<int>(0, (sum, val) => sum + val);
  }

  /// Récupère le total de "Grains" (points de jeu)
  Future<int> getTotalGrains() async {
    final sp = await _prefs;
    return sp.getInt(_kKeyGrains) ?? 0;
  }

  /// Récupère la flamme de série journalière (Streak 🔥)
  Future<int> getStreakJours() async {
    final sp = await _prefs;
    await _verifierValiditeStreak();
    return sp.getInt(_kKeyStreak) ?? 0;
  }

  /// Vérifie si le quiz du jour a déjà été joué aujourd'hui
  Future<bool> estQuizDuJourFaitAujourdhui() async {
    final sp = await _prefs;
    final aujourdhui = _dateAujourdhuiString();
    final dernierJourFait = sp.getString(_kKeyQuizJourFait);
    return dernierJourFait == aujourdhui;
  }

  /// Récupère la liste des IDs des badges débloqués
  Future<List<String>> getBadgesDebloques() async {
    final sp = await _prefs;
    return sp.getStringList(_kKeyBadges) ?? [];
  }

  /// Récupère le grade actif actuel du joueur (de Novice à Légende)
  Future<QuizGrade> getGradeActuel() async {
    final max = await getNiveauMaxDebloque();
    return QuizGrade.getGradePourNiveau(max);
  }

  /// Enregistre le résultat d'un niveau du mode aventure
  /// Retourne : (etoilesObtenues, nouveauNiveauDebloque, grainsGagnes, nouveauxBadges, nouveauGrade)
  Future<({int etoiles, bool niveauDebloque, int grainsGagnes, List<BadgeQuiz> nouveauxBadges, QuizGrade? nouveauGrade})> enregistrerResultatNiveau({
    required int niveauId,
    required int bonnesReponses,
  }) async {
    final sp = await _prefs;
    final niveauMaxActuel = sp.getInt(_kKeyNiveauMax) ?? 1;

    // Calcul des étoiles pour cette session
    int etoilesSession = 0;
    if (bonnesReponses == 3) {
      etoilesSession = 3;
    } else if (bonnesReponses == 2) {
      etoilesSession = 2;
    } else if (bonnesReponses == 1) {
      etoilesSession = 1;
    }

    // Sauvegarde des meilleures étoiles
    final etoilesMap = await getEtoilesParNiveau();
    final etoilesPrecedentes = etoilesMap[niveauId] ?? 0;
    if (etoilesSession > etoilesPrecedentes) {
      etoilesMap[niveauId] = etoilesSession;
      final encoded = jsonEncode(etoilesMap.map((k, v) => MapEntry(k.toString(), v)));
      await sp.setString(_kKeyEtoiles, encoded);
    }

    // Déblocage du niveau suivant si au moins 2 étoiles et c'est le niveau max actuel
    bool niveauDebloque = false;
    QuizGrade? nouveauGrade;
    if (etoilesSession >= 2 && niveauId == niveauMaxActuel && niveauId < QuizData.totalNiveaux) {
      final nouveauNiveau = niveauId + 1;
      await sp.setInt(_kKeyNiveauMax, nouveauNiveau);
      niveauDebloque = true;

      // Détection de promotion de grade
      final ancienGrade = QuizGrade.getGradePourNiveau(niveauMaxActuel);
      final gradeApres = QuizGrade.getGradePourNiveau(nouveauNiveau);
      if (gradeApres.titre != ancienGrade.titre) {
        nouveauGrade = gradeApres;
      }
    }

    // Calcul des grains
    final grainsGagnes = (bonnesReponses * 10) + (etoilesSession == 3 ? 15 : (etoilesSession == 2 ? 5 : 0));
    final grainsActuels = sp.getInt(_kKeyGrains) ?? 0;
    await sp.setInt(_kKeyGrains, grainsActuels + grainsGagnes);

    // Mise à jour du streak quotidien
    await _mettreAJourStreak();

    // Vérification des badges
    final nouveauxBadges = await _verifierEtAttribuerBadges(etoilesMap);

    changeNotifier.value++;
    return (
      etoiles: etoilesSession,
      niveauDebloque: niveauDebloque,
      grainsGagnes: grainsGagnes,
      nouveauxBadges: nouveauxBadges,
      nouveauGrade: nouveauGrade,
    );
  }

  /// Enregistre le résultat du Quiz du Jour
  Future<({int grainsGagnes, int streakActuel, List<BadgeQuiz> nouveauxBadges})> enregistrerResultatQuizDuJour({
    required int bonnesReponses,
  }) async {
    final sp = await _prefs;
    final aujourdhui = _dateAujourdhuiString();
    await sp.setString(_kKeyQuizJourFait, aujourdhui);

    final grainsGagnes = (bonnesReponses * 15) + (bonnesReponses == 3 ? 20 : 0);
    final grainsActuels = sp.getInt(_kKeyGrains) ?? 0;
    await sp.setInt(_kKeyGrains, grainsActuels + grainsGagnes);

    final streak = await _mettreAJourStreak();
    final etoilesMap = await getEtoilesParNiveau();
    final nouveauxBadges = await _verifierEtAttribuerBadges(etoilesMap);

    changeNotifier.value++;
    return (
      grainsGagnes: grainsGagnes,
      streakActuel: streak,
      nouveauxBadges: nouveauxBadges,
    );
  }

  // ── Méthodes privées d'aide ──

  String _dateAujourdhuiString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _dateHierString() {
    final hier = DateTime.now().subtract(const Duration(days: 1));
    return '${hier.year}-${hier.month.toString().padLeft(2, '0')}-${hier.day.toString().padLeft(2, '0')}';
  }

  Future<void> _verifierValiditeStreak() async {
    final sp = await _prefs;
    final dernierJour = sp.getString(_kKeyDernierJour);
    if (dernierJour == null) return;

    final aujourdhui = _dateAujourdhuiString();
    final hier = _dateHierString();

    // Si le dernier jour joué est plus ancien qu'hier, le streak est brisé
    if (dernierJour != aujourdhui && dernierJour != hier) {
      await sp.setInt(_kKeyStreak, 0);
    }
  }

  Future<int> _mettreAJourStreak() async {
    final sp = await _prefs;
    final dernierJour = sp.getString(_kKeyDernierJour);
    final aujourdhui = _dateAujourdhuiString();
    final hier = _dateHierString();

    int streak = sp.getInt(_kKeyStreak) ?? 0;

    if (dernierJour == aujourdhui) {
      // Déjà incrémenté aujourd'hui
      return streak;
    }

    if (dernierJour == hier) {
      // Jour consécutif parfait !
      streak += 1;
    } else {
      // Première fois ou série brisée
      streak = 1;
    }

    await sp.setInt(_kKeyStreak, streak);
    await sp.setString(_kKeyDernierJour, aujourdhui);
    return streak;
  }

  Future<List<BadgeQuiz>> _verifierEtAttribuerBadges(Map<int, int> etoilesMap) async {
    final sp = await _prefs;
    final badgesActuels = sp.getStringList(_kKeyBadges) ?? [];
    final nouveaux = <BadgeQuiz>[];
    final streak = sp.getInt(_kKeyStreak) ?? 0;
    final totalEtoiles = etoilesMap.values.fold(0, (sum, val) => sum + val);

    void tenterAjout(BadgeQuiz badge, bool condition) {
      if (condition && !badgesActuels.contains(badge.id)) {
        badgesActuels.add(badge.id);
        nouveaux.add(badge);
      }
    }

    // 1. Premier pas : au moins un niveau ou quiz joué
    tenterAjout(tousLesBadges[0], etoilesMap.isNotEmpty || sp.getString(_kKeyDernierJour) != null);

    // 2. Streak 3 jours
    tenterAjout(tousLesBadges[1], streak >= 3);

    // 3. Streak 7 jours
    tenterAjout(tousLesBadges[2], streak >= 7);

    // 4. Maître du sol : Monde 1 (niveaux 1, 2, 3) tous à 3 étoiles
    final monde1Complet = (etoilesMap[1] == 3 && etoilesMap[2] == 3 && etoilesMap[3] == 3);
    tenterAjout(tousLesBadges[3], monde1Complet);

    // 5. Expert Maraîchage : Monde 2 (niveaux 4, 5, 6) complétés (au moins 2 étoiles chacun)
    final monde2Complet = ((etoilesMap[4] ?? 0) >= 2 && (etoilesMap[5] ?? 0) >= 2 && (etoilesMap[6] ?? 0) >= 2);
    tenterAjout(tousLesBadges[4], monde2Complet);

    // 6. Pro Céréales : Monde 3 (niveaux 7, 8, 9) complétés
    final monde3Complet = ((etoilesMap[7] ?? 0) >= 2 && (etoilesMap[8] ?? 0) >= 2 && (etoilesMap[9] ?? 0) >= 2);
    tenterAjout(tousLesBadges[5], monde3Complet);

    // 7. Champion Bio : Monde 4 (niveaux 10, 11, 12) complétés
    final monde4Complet = ((etoilesMap[10] ?? 0) >= 2 && (etoilesMap[11] ?? 0) >= 2 && (etoilesMap[12] ?? 0) >= 2);
    tenterAjout(tousLesBadges[6], monde4Complet);

    // 8. Grand Agronome : 35 étoiles ou plus
    tenterAjout(tousLesBadges[7], totalEtoiles >= 35);

    if (nouveaux.isNotEmpty) {
      await sp.setStringList(_kKeyBadges, badgesActuels);
    }

    return nouveaux;
  }
}
