// Écran paramètres : profil utilisateur, thème, langue, notifications, partage, à propos.
// Affiche un bouton connexion si non connecté, ou le profil + déconnexion si connecté.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../screens/auth/login_screen.dart';
import '../../core/design/app_colors.dart';
import '../../core/app_localizations.dart';
import 'detail_settings/about_screen.dart';
import 'detail_settings/contact_screen.dart';
import 'detail_settings/notifications_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Construit une ligne de paramètre avec icône (Material ou FontAwesome), titre et chevron
  Widget _ligne(BuildContext context, IconData icone, String titre,
      {String? sousTitre, VoidCallback? onTap, Color? couleurTitre, bool isFa = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: AppColors.grisPastille,
            radius: 18,
            child: isFa
                ? FaIcon(icone, color: AppColors.grisIcone, size: 16)
                : Icon(icone, color: AppColors.grisIcone, size: 18),
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

  // Confirmation puis suppression définitive du compte (conformité Google Play)
  Future<void> _supprimerCompte(BuildContext context) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 10),
          Expanded(child: Text('Supprimer le compte ?', style: TextStyle(fontSize: 18))),
        ]),
        content: const Text(
          'Cette action est irréversible. Votre compte ainsi que toutes vos données '
          '(favoris, commentaires, notifications, demandes) seront définitivement supprimés.\n\n'
          'Voulez-vous vraiment continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
    if (confirme != true || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    final service = AuthService();
    try {
      await service.supprimerCompte();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre compte et vos données ont été supprimés'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      final message = e is Exception && e.toString().contains('message:')
          ? e.toString().split('message: ').last.replaceAll('Exception', '').trim()
          : 'Erreur lors de la suppression. Vérifiez votre connexion.';
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      await auth.deconnecter();
    }
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                )),

          if (auth.connecte)
            _ligne(context, Icons.logout, l.t('logout'),
                couleurTitre: Colors.red,
                onTap: () async => await auth.deconnecter()),

          if (auth.connecte)
            _ligne(
              context,
              Icons.delete_forever_outlined,
              'Supprimer mon compte',
              sousTitre: 'Effacer mes données',
              couleurTitre: Colors.red.shade700,
              onTap: () => _supprimerCompte(context),
            ),

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
            FontAwesomeIcons.shareNodes,
            l.t('share'),
            isFa: true,
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

          // Contactez-nous (conformité Google Play : contact visible en texte brut)
          _ligne(
            context,
            Icons.mail_outline,
            'Contactez-nous',
            sousTitre: 'Email, téléphone',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactScreen()),
            ),
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
