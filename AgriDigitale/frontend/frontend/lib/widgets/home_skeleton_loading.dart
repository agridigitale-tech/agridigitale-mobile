// Squelette de chargement animé (Skeleton / Shimmer) pour l'écran d'accueil.
// Reproduit fidèlement la structure de la page d'accueil :
//  - Section "À la une" avec badge "🔥 TENDANCE" et grande carte héro
//  - Section "À ne pas manquer" avec carrousel horizontal de cartes
//  - Section "Dernières actualités" avec cartes horizontales
// Optimisé pour un shimmer synchronisé à 60 FPS et compatible mode sombre.

import 'package:flutter/material.dart';
import '../core/design/app_colors.dart';

/// Contrôleur et fournisseur du dégradé shimmer partagé pour tous les éléments enfants.
class ShimmerProvider extends StatefulWidget {
  final Widget child;

  const ShimmerProvider({super.key, required this.child});

  static double of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShimmerInherited>()?.percent ?? 0.0;
  }

  @override
  State<ShimmerProvider> createState() => _ShimmerProviderState();
}

class _ShimmerProviderState extends State<ShimmerProvider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ShimmerInherited(
          percent: _controller.value,
          child: widget.child,
        );
      },
    );
  }
}

class ShimmerInherited extends InheritedWidget {
  final double percent;

  const ShimmerInherited({
    super.key,
    required this.percent,
    required super.child,
  });

  @override
  bool updateShouldNotify(ShimmerInherited oldWidget) =>
      percent != oldWidget.percent;
}

/// Bloc élémentaire du squelette avec effet lumineux balayant (shimmer).
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final BorderRadius? customBorderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
    this.customBorderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percent = ShimmerProvider.of(context);

    final baseColor = isDark ? const Color(0xFF1E2620) : const Color(0xFFE5E7EB);
    final highlightColor = isDark ? const Color(0xFF2C382F) : const Color(0xFFF3F4F6);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: customBorderRadius ?? BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1.5 + percent * 3.0, -0.3),
          end: Alignment(-0.5 + percent * 3.0, 0.3),
          colors: [
            baseColor,
            highlightColor,
            baseColor,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

/// Squelette complet de l'écran d'accueil reproduisant la capture d'écran.
class HomeSkeletonLoading extends StatelessWidget {
  final String? categorie;

  const HomeSkeletonLoading({
    super.key,
    this.categorie,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ShimmerProvider(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (categorie == null) ...[
            // 1. En-tête de section "À la une" + badge "TENDANCE"
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.redAccent, Colors.orange],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SkeletonBox(width: 90, height: 18, radius: 4),
                  const Spacer(),
                  // Badge 🔥 TENDANCE squelette
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SkeletonBox(width: 65, height: 12, radius: 4),
                  ),
                ],
              ),
            ),

            // 2. Grande carte héro "À la une" (hauteur ~230)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 230,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Fond shimmer de la carte entière
                    const SkeletonBox(
                      width: double.infinity,
                      height: double.infinity,
                      radius: 16,
                    ),

                    // Contenu superposé (Badges et lignes de texte)
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge "⚡ À LA UNE"
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const SkeletonBox(width: 75, height: 12, radius: 4),
                          ),
                          const Spacer(),
                          // Badge Catégorie ("TOGO")
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const SkeletonBox(width: 50, height: 12, radius: 4),
                          ),
                          const SizedBox(height: 8),
                          // Titre - Ligne 1
                          const SkeletonBox(
                            width: double.infinity,
                            height: 16,
                            radius: 4,
                          ),
                          const SizedBox(height: 6),
                          // Titre - Ligne 2
                          const SkeletonBox(
                            width: 220,
                            height: 16,
                            radius: 4,
                          ),
                          const SizedBox(height: 8),
                          // Timestamp "🕒 Il y a 3h"
                          const SkeletonBox(width: 70, height: 11, radius: 3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. En-tête "À ne pas manquer"
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFE65100), Colors.amber],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SkeletonBox(width: 140, height: 18, radius: 4),
                ],
              ),
            ),

            // 4. Carrousel horizontal "À ne pas manquer" (hauteur 236)
            SizedBox(
              height: 236,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, _) => _buildCarteVerticaleSkeleton(isDark),
              ),
            ),

            // 5. En-tête "Dernières actualités"
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.vertPrimaire, Color(0xFF66BB6A)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SkeletonBox(width: 160, height: 18, radius: 4),
                ],
              ),
            ),
          ] else ...[
            // Catégorie active filtrée (ex: TOGO, AFRIQUE, MONDE)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.vertPrimaire, Color(0xFF66BB6A)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SkeletonBox(width: 140, height: 18, radius: 4),
                ],
              ),
            ),
          ],

          // 6. Liste verticale d'articles (cartes horizontales)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            itemCount: categorie == null ? 3 : 5,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, _) => _buildCarteHorizontaleSkeleton(isDark),
          ),
        ],
      ),
    );
  }

  /// Squelette d'une carte verticale pour le carrousel "À ne pas manquer"
  Widget _buildCarteVerticaleSkeleton(bool isDark) {
    return Container(
      width: 165,
      height: 236,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceSombre : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image en haut
            const SkeletonBox(
              width: 165,
              height: 115,
              radius: 0,
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Catégorie
                  const SkeletonBox(width: 55, height: 12, radius: 4),
                  const SizedBox(height: 8),
                  // Titre Ligne 1
                  const SkeletonBox(width: 140, height: 12, radius: 3),
                  const SizedBox(height: 5),
                  // Titre Ligne 2
                  const SkeletonBox(width: 95, height: 12, radius: 3),
                  const SizedBox(height: 10),
                  // Date
                  const SkeletonBox(width: 60, height: 10, radius: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Squelette d'une carte horizontale (liste principale des articles)
  Widget _buildCarteHorizontaleSkeleton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceSombre : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Miniature d'image
          const SkeletonBox(
            width: 100,
            height: 82,
            radius: 10,
          ),
          const SizedBox(width: 12),
          // Colonne texte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Catégorie
                const SkeletonBox(width: 60, height: 12, radius: 4),
                const SizedBox(height: 8),
                // Titre Ligne 1
                const SkeletonBox(width: double.infinity, height: 13, radius: 3),
                const SizedBox(height: 5),
                // Titre Ligne 2
                const SkeletonBox(width: 150, height: 13, radius: 3),
                const SizedBox(height: 10),
                // Date & durée
                const SkeletonBox(width: 80, height: 10, radius: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
