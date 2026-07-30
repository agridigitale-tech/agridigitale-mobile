import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';

Widget adminErreur(VoidCallback onRetry) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wifi_off, size: 48, color: AppColors.grisIcone),
        const SizedBox(height: 12),
        const Text('Erreur de chargement'),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.vertPrimaire),
          child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

Widget adminCarteChiffre(IconData icone, String valeur, String label, Color couleur) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icone, color: couleur, size: 28),
      const SizedBox(height: 8),
      Text(valeur,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: couleur)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.grisTexte)),
    ]),
  );
}

Widget adminBadgeStatut(bool actif) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: actif
          ? Colors.green.withValues(alpha: 0.1)
          : Colors.red.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      actif ? 'Actif' : 'Inactif',
      style: TextStyle(
        fontSize: 11,
        color: actif ? Colors.green : Colors.red,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
