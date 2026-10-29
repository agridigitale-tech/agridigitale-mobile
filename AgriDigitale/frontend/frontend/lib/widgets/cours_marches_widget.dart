// Widget "La Bourse Agricole" : Cours des marchés vivriers au Togo.
// Permet aux producteurs et commerçants de comparer les prix et négocier au juste prix.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/design/app_colors.dart';
import '../data/marches_data.dart';

class CoursMarchesWidget extends StatefulWidget {
  const CoursMarchesWidget({super.key});

  @override
  State<CoursMarchesWidget> createState() => _CoursMarchesWidgetState();
}

class _CoursMarchesWidgetState extends State<CoursMarchesWidget> {
  int _marcheIndex = 0;
  bool _voirTout = false;
  final NumberFormat _fmt = NumberFormat('#,###', 'fr_FR');

  MarcheAgricole get _marcheSelectionne => MarchesData.marches[_marcheIndex];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final produits = _voirTout
        ? _marcheSelectionne.produits
        : _marcheSelectionne.produits.take(4).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceSombre : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.vertClair : AppColors.vertPrimaire).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : Titre + Badge Bourse
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade800,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storefront, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bourse Agricole des Marchés',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    Text(
                      'Prix indicatifs des denrées au Togo',
                      style: TextStyle(fontSize: 11, color: AppColors.grisTexte),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('Cette semaine', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sélecteur horizontal de marchés
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: MarchesData.marches.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final m = MarchesData.marches[i];
                final estActif = (_marcheIndex == i);
                return InkWell(
                  onTap: () => setState(() => _marcheIndex = i),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: estActif
                          ? AppColors.vertPrimaire
                          : (isDark ? AppColors.surfaceSombreLegere : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: estActif ? AppColors.vertPrimaire : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        m.nom,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: estActif ? FontWeight.bold : FontWeight.w500,
                          color: estActif ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Tableau / Liste des produits et prix
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: produits.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? AppColors.bordureSombre : Colors.grey.shade200),
            itemBuilder: (context, i) {
              final p = produits[i];
              Color couleurTendance;
              IconData iconeTendance;
              String texteVariation;

              switch (p.tendance) {
                case TendancePrix.hausse:
                  couleurTendance = Colors.red.shade700;
                  iconeTendance = Icons.trending_up;
                  texteVariation = '+${p.difference} F';
                  break;
                case TendancePrix.baisse:
                  couleurTendance = Colors.green.shade700;
                  iconeTendance = Icons.trending_down;
                  texteVariation = '${p.difference} F';
                  break;
                case TendancePrix.stable:
                  couleurTendance = Colors.grey.shade600;
                  iconeTendance = Icons.trending_flat;
                  texteVariation = 'Stable';
                  break;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(p.icone, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.produit,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            p.unite,
                            style: const TextStyle(fontSize: 11, color: AppColors.grisTexte),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_fmt.format(p.prixActuel)} FCFA',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(iconeTendance, size: 12, color: couleurTendance),
                            const SizedBox(width: 2),
                            Text(
                              texteVariation,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: couleurTendance,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Bouton voir plus / voir moins
          if (_marcheSelectionne.produits.length > 4) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _voirTout = !_voirTout),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: isDark ? AppColors.vertClair : AppColors.vertPrimaire,
                ),
                child: Text(
                  _voirTout ? '▲ Voir moins de denrées' : '▼ Voir les ${_marcheSelectionne.produits.length} denrées du marché',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
