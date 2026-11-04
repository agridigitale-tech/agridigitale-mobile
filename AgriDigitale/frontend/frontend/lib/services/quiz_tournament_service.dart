// Service de gestion du Tournoi Virtuel Éphémère, du calcul de QI (IQ),
// de la ligue dynamique et du suivi des Victoires Quotidiennes (Daily Victories).
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JoueurTournoi {
  final int rang;
  final String nom;
  final String drapeau;
  final String avatar;
  final int niveauBadge;
  final int score;
  final int coeurs;
  final bool estJoueurActuel;
  final String statut;

  const JoueurTournoi({
    required this.rang,
    required this.nom,
    required this.drapeau,
    required this.avatar,
    required this.niveauBadge,
    required this.score,
    required this.coeurs,
    this.estJoueurActuel = false,
    this.statut = 'En jeu',
  });

  JoueurTournoi copyWith({
    int? rang,
    String? nom,
    String? drapeau,
    String? avatar,
    int? niveauBadge,
    int? score,
    int? coeurs,
    bool? estJoueurActuel,
    String? statut,
  }) {
    return JoueurTournoi(
      rang: rang ?? this.rang,
      nom: nom ?? this.nom,
      drapeau: drapeau ?? this.drapeau,
      avatar: avatar ?? this.avatar,
      niveauBadge: niveauBadge ?? this.niveauBadge,
      score: score ?? this.score,
      coeurs: coeurs ?? this.coeurs,
      estJoueurActuel: estJoueurActuel ?? this.estJoueurActuel,
      statut: statut ?? this.statut,
    );
  }
}

class QuizTournamentService {
  static final QuizTournamentService _instance = QuizTournamentService._internal();
  factory QuizTournamentService() => _instance;
  QuizTournamentService._internal();

  static const _kKeyIQ = 'quiz_tournament_iq';
  static const _kKeyLigue = 'quiz_tournament_ligue';
  static const _kKeyLigueExpire = 'quiz_tournament_ligue_expire';
  static const _kKeyBoosters = 'quiz_tournament_boosters';
  static const _kKeyDailyDays = 'quiz_tournament_daily_days';
  static const _kKeyPlayerScore = 'quiz_tournament_player_score';
  static const _kKeyPseudo = 'quiz_tournament_player_pseudo';

  final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  /// Récupère le pseudo choisi par le joueur (null s'il n'en a pas encore créé)
  Future<String?> getPseudoJoueur() async {
    final sp = await _prefs;
    return sp.getString(_kKeyPseudo);
  }

  /// Enregistre le pseudo du joueur
  Future<void> setPseudoJoueur(String pseudo) async {
    final sp = await _prefs;
    await sp.setString(_kKeyPseudo, pseudo.trim());
    changeNotifier.value++;
  }

  /// Récupère le score QI du joueur (par défaut 149.4)
  Future<double> getIQ() async {
    final sp = await _prefs;
    return sp.getDouble(_kKeyIQ) ?? 149.4;
  }

  /// Incrémente le QI suite à une bonne série ou victoire (effet gratifiant de l'ego)
  Future<double> ajouterIQ(double gain) async {
    final sp = await _prefs;
    final actuel = sp.getDouble(_kKeyIQ) ?? 149.4;
    final nouveau = double.parse((actuel + gain).toStringAsFixed(1));
    await sp.setDouble(_kKeyIQ, nouveau);
    changeNotifier.value++;
    return nouveau;
  }

  /// Récupère la ligue active (par défaut "Ligue Argent")
  Future<String> getLigueNom() async {
    final sp = await _prefs;
    return sp.getString(_kKeyLigue) ?? 'Ligue Argent';
  }

  /// Récupère le temps restant pour la session de tournoi (24h glissantes)
  Future<Duration> getTempsRestantLigue() async {
    final sp = await _prefs;
    final expireMillis = sp.getInt(_kKeyLigueExpire);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (expireMillis == null || expireMillis <= now) {
      // Nouvelle session de 24h
      final newExpire = DateTime.now().add(const Duration(hours: 23, minutes: 51, seconds: 35)).millisecondsSinceEpoch;
      await sp.setInt(_kKeyLigueExpire, newExpire);
      return const Duration(hours: 23, minutes: 51, seconds: 35);
    }

    return Duration(milliseconds: expireMillis - now);
  }

