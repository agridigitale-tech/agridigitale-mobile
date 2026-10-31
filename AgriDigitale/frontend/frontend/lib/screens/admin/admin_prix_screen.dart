// Écran d'administration dédié à la saisie et à la mise à jour des prix des produits agricoles.
// Permet de modifier le cours d'une denrée pour chaque marché, avec calcul automatique
// de la tendance et prévisualisation du mini-graphe (Rouge pour hausse, Vert pour baisse).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design/app_colors.dart';
import '../../data/marches_data.dart';
import '../../services/prix_produits_service.dart';
import '../../widgets/mini_graphe_tendance.dart';

class AdminPrixScreen extends StatefulWidget {
  final bool isTab;
  const AdminPrixScreen({super.key, this.isTab = false});

  @override
  State<AdminPrixScreen> createState() => _AdminPrixScreenState();
}

class _AdminPrixScreenState extends State<AdminPrixScreen> {
  final _service = PrixProduitsService();
  List<MarcheAgricole> _marches = [];
  bool _chargement = true;
  String _marcheSelectionneId = 'tous';
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _charger();
    _service.changeNotifier.addListener(_charger);
  }

  @override
  void dispose() {
    _service.changeNotifier.removeListener(_charger);
    super.dispose();
  }

  Future<void> _charger() async {
    final list = await _service.getMarches();
    if (mounted) {
      setState(() {
        _marches = list;
        _chargement = false;
      });
    }
  }

  void _ouvrirDialogueEdition({required MarcheAgricole marche, required PrixProduit produit}) {
    HapticFeedback.lightImpact();

    final prixActuelCtrl = TextEditingController(text: '${produit.prixActuel}');
    final prixPrecedentCtrl = TextEditingController(text: '${produit.prixPrecedent}');
    final uniteCtrl = TextEditingController(text: produit.unite);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final int nouveauPrix = int.tryParse(prixActuelCtrl.text.replaceAll(' ', '')) ?? produit.prixActuel;
          final int precedent = int.tryParse(prixPrecedentCtrl.text.replaceAll(' ', '')) ?? produit.prixPrecedent;

          final t = nouveauPrix > precedent
              ? TendancePrix.hausse
              : (nouveauPrix < precedent ? TendancePrix.baisse : TendancePrix.stable);

          final diff = nouveauPrix - precedent;
          final pct = precedent > 0 ? (diff / precedent) * 100 : 0.0;
          final couleurTendance = t == TendancePrix.hausse
              ? const Color(0xFFD32F2F) // Rouge pour hausse
              : (t == TendancePrix.baisse ? const Color(0xFF2E7D32) : Colors.grey);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poignée supérieure
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // En-tête avec nom du produit et marché
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.vertPrimaire.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(produit.icone, style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              produit.produit,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.texteFort),
                            ),
                            Text(
                              '${marche.nom} (${marche.ville})',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.grisTexte),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Prévisualisation en direct du mini-graphe et de la variation
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: couleurTendance.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: couleurTendance.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        MiniGrapheTendance(
                          tendance: t,
                          couleur: couleurTendance,
                          width: 58,
                          height: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t == TendancePrix.hausse
                                    ? 'Tendance : Hausse du cours'
                                    : (t == TendancePrix.baisse ? 'Tendance : Baisse du cours' : 'Tendance : Cours stable'),
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: couleurTendance),
                              ),
                              Text(
                                diff != 0
                                    ? '${diff > 0 ? '+' : ''}$diff F (${pct > 0 ? '+' : ''}${pct.toStringAsFixed(1)}%)'
                                    : 'Aucune variation',
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.grisTexte, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$nouveauPrix F',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: couleurTendance),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Champ 1 : Nouveau prix actuel
                  Text(
                    'Nouveau Prix Actuel (en FCFA)',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.texteFort),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: prixActuelCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setModalState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.monetization_on_outlined, color: AppColors.vertPrimaire),
                      suffixText: 'FCFA',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.vertPrimaire, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Champ 2 : Prix précédent
                  Text(
                    'Prix Précédent (référence précédente)',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.texteFort),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: prixPrecedentCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setModalState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.history, color: Colors.blueGrey),
                      suffixText: 'FCFA',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.vertPrimaire, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Champ 3 : Unité de mesure
                  Text(
                    'Unité de mesure',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.texteFort),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: uniteCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.scale_outlined, color: AppColors.grisIcone),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Bouton d'enregistrement
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final valActuel = int.tryParse(prixActuelCtrl.text.replaceAll(' ', ''));
                        final valPrec = int.tryParse(prixPrecedentCtrl.text.replaceAll(' ', ''));
                        if (valActuel == null || valActuel <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Veuillez saisir un prix valide supérieur à 0')),
                          );
                          return;
                        }

                        Navigator.pop(ctx);

                        await _service.updatePrixProduit(
                          marcheId: marche.id,
                          nomProduit: produit.produit,
                          nouveauPrix: valActuel,
                          nouveauPrixPrecedent: valPrec,
                          nouvelleUnite: uniteCtrl.text.trim().isNotEmpty ? uniteCtrl.text.trim() : null,
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Prix de "${produit.produit}" mis à jour avec succès ($valActuel FCFA) ✓'),
                              backgroundColor: AppColors.vertFonce,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.vertPrimaire,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: Text(
                        'ENREGISTRER LE NOUVEAU PRIX',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _dialogReinitialiser() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Réinitialiser les prix ?'),
        content: const Text(
          'Tous les cours personnalisés seront remis aux valeurs par défaut officielles du Togo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.resetToDefaults();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Les cours des marchés ont été réinitialisés avec succès ✓'),
                    backgroundColor: Colors.blueGrey,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Réinitialiser', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = _chargement
        ? const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire))
        : _buildContenu();

    if (widget.isTab) {
      return bodyContent;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Prix Produits', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.vertPrimaire,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Réinitialiser aux valeurs d\'origine',
            onPressed: _dialogReinitialiser,
          ),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildContenu() {
    // Collecte des couples filtrés
    final List<Map<String, dynamic>> itemsFiltres = [];
    int totalHausse = 0;
    int totalBaisse = 0;
    int totalStable = 0;

    for (final marche in _marches) {
      for (final produit in marche.produits) {
        if (produit.tendance == TendancePrix.hausse) totalHausse++;
        if (produit.tendance == TendancePrix.baisse) totalBaisse++;
        if (produit.tendance == TendancePrix.stable) totalStable++;

        if (_marcheSelectionneId != 'tous' && marche.id != _marcheSelectionneId) {
          continue;
        }

        if (_recherche.isNotEmpty) {
          final q = _recherche.toLowerCase();
          final match = produit.produit.toLowerCase().contains(q) ||
              marche.nom.toLowerCase().contains(q) ||
              marche.ville.toLowerCase().contains(q);
          if (!match) continue;
        }

        itemsFiltres.add({
          'marche': marche,
          'produit': produit,
        });
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cartes statistiques résumées
          Row(
            children: [
              Expanded(
                child: _buildCarteStat(
                  titre: 'En hausse',
                  valeur: '$totalHausse',
                  couleur: const Color(0xFFD32F2F),
                  icone: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCarteStat(
                  titre: 'En baisse',
                  valeur: '$totalBaisse',
                  couleur: const Color(0xFF2E7D32),
                  icone: Icons.trending_down,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCarteStat(
                  titre: 'Stables',
                  valeur: '$totalStable',
                  couleur: Colors.blueGrey,
                  icone: Icons.trending_flat,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Champ de recherche
          TextField(
            onChanged: (val) => setState(() => _recherche = val),
            decoration: InputDecoration(
              hintText: 'Rechercher une denrée à éditer...',
              prefixIcon: const Icon(Icons.search, color: AppColors.grisIcone),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Sélecteur horizontal de marchés
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildMarcheChip('tous', 'Tous les marchés'),
                const SizedBox(width: 8),
                ..._marches.map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildMarcheChip(m.id, '${m.ville} (${m.nom})'),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Titre de la liste & bouton de réinitialisation
          Row(
            children: [
              Text(
                '${itemsFiltres.length} denrées répertoriées',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.texteFort),
              ),
              const Spacer(),
              if (widget.isTab)
                TextButton.icon(
                  onPressed: _dialogReinitialiser,
                  icon: const Icon(Icons.restore, size: 16, color: Colors.blueGrey),
                  label: const Text('Rétablir par défaut', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // 5. Liste des produits éditables
          if (itemsFiltres.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text('Aucun produit trouvé pour ce filtre.', style: TextStyle(color: AppColors.grisTexte)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemsFiltres.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final MarcheAgricole m = itemsFiltres[i]['marche'];
                final PrixProduit p = itemsFiltres[i]['produit'];

                final couleurTendance = p.tendance == TendancePrix.hausse
                    ? const Color(0xFFD32F2F) // Rouge pour hausse
                    : (p.tendance == TendancePrix.baisse ? const Color(0xFF2E7D32) : Colors.grey);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icône
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(p.icone, style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),

                      // Infos produit
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.produit,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.texteFort),
                            ),
                            Text(
                              '${m.nom} • ${m.ville}',
                              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.grisTexte),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.vertPrimaire.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                p.unite,
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.vertPrimaire),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Mini graphe étincelle (Rouge si monté, Vert si baisse)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${p.prixActuel} F',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: couleurTendance),
                          ),
                          const SizedBox(height: 3),
                          MiniGrapheTendance(
                            tendance: p.tendance,
                            couleur: couleurTendance,
                            points: p.historiquePrix,
                            width: 50,
                            height: 18,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Préc. ${p.prixPrecedent} F',
                            style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.grisTexte),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),

                      // Bouton d'édition rapide
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.vertPrimaire, size: 20),
                        tooltip: 'Modifier ce prix',
                        onPressed: () => _ouvrirDialogueEdition(marche: m, produit: p),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCarteStat({required String titre, required String valeur, required Color couleur, required IconData icone}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, size: 14, color: couleur),
              const SizedBox(width: 4),
              Text(titre, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: couleur)),
            ],
          ),
          const SizedBox(height: 2),
          Text(valeur, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: couleur)),
        ],
      ),
    );
  }

  Widget _buildMarcheChip(String id, String label) {
    final estSelectionne = (_marcheSelectionneId == id);
    return ChoiceChip(
      label: Text(label),
      selected: estSelectionne,
      onSelected: (_) => setState(() => _marcheSelectionneId = id),
      selectedColor: AppColors.vertPrimaire,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: estSelectionne ? FontWeight.bold : FontWeight.normal,
        color: estSelectionne ? Colors.white : Colors.black87,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
