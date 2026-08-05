// Vérifie si l'utilisateur est connecté avant une action protégée.
// Si non connecté, redirige vers LoginScreen au lieu de l'ancien BottomSheet.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';

/// Retourne true si déjà connecté.
/// Sinon, navigue vers LoginScreen et retourne false.
/// Tous les appelants existants (favoris, commentaires, demandes) fonctionnent sans changement.
Future<bool> exigerConnexion(BuildContext context, {String motif = 'continuer'}) async {
  final auth = context.read<AuthProvider>();
  if (auth.connecte) return true;

  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );

  // Après retour de LoginScreen, vérifier si l'utilisateur s'est connecté
  if (!context.mounted) return false;
  return context.read<AuthProvider>().connecte;
}