  /// Récupère l'inventaire des 4 boosters (mélange, annuler, indice, retour)
  Future<Map<String, int>> getBoosters() async {
    final sp = await _prefs;
    final raw = sp.getString(_kKeyBoosters);
    if (raw != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(raw);
        return map.map((k, v) => MapEntry(k, v as int));
      } catch (_) {}
    }
    // Valeurs par défaut comme sur la capture
    return {
      'shuffle': 38,
      'undo': 2,
      'hint': 17,
      'back': 31,
    };
  }

  /// Consomme ou ajoute un booster
  Future<void> modifierBooster(String type, int delta) async {
    final sp = await _prefs;
    final boosters = await getBoosters();
    final actuel = boosters[type] ?? 0;
    boosters[type] = math.max(0, actuel + delta);
    await sp.setString(_kKeyBoosters, jsonEncode(boosters));
    changeNotifier.value++;
  }

  /// ── ALGORITHME DU TOURNOI VIRTUEL ÉPHÉMÈRE (Le Yoyo des rangs) ──
  /// Génère et simule un groupe de compétition dynamique avec rivaux d'Afrique
  Future<List<JoueurTournoi>> getClassementTournoi({String? pseudoJoueur}) async {
    final sp = await _prefs;
    int scoreJoueur = sp.getInt(_kKeyPlayerScore) ?? 16;
    final pseudoActif = (pseudoJoueur != null && pseudoJoueur.trim().isNotEmpty)
        ? pseudoJoueur.trim()
        : (sp.getString(_kKeyPseudo) ?? 'Champion 🇹🇬');

    // Liste des rivaux simulés inspirée du modèle Vita Mahjong / Candy Crush
    // Adaptée 100% avec les nations et talents agricoles d'Afrique
    final List<Map<String, dynamic>> rivaux = [
      {'nom': 'Koffi_Lomé', 'drapeau': '🇹🇬', 'avatar': 'farmer_man', 'badge': 125, 'scoreBase': 24, 'coeurs': 0},
      {'nom': 'Amara_Abidjan', 'drapeau': '🇨🇮', 'avatar': 'lion', 'badge': 118, 'scoreBase': 22, 'coeurs': 0},
      {'nom': 'Fatou_Dakar', 'drapeau': '🇸🇳', 'avatar': 'elderly_woman', 'badge': 112, 'scoreBase': 20, 'coeurs': 0},
      {'nom': 'Kwame_Accra', 'drapeau': '🇬🇭', 'avatar': 'eagle', 'badge': 110, 'scoreBase': 20, 'coeurs': 0},
      {'nom': 'Chinedu_Lagos', 'drapeau': '🇳🇬', 'avatar': 'cat_warrior', 'badge': 95, 'scoreBase': 16, 'coeurs': 1},
      {'nom': 'Bio_Cotonou', 'drapeau': '🇧🇯', 'avatar': 'fox', 'badge': 88, 'scoreBase': 16, 'coeurs': 0},
      {'nom': 'Ibrahim_Ouaga', 'drapeau': '🇧🇫', 'avatar': 'bear', 'badge': 82, 'scoreBase': 14, 'coeurs': 2},
      {'nom': 'Moussa_Bamako', 'drapeau': '🇲🇱', 'avatar': 'bunny', 'badge': 78, 'scoreBase': 13, 'coeurs': 0},
      {'nom': 'Sani_Niamey', 'drapeau': '🇳🇪', 'avatar': 'kitten', 'badge': 70, 'scoreBase': 11, 'coeurs': 0},
      {'nom': 'Eto\'o_Douala', 'drapeau': '🇨🇲', 'avatar': 'grandma', 'badge': 65, 'scoreBase': 9, 'coeurs': 1},
    ];

    // Création de la liste combinée
    final List<JoueurTournoi> joueurs = [];

    // Joueur actuel mis en vedette
    joueurs.add(JoueurTournoi(
      rang: 5,
      nom: pseudoActif,
      drapeau: '🇹🇬',
      avatar: 'panda_hero',
      niveauBadge: 100,
      score: scoreJoueur,
      coeurs: 0,
      estJoueurActuel: true,
      statut: 'En jeu',
    ));

    // Adversaires
    for (final r in rivaux) {
      joueurs.add(JoueurTournoi(
        rang: 0,
        nom: r['nom'],
        drapeau: r['drapeau'],
        avatar: r['avatar'],
        niveauBadge: r['badge'],
        score: r['scoreBase'],
        coeurs: r['coeurs'],
        estJoueurActuel: false,
        statut: 'En jeu',
      ));
    }

    // Tri par score décroissant pour déterminer les rangs
    joueurs.sort((a, b) {
      if (b.score != a.score) return b.score.compareTo(a.score);
      // En cas d'égalité, privilégier le joueur actuel pour la gratification
      if (a.estJoueurActuel) return -1;
      if (b.estJoueurActuel) return 1;
      return a.nom.compareTo(b.nom);
    });

    // Attribution des rangs 1 à N
    final List<JoueurTournoi> classementFinal = [];
    for (int i = 0; i < joueurs.length; i++) {
      classementFinal.add(joueurs[i].copyWith(rang: i + 1));
    }

    return classementFinal;
  }

  /// Appelé à la fin d'une partie réussie : booste le score du joueur et simule une rivalité
  Future<({int nouveauScore, int ancienRang, int nouveauRang})> marquerVictoireTournoi() async {
    final sp = await _prefs;
    final scoreActuel = sp.getInt(_kKeyPlayerScore) ?? 16;

    // Récupérer le rang avant
    final avant = await getClassementTournoi();
    final indexAvant = avant.indexWhere((j) => j.estJoueurActuel);
    final ancienRang = indexAvant != -1 ? avant[indexAvant].rang : 5;

    // Gain de points pour cette victoire (+4 points)
    final nouveauScore = scoreActuel + 4;
    await sp.setInt(_kKeyPlayerScore, nouveauScore);

    // Calcul du nouveau rang
    final apres = await getClassementTournoi();
    final indexApres = apres.indexWhere((j) => j.estJoueurActuel);
    final nouveauRang = indexApres != -1 ? apres[indexApres].rang : 3;

    changeNotifier.value++;
    return (
      nouveauScore: nouveauScore,
      ancienRang: ancienRang,
      nouveauRang: nouveauRang,
    );
  }

  /// ── SUIVI DU CYCLE HEBDOMADAIRE (Daily Victories - Image 0) ──
  /// 7 jours : Sa, Su, Mo, Tu, We, Th, Fr
  Future<Map<String, bool>> getVictoiresHebdo() async {
    final sp = await _prefs;
    final raw = sp.getString(_kKeyDailyDays);
    if (raw != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        return decoded.map((k, v) => MapEntry(k, v as bool));
      } catch (_) {}
    }
    // Par défaut, samedi validé (comme sur l'image 0 où Sa est coché)
    return {
      'Sa': true,
      'Su': false,
      'Mo': false,
      'Tu': false,
      'We': false,
      'Th': false,
      'Fr': false,
    };
  }

  /// Valide le jour actuel dans le tableau hebdomadaire
  Future<void> validerJourAujourdhui() async {
    final sp = await _prefs;
    final jours = await getVictoiresHebdo();
    final weekday = DateTime.now().weekday;
    // Map weekday: 1=Mo, 2=Tu, 3=We, 4=Th, 5=Fr, 6=Sa, 7=Su
    String codeJour = 'Sa';
    switch (weekday) {
      case 1: codeJour = 'Mo'; break;
      case 2: codeJour = 'Tu'; break;
      case 3: codeJour = 'We'; break;
      case 4: codeJour = 'Th'; break;
      case 5: codeJour = 'Fr'; break;
      case 6: codeJour = 'Sa'; break;
      case 7: codeJour = 'Su'; break;
    }
    jours[codeJour] = true;
    await sp.setString(_kKeyDailyDays, jsonEncode(jours));
    changeNotifier.value++;
  }
}
