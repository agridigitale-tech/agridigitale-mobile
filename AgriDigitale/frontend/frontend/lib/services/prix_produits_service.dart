// Service de gestion dynamique des prix des produits et marchés agricoles.
// Persistance locale via SharedPreferences avec synchronisation réseau bidirectionnelle.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../data/marches_data.dart';

/// Modèle représentant une alerte de variation de cours (affichée dans la bande jaune)
class AlertePrixMarche {
  final String produit;
  final String nomMarche;
  final String ville;
  final int prixActuel;
  final int prixPrecedent;
  final TendancePrix tendance;
  final DateTime date;
  final String? imageOuIcone;

  AlertePrixMarche({
    required this.produit,
    required this.nomMarche,
    required this.ville,
    required this.prixActuel,
    required this.prixPrecedent,
    required this.tendance,
    required this.date,
    this.imageOuIcone,
  });

  int get difference => prixActuel - prixPrecedent;

  /// Texte formaté pour l'animation de saisie clavier
  String get texteAlerteClavier {
    final diffAbs = (prixActuel - prixPrecedent).abs();
    if (tendance == TendancePrix.hausse) {
      return 'HAUSSE DE PRIX : $produit passe à $prixActuel FCFA (+$diffAbs F) au $nomMarche ($ville)';
    } else if (tendance == TendancePrix.baisse) {
      return 'BAISSE DE PRIX : $produit passe à $prixActuel FCFA (-$diffAbs F) au $nomMarche ($ville)';
    } else {
      return 'COURS DU MARCHÉ : $produit est à $prixActuel FCFA au $nomMarche ($ville)';
    }
  }

  Map<String, dynamic> toJson() => {
    'produit': produit,
    'nomMarche': nomMarche,
    'ville': ville,
    'prixActuel': prixActuel,
    'prixPrecedent': prixPrecedent,
    'tendance': tendance.name,
    'date': date.toIso8601String(),
    'imageOuIcone': imageOuIcone,
  };

  factory AlertePrixMarche.fromJson(Map<String, dynamic> json) => AlertePrixMarche(
    produit: json['produit'] as String? ?? '',
    nomMarche: json['nomMarche'] as String? ?? '',
    ville: json['ville'] as String? ?? '',
    prixActuel: (json['prixActuel'] as num?)?.toInt() ?? 0,
    prixPrecedent: (json['prixPrecedent'] as num?)?.toInt() ?? 0,
    tendance: TendancePrix.values.firstWhere(
      (e) => e.name == json['tendance'],
      orElse: () => TendancePrix.stable,
    ),
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    imageOuIcone: json['imageOuIcone'] as String?,
  );
}

class PrixProduitsService {
  static final PrixProduitsService _instance = PrixProduitsService._internal();
  factory PrixProduitsService() => _instance;
  PrixProduitsService._internal();

  static const String _kStorageKey = 'agri_prix_produits_v2';
  static const String _kStorageKeyAlerte = 'agri_derniere_alerte_prix';

  final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  /// Notifier global pour la bande jaune en superposition
  static final ValueNotifier<AlertePrixMarche?> alerteBandeJauneNotifier =
      ValueNotifier<AlertePrixMarche?>(null);

  List<MarcheAgricole>? _cache;

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  /// Récupère la dernière alerte active si elle date de moins d'une minute (60s)
  Future<AlertePrixMarche?> getDerniereAlerteActive() async {
    try {
      final sp = await _prefs;
      final raw = sp.getString(_kStorageKeyAlerte);
      if (raw != null && raw.isNotEmpty) {
        final alerte = AlertePrixMarche.fromJson(jsonDecode(raw));
        final diffSecondes = DateTime.now().difference(alerte.date).inSeconds;
        if (diffSecondes < 60 && diffSecondes >= 0) {
          alerteBandeJauneNotifier.value = alerte;
          return alerte;
        } else {
          await sp.remove(_kStorageKeyAlerte);
        }
      }
    } catch (e) {
      debugPrint('[PrixProduitsService] Erreur lecture alerte active: $e');
    }
    return null;
  }

  /// Déclenche l'alerte de la bande jaune pour 1 minute
  Future<void> declencherAlerteBandeJaune(AlertePrixMarche alerte) async {
    try {
      final sp = await _prefs;
      await sp.setString(_kStorageKeyAlerte, jsonEncode(alerte.toJson()));
    } catch (_) {}
    alerteBandeJauneNotifier.value = alerte;
  }

  /// Ferme la bande jaune
  Future<void> fermerAlerteBandeJaune() async {
    try {
      final sp = await _prefs;
      await sp.remove(_kStorageKeyAlerte);
    } catch (_) {}
    alerteBandeJauneNotifier.value = null;
  }

