// Vue dédiée pour la catégorie "PRIX PRODUIT" accessible depuis la barre d'onglets.
// Affiche la Bourse Agricole complète avec tous les marchés du Togo (Cacaveli, Notsè, Kpalimé, Kara, Dapaong),
// recherche par denrée, filtrage par type, suivi des tendances (hausse/baisse) et partage WhatsApp.
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../core/design/app_colors.dart';
import '../data/marches_data.dart';

class PrixProduitsSection extends StatefulWidget {
  const PrixProduitsSection({super.key});

  @override
  State<PrixProduitsSection> createState() => _PrixProduitsSectionState();
}

class _PrixProduitsSectionState extends State<PrixProduitsSection> {
  String _marcheSelectionneId = 'tous';
  String _recherche = '';

  void _partagerBulletin(MarcheAgricole m, PrixProduit p) {
    final variation = p.tendance == TendancePrix.hausse
        ? '📈 En hausse (+${p.pourcentageVariation.toStringAsFixed(1)}%)'
        : p.tendance == TendancePrix.baisse
            ? '📉 En baisse (${p.pourcentageVariation.toStringAsFixed(1)}%)'
            : '⚪ Stable';

    final texte = '🌾 Cours des marchés AgriDigitale :\n'
        '• Produit : ${p.icone} ${p.produit}\n'
        '• Marché : ${m.nom} (${m.ville})\n'
        '• Prix actuel : ${p.prixActuel} FCFA / ${p.unite}\n'
        '• Prix précédent : ${p.prixPrecedent} FCFA\n'
        '• Tendance : $variation\n\n'
        'Consultez les prix agricoles en direct sur l\'app AgriDigitale : https://agridigitale.net';
    Share.share(texte);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Collecte des couples (Marché, Produit) filtrés
    final List<Map<String, dynamic>> itemsFiltres = [];

    for (final marche in MarchesData.marches) {
      if (_marcheSelectionneId != 'tous' && marche.id != _marcheSelectionneId) {
        continue;
      }
      for (final produit in marche.produits) {
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec titre
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF81C784)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'La Bourse Agricole en Direct',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.4),
                    ),
                    Text(
                      'Prix indicatifs sur les marchés vivriers du Togo',
                      style: TextStyle(fontSize: 12.5, color: AppColors.vertPrimaire, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Champ de recherche produit
          TextField(
            onChanged: (val) => setState(() => _recherche = val),
            decoration: InputDecoration(
              hintText: 'Rechercher maïs, soja, tomate, piment, igname...',
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.grisIcone),
              filled: true,
              fillColor: isDark ? AppColors.surfaceSombre : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Sélecteur horizontal de marchés
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildMarcheChip('tous', '📍 Tous les marchés', isDark),
                const SizedBox(width: 8),
                ...MarchesData.marches.map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildMarcheChip(m.id, '${m.ville} (${m.nom})', isDark),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Nombre de relevés
          Row(
            children: [
              Text(
                '${itemsFiltres.length} relevés de prix trouvés',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.texteSombreMoyen : AppColors.grisTexte,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.schedule, size: 12, color: AppColors.vertPrimaire),
                    SizedBox(width: 4),
                    Text(
                      'Relevé hebdo',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.vertPrimaire),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Liste des produits avec prix et variations
          if (itemsFiltres.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.grisIcone),
                  const SizedBox(height: 8),
                  Text(
                    'Aucun produit correspondant trouvé',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppColors.grisTexte,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemsFiltres.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final MarcheAgricole m = itemsFiltres[index]['marche'];
                final PrixProduit p = itemsFiltres[index]['produit'];

                Color couleurTendance;
                IconData iconeTendance;
                String libelleTendance;

                switch (p.tendance) {
                  case TendancePrix.hausse:
                    couleurTendance = const Color(0xFFD32F2F); // Rouge = plus cher pour l'acheteur
                    iconeTendance = Icons.trending_up;
                    libelleTendance = '+${p.difference} F (+${p.pourcentageVariation.toStringAsFixed(1)}%)';
                    break;
                  case TendancePrix.baisse:
                    couleurTendance = const Color(0xFF2E7D32); // Vert = baisse de prix
                    iconeTendance = Icons.trending_down;
                    libelleTendance = '${p.difference} F (${p.pourcentageVariation.toStringAsFixed(1)}%)';
                    break;
                  case TendancePrix.stable:
                    couleurTendance = Colors.grey;
                    iconeTendance = Icons.trending_flat;
                    libelleTendance = 'Stable';
                    break;
                }

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceSombre : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icône produit dans un conteneur rond
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white10 : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          p.icone,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Infos produit et marché
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.produit,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.texteFort,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${m.nom} • ${m.ville}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white60 : AppColors.grisTexte,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.vertPrimaire.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                p.unite,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.vertPrimaire,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Prix et variation
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${p.prixActuel} F',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.vertClair : AppColors.vertFonce,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(iconeTendance, size: 14, color: couleurTendance),
                              const SizedBox(width: 2),
                              Text(
                                libelleTendance,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: couleurTendance,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Bouton partage WhatsApp
                          InkWell(
                            onTap: () => _partagerBulletin(m, p),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.share_outlined, size: 13, color: AppColors.vertPrimaire),
                                  SizedBox(width: 3),
                                  Text(
                                    'Partager',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.vertPrimaire,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 24),
          // Conseil négoce
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.vertPrimaire.withValues(alpha: 0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💡', style: TextStyle(fontSize: 20)),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conseil de vente AgriDigitale',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Comparez toujours les cours des marchés voisins avant de livrer vos sacs aux acheteurs bord-champ. Un regroupement de producteurs permet souvent d\'obtenir 10% à 20% de valeur en plus !',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E7D32),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarcheChip(String id, String label, bool isDark) {
    final actif = _marcheSelectionneId == id;
    return ChoiceChip(
      label: Text(label),
      selected: actif,
      onSelected: (val) {
        if (val) setState(() => _marcheSelectionneId = id);
      },
      selectedColor: AppColors.vertPrimaire,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: actif ? FontWeight.bold : FontWeight.w500,
        color: actif ? Colors.white : (isDark ? Colors.white70 : AppColors.texteFort),
      ),
      backgroundColor: isDark ? AppColors.surfaceSombre : Colors.grey.shade200,
    );
  }
}
