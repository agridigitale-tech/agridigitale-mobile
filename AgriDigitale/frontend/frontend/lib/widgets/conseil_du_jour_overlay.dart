// Overlay pop-up "Conseil du Jour" affiché chaque matin en superposition sur l'écran.
// Affiche la citation agronomique du jour en mode Glassmorphisme avec griffes et typographie élégante.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/conseils_data.dart';
import 'conseil_du_jour_card.dart';

class ConseilDuJourOverlay extends StatefulWidget {
  final ConseilAgricole conseil;
  final VoidCallback? onFermer;

  const ConseilDuJourOverlay({
    super.key,
    required this.conseil,
    this.onFermer,
  });

  static const String _kKeyDernierConseilDate = 'dernier_popup_conseil_date';

  /// Affiche l'overlay automatiquement le matin au premier lancement de la journée
  static Future<bool> afficherSiNouveauMatin(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final aujourdhui = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final derniereDate = prefs.getString(_kKeyDernierConseilDate);

      if (derniereDate != aujourdhui) {
        await prefs.setString(_kKeyDernierConseilDate, aujourdhui);
        if (context.mounted) {
          afficher(context);
          return true;
        }
      }
    } catch (e) {
      debugPrint('[ConseilDuJourOverlay] Erreur vérification date matin: $e');
    }
    return false;
  }

  /// Affiche l'overlay manuellement à l'écran
  static void afficher(BuildContext context, [ConseilAgricole? conseilPersonnalise]) {
    final c = conseilPersonnalise ?? ConseilsData.getConseilDuJour();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fermer le conseil du jour',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim1, anim2) {
        return ConseilDuJourOverlay(
          conseil: c,
          onFermer: () => Navigator.of(ctx).pop(),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6 * anim1.value, sigmaY: 6 * anim1.value),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curve),
            child: FadeTransition(
              opacity: anim1,
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  State<ConseilDuJourOverlay> createState() => _ConseilDuJourOverlayState();
}

class _ConseilDuJourOverlayState extends State<ConseilDuJourOverlay> {
  void _fermer() {
    if (widget.onFermer != null) {
      widget.onFermer!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          constraints: const BoxConstraints(maxWidth: 420),
          child: ConseilDuJourCard(
            conseil: widget.conseil,
            onFermer: _fermer,
            margin: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