  /// Récupère la liste complète des marchés et de leurs cours
  Future<List<MarcheAgricole>> getMarches({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null && _cache!.isNotEmpty) {
      return _cache!;
    }

    try {
      final sp = await _prefs;
      final raw = sp.getString(_kStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        _cache = decoded
            .map((e) => MarcheAgricole.fromJson(e as Map<String, dynamic>))
            .toList();
        return _cache!;
      }
    } catch (e) {
      debugPrint('[PrixProduitsService] Erreur lecture locale: $e');
    }

    // Essayer de charger depuis le backend si disponible
    try {
      final rep = await ApiClient().dio.get('/prix-marches');
      if (rep.statusCode == 200 && rep.data is List) {
        final List<dynamic> list = rep.data;
        _cache = list
            .map((e) => MarcheAgricole.fromJson(e as Map<String, dynamic>))
            .toList();
        await _sauvegarderLocalement(_cache!);
        return _cache!;
      }
    } catch (_) {
      // Mode hors-ligne ou backend indisponible
    }

    // Initialisation avec le référentiel officiel MarchesData
    _cache = List<MarcheAgricole>.from(MarchesData.marches);
    await _sauvegarderLocalement(_cache!);
    return _cache!;
  }

  /// Sauvegarde la liste complète localement
  Future<void> _sauvegarderLocalement(List<MarcheAgricole> marches) async {
    try {
      final sp = await _prefs;
      final encoded = jsonEncode(marches.map((m) => m.toJson()).toList());
      await sp.setString(_kStorageKey, encoded);
    } catch (e) {
      debugPrint('[PrixProduitsService] Erreur sauvegarde: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════
  // ── CRUD PRODUIT ET PRIX SUR UN MARCHÉ
  // ════════════════════════════════════════════════════════════════

  /// Met à jour le prix d'un produit spécifique pour un marché donné
  Future<void> updatePrixProduit({
    required String marcheId,
    required String nomProduit,
    required int nouveauPrix,
    int? nouveauPrixPrecedent,
    String? nouvelleUnite,
    String? nouvelleIcone,
  }) async {
    final marches = await getMarches();
    final indexMarche = marches.indexWhere((m) => m.id == marcheId);
    if (indexMarche == -1) return;

    final marche = marches[indexMarche];
    final indexProd = marche.produits.indexWhere((p) => p.produit == nomProduit);
    if (indexProd == -1) return;

    final ancien = marche.produits[indexProd];
    final precedent = nouveauPrixPrecedent ?? ancien.prixActuel;
    final t = nouveauPrix > precedent
        ? TendancePrix.hausse
        : (nouveauPrix < precedent ? TendancePrix.baisse : TendancePrix.stable);

    // Mise à jour de l'historique des relevés pour mini-graphe
    final hist = List<int>.from(ancien.historiquePrix ?? [ancien.prixPrecedent, ancien.prixActuel]);
    hist.add(nouveauPrix);
    if (hist.length > 7) {
      hist.removeAt(0);
    }

    final misAJour = ancien.copyWith(
      prixActuel: nouveauPrix,
      prixPrecedent: precedent,
      tendance: t,
      unite: nouvelleUnite ?? ancien.unite,
      icone: nouvelleIcone ?? ancien.icone,
      historiquePrix: hist,
    );

    final nouveauxProduits = List<PrixProduit>.from(marche.produits);
    nouveauxProduits[indexProd] = misAJour;

    marches[indexMarche] = marche.copyWith(produits: nouveauxProduits);
    _cache = marches;

    await _sauvegarderLocalement(marches);

    // Déclencher l'alerte jaune si le prix a varié
    if (nouveauPrix != precedent) {
      final alerte = AlertePrixMarche(
        produit: misAJour.produit,
        nomMarche: marche.nom,
        ville: marche.ville,
        prixActuel: nouveauPrix,
        prixPrecedent: precedent,
        tendance: t,
        date: DateTime.now(),
        imageOuIcone: misAJour.icone,
      );
      await declencherAlerteBandeJaune(alerte);
    }

    _synchroniserBackendProduit(marcheId, misAJour);
    changeNotifier.value++;
  }

  /// Ajoute un nouveau produit à un marché
  Future<void> ajouterProduit({
    required String marcheId,
    required PrixProduit produit,
  }) async {
    final marches = await getMarches();
    final indexMarche = marches.indexWhere((m) => m.id == marcheId);
    if (indexMarche == -1) return;

    final marche = marches[indexMarche];
    // Remplacer si existe déjà ou ajouter
    final prods = List<PrixProduit>.from(marche.produits);
    final idx = prods.indexWhere((p) => p.produit == produit.produit);
    if (idx != -1) {
      prods[idx] = produit;
    } else {
      prods.add(produit);
    }

    marches[indexMarche] = marche.copyWith(produits: prods);
    _cache = marches;

    await _sauvegarderLocalement(marches);

    // Déclencher l'alerte jaune
    final alerte = AlertePrixMarche(
      produit: produit.produit,
      nomMarche: marche.nom,
      ville: marche.ville,
      prixActuel: produit.prixActuel,
      prixPrecedent: produit.prixPrecedent,
      tendance: produit.tendance,
      date: DateTime.now(),
      imageOuIcone: produit.icone,
    );
    await declencherAlerteBandeJaune(alerte);

    _synchroniserBackendProduit(marcheId, produit);
    changeNotifier.value++;
  }

  /// Supprime un produit d'un marché
  Future<void> supprimerProduit({
    required String marcheId,
    required String nomProduit,
  }) async {
    final marches = await getMarches();
    final indexMarche = marches.indexWhere((m) => m.id == marcheId);
    if (indexMarche == -1) return;

    final marche = marches[indexMarche];
    final prods = List<PrixProduit>.from(marche.produits)
      ..removeWhere((p) => p.produit == nomProduit);
    marches[indexMarche] = marche.copyWith(produits: prods);
    _cache = marches;

    await _sauvegarderLocalement(marches);
    _synchroniserBackendSupprimerProduit(marcheId, nomProduit);
    changeNotifier.value++;
  }

  // ════════════════════════════════════════════════════════════════
  // ── CRUD MARCHÉS
  // ════════════════════════════════════════════════════════════════

  /// Crée un nouveau marché
  Future<void> ajouterMarche({required MarcheAgricole marche}) async {
    final marches = await getMarches();
    // Vérifier l'unicité
    if (marches.any((m) => m.id == marche.id)) {
      throw Exception('Un marché avec cet identifiant existe déjà');
    }

    marches.add(marche);
    _cache = marches;
    await _sauvegarderLocalement(marches);
    _synchroniserBackendMarche(marche);
    changeNotifier.value++;
  }

  /// Modifie un marché existant (nom, ville, région)
  Future<void> modifierMarche({
    required String id,
    required String nom,
    required String ville,
    required String region,
  }) async {
    final marches = await getMarches();
    final idx = marches.indexWhere((m) => m.id == id);
    if (idx == -1) return;

    final ancien = marches[idx];
    final maj = ancien.copyWith(nom: nom, ville: ville, region: region);
    marches[idx] = maj;
    _cache = marches;

    await _sauvegarderLocalement(marches);
    _synchroniserBackendModifierMarche(maj);
    changeNotifier.value++;
  }

  /// Supprime un marché
  Future<void> supprimerMarche({required String id}) async {
    final marches = await getMarches();
    marches.removeWhere((m) => m.id == id);
    _cache = marches;

    await _sauvegarderLocalement(marches);
    _synchroniserBackendSupprimerMarche(id);
    changeNotifier.value++;
  }

  /// Réinitialise tous les cours avec les données de référence
  Future<void> resetToDefaults() async {
    _cache = List<MarcheAgricole>.from(MarchesData.marches);
    await _sauvegarderLocalement(_cache!);
    try {
      await ApiClient().dio.post('/prix-marches/reset');
    } catch (_) {}
    changeNotifier.value++;
  }

  // ════════════════════════════════════════════════════════════════
  // ── SYNCHRONISATION DISTANTE ASYNCHRONE
  // ════════════════════════════════════════════════════════════════

  void _synchroniserBackendProduit(String marcheId, PrixProduit produit) async {
    try {
      await ApiClient().dio.put('/prix-marches', data: {
        'marcheId': marcheId,
        'produit': produit.toJson(),
      });
    } catch (err) {
      debugPrint('[PrixProduitsService] Synchro produit distante : $err');
    }
  }

  void _synchroniserBackendSupprimerProduit(String marcheId, String nomProduit) async {
    try {
      await ApiClient().dio.delete(
        '/prix-marches/marche/$marcheId/produit/${Uri.encodeComponent(nomProduit)}',
      );
    } catch (err) {
      debugPrint('[PrixProduitsService] Synchro suppression produit : $err');
    }
  }

  void _synchroniserBackendMarche(MarcheAgricole marche) async {
    try {
      await ApiClient().dio.post('/prix-marches/marche', data: marche.toJson());
    } catch (err) {
      debugPrint('[PrixProduitsService] Synchro ajout marché : $err');
    }
  }

  void _synchroniserBackendModifierMarche(MarcheAgricole marche) async {
    try {
      await ApiClient().dio.put('/prix-marches/marche/${marche.id}', data: {
        'nom': marche.nom,
        'ville': marche.ville,
        'region': marche.region,
      });
    } catch (err) {
      debugPrint('[PrixProduitsService] Synchro modification marché : $err');
    }
  }

  void _synchroniserBackendSupprimerMarche(String marcheId) async {
    try {
      await ApiClient().dio.delete('/prix-marches/marche/$marcheId');
    } catch (err) {
      debugPrint('[PrixProduitsService] Synchro suppression marché : $err');
    }
  }
}
