//permet d'afficher les paramètres de l'application et gérer la connexion de l'utilisateur

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_gate.dart';
import '../../core/design/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _ligne(BuildContext context, IconData icone, String titre, {String? sousTitre, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          CircleAvatar(backgroundColor: AppColors.grisPastille, radius: 18,
            child: Icon(icone, color: AppColors.grisIcone, size: 18)),
          const SizedBox(width: 16),
          Expanded(child: Text(titre, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600))),
          if (sousTitre != null) Text(sousTitre, style: const TextStyle(color: AppColors.grisTexte)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: Text('settings', style: Theme.of(context).textTheme.displaySmall)),
      body: ListView(
        children: [
          if (!auth.connecte)
            _ligne(context, Icons.login, 'Se connecter / Créer un compte',
              onTap: () => exigerConnexion(context, motif: "accéder à ton profil")),
          if (auth.connecte)
            _ligne(context, Icons.logout, 'Déconnexion', onTap: () => auth.deconnecter()),
          const Divider(height: 1),
          _ligne(context, Icons.translate, 'Language', sousTitre: 'Français'),
          const Divider(height: 1),
          _ligne(context, Icons.share_outlined, 'Share Agridigitale'),
          const Divider(height: 1),
          _ligne(context, Icons.star_border, 'Rate Agridigitale'),
          const Divider(height: 1),
          _ligne(context, Icons.info_outline, 'About'),
          const Divider(height: 1),
          _ligne(context, Icons.notifications_none, 'Notification Management'),
          const Divider(height: 1),
          const SizedBox(height: 40),
          Container(
            width: double.infinity, color: const Color(0xFFF3F3F3),
            padding: const EdgeInsets.all(20),
            child: const Text('Copyright © 2026 Agridigitale', textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.vertPrimaire)),
          ),
        ],
      ),
    );
  }
}