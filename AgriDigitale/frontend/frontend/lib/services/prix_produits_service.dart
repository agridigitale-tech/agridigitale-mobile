// Service de gestion dynamique des prix des produits et marchés agricoles.
// Persistance locale via SharedPreferences avec synchronisation réseau optionnelle.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../data/marches_data.dart';

class PrixProduitsService {
  static final PrixProduitsService _instance = PrixProduitsService._internal();
  factory PrixProduitsService() => _instance;
  PrixProduitsService._internal();

  static const String _kStorageKey = 'agri_prix_produits_v1';

  final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);
  List<MarcheAgricole>? _cache;

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

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
      // Mode hors-ligne ou backend sans route : utilisation du référentiel par défaut
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

  /// Met à jour le prix d'un produit spécifique pour un marché donné
  Future<void> updatePrixProduit({
    required String marcheId,
    required String nomProduit,
    required int nouveauPrix,
    int? nouveauPrixPrecedent,
    String? nouvelleUnite,
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

    // Mise à jour de l'historique des points pour le graphe
    final hist = List<int>.from(ancien.historiquePrix ?? [ancien.prixPrecedent, ancien.prixActuel]);
    hist.add(nouveauPrix);
    if (hist.length > 7) {
      hist.removeAt(0); // Garder les 7 derniers relevés max
    }

    final misAJour = ancien.copyWith(
      prixActuel: nouveauPrix,
      prixPrecedent: precedent,
      tendance: t,
      unite: nouvelleUnite ?? ancien.unite,
      historiquePrix: hist,
    );

    final nouveauxProduits = List<PrixProduit>.from(marche.produits);
    nouveauxProduits[indexProd] = misAJour;

    marches[indexMarche] = marche.copyWith(produits: nouveauxProduits);
    _cache = marches;

    await _sauvegarderLocalement(marches);
    _synchroniserBackend(marcheId, misAJour);

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
    final prods = List<PrixProduit>.from(marche.produits)..add(produit);
    marches[indexMarche] = marche.copyWith(produits: prods);
    _cache = marches;

    await _sauvegarderLocalement(marches);
    _synchroniserBackend(marcheId, produit);
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
    changeNotifier.value++;
  }

  /// Réinitialise tous les cours avec les données de référence
  Future<void> resetToDefaults() async {
    _cache = List<MarcheAgricole>.from(MarchesData.marches);
    await _sauvegarderLocalement(_cache!);
    changeNotifier.value++;
  }

  /// Envoi asynchrone au backend si en ligne
  void _synchroniserBackend(String marcheId, PrixProduit produit) async {
    try {
      await ApiClient().dio.put('/prix-marches', data: {
        'marcheId': marcheId,
        'produit': produit.toJson(),
      });
    } catch (err) {
      debugPrint('[PrixProduitsService] Synchro distante échouée (sauvegardé en local) : $err');
    }
  }
}
