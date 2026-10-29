// Barre de catégories en carrousel horizontal avec défilement très lent et fluide.
// Chaque catégorie est encadrée avec un borderRadius arrondi (style badge / capsule).
// S'interrompt automatiquement dès que l'utilisateur touche l'écran pour une ergonomie parfaite.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/design/app_colors.dart';

class CategoriesCarouselBar extends StatefulWidget {
  final List<String> categories;
  final String? categorieActive;
  final ValueChanged<String?> onSelectCategorie;

  const CategoriesCarouselBar({
    super.key,
    required this.categories,
    required this.categorieActive,
    required this.onSelectCategorie,
  });

  @override
  State<CategoriesCarouselBar> createState() => _CategoriesCarouselBarState();
}

class _CategoriesCarouselBarState extends State<CategoriesCarouselBar> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timerAutoScroll;
  Timer? _timerReprise;
  bool _utilisateurInteragit = false;
  bool _enSensAvant = true;
  bool _enPauseExtremite = false;

  @override
  void initState() {
    super.initState();
    _demarrerDefilementLent();
  }

  void _demarrerDefilementLent() {
    // Tique toutes les 60ms pour un déplacement très doux d'environ 10 pixels / seconde
    _timerAutoScroll?.cancel();
    _timerAutoScroll = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (!mounted || _utilisateurInteragit || _enPauseExtremite) return;
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) return;

      final offsetActuel = _scrollController.offset;
      const step = 0.65; // Vitesse très lente

      if (_enSensAvant) {
        final prochain = offsetActuel + step;
        if (prochain >= maxScroll) {
          _scrollController.jumpTo(maxScroll);
          _enSensAvant = false;
          _fairePauseExtremite();
        } else {
          _scrollController.jumpTo(prochain);
        }
      } else {
        final prochain = offsetActuel - step;
        if (prochain <= 0) {
          _scrollController.jumpTo(0);
          _enSensAvant = true;
          _fairePauseExtremite();
        } else {
          _scrollController.jumpTo(prochain);
        }
      }
    });
  }

  void _fairePauseExtremite() {
    _enPauseExtremite = true;
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() => _enPauseExtremite = false);
      }
    });
  }

  void _onInteractionDebut() {
    _utilisateurInteragit = true;
    _timerReprise?.cancel();
  }

  void _onInteractionFin() {
    _timerReprise?.cancel();
    // Reprend le glissement automatique après 3.5 secondes d'inactivité
    _timerReprise = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() => _utilisateurInteragit = false);
      }
    });
  }

  @override
  void dispose() {
    _timerAutoScroll?.cancel();
    _timerReprise?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  String _recupererIcone(String cat) {
    switch (cat.toUpperCase()) {
      case 'HOME':
        return '🏠';
      case 'TOGO':
        return '🇹🇬';
      case 'AFRIQUE':
        return '🌍';
      case 'MONDE':
        return '🌐';
      case 'CONSEIL DU JOUR':
        return '☀️';
      case 'PRIX PRODUIT':
        return '🌾';
      default:
        return '📰';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Listener(
      onPointerDown: (_) => _onInteractionDebut(),
      onPointerUp: (_) => _onInteractionFin(),
      onPointerCancel: (_) => _onInteractionFin(),
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          itemCount: widget.categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final cat = widget.categories[index];
            final actif = (cat.toUpperCase() == 'HOME' && widget.categorieActive == null) ||
                cat.toUpperCase() == widget.categorieActive?.toUpperCase();

            final icone = _recupererIcone(cat);

            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                _onInteractionDebut();
                _onInteractionFin();
                widget.onSelectCategorie(cat.toUpperCase() == 'HOME' ? null : cat);
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: actif
                      ? const LinearGradient(
                          colors: [AppColors.vertPrimaire, Color(0xFF43A047)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: actif
                      ? null
                      : (isDark ? AppColors.surfaceSombre : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: actif
                        ? Colors.transparent
                        : (isDark ? Colors.white12 : Colors.black12),
                    width: 1.2,
                  ),
                  boxShadow: actif
                      ? [
                          BoxShadow(
                            color: AppColors.vertPrimaire.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(icone, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      cat.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: actif ? FontWeight.w900 : FontWeight.w700,
                        color: actif
                            ? Colors.white
                            : (isDark ? AppColors.texteSombreMoyen : AppColors.texteFort),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
