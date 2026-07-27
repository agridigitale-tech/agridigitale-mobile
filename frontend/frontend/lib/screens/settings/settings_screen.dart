import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/auth_gate.dart';
import '../../core/design/app_colors.dart';
import '../../core/app_localizations.dart';
import 'detail_settings/about_screen.dart';
import 'detail_settings/notifications_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _ligne(BuildContext context, IconData icone, String titre,
      {String? sousTitre, VoidCallback? onTap, Color? couleurTitre}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: AppColors.grisPastille,
            radius: 18,
            child: Icon(icone, color: AppColors.grisIcone, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(titre,
                style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: couleurTitre)),
          ),
          if (sousTitre != null)
            Text(sousTitre, style: const TextStyle(color: AppColors.grisTexte)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.grisIcone, size: 18),
        ]),
      ),
    );
  }

  void _partagerApplication() {
    Share.share(
      'Utilisez l\'application Agridigitale pour rester informé en temps réel sur l\'information agricole !\n\nTéléchargez-la ici : https://play.google.com/store/apps/details?id=com.agridigitale',
      subject: 'Découvrez Agridigitale',
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
          title: Text(l.t('settings'),
              style: Theme.of(context).textTheme.titleLarge)),
      body: ListView(
        children: [
          // Carte profil utilisateur
          if (auth.connecte) ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.vertPrimaire.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.vertPrimaire.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.vertPrimaire,
                  child: Text(
                    (auth.nomUtilisateur ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.nomUtilisateur ?? 'Utilisateur',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      if (auth.emailUtilisateur != null)
                        Text(
                          auth.emailUtilisateur!,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
              ]),
            ),
            const Divider(height: 1),
          ],

          if (!auth.connecte)
            _ligne(context, Icons.login, l.t('login_create'),
                onTap: () =>
                    exigerConnexion(context, motif: 'accéder à ton profil')),

          if (auth.connecte)
            _ligne(context, Icons.logout, l.t('logout'),
                couleurTitre: Colors.red,
                onTap: () async => await auth.deconnecter()),

          const Divider(height: 1),

          // Bouton bascule thème sombre / clair
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              final estSombre = themeProvider.mode == ThemeMode.dark;
              return _ligne(
                context,
                estSombre ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                estSombre ? 'Thème sombre' : 'Thème clair',
                sousTitre: estSombre ? '🌙 Sombre' : '☀️ Clair',
                onTap: () => themeProvider.basculer(),
              );
            },
          ),
          const Divider(height: 1),

          // Langue
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              final currentLang = languageProvider.locale.languageCode == 'fr'
                  ? '🇫🇷 Français'
                  : '🇬🇧 English';
              return _ligne(context, Icons.translate, l.t('language'),
                  sousTitre: currentLang,
                  onTap: () => languageProvider.basculerLangue());
            },
          ),
          const Divider(height: 1),

          // Notifications
          _ligne(
            context,
            Icons.notifications_outlined,
            'Notifications',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationsScreen()),
            ),
          ),
          const Divider(height: 1),

          // Partager
          _ligne(
            context,
            Icons.share_outlined,
            l.t('share'),
            onTap: _partagerApplication,
          ),
          const Divider(height: 1),

          // Noter
          _ligne(
            context,
            Icons.star_border,
            l.t('rate'),
            onTap: () {},
          ),
          const Divider(height: 1),

          // À propos
          _ligne(
            context,
            Icons.info_outline,
            l.t('about'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
          const Divider(height: 1),

          const SizedBox(height: 40),
          Container(
            width: double.infinity,
            color: const Color(0xFFF3F3F3),
            padding: const EdgeInsets.all(20),
            child: const Text('Copyright © 2026 Agridigitale',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.vertPrimaire)),
          ),
        ],
      ),
    );
  }
}
