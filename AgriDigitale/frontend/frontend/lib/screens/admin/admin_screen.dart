//permet à l'administrateur de gérer les différentes sections de l'application, telles que les statistiques, les utilisateurs, les demandes et les bannières. Il peut également publier la météo et envoyer des notifications à tous les utilisateurs. L'interface est organisée en onglets pour faciliter la navigation entre les différentes sections.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import '../../providers/auth_provider.dart';
import '../../core/design/app_colors.dart';
import 'admin_meteo_screen.dart';
import 'admin_stats_tab.dart';
import 'admin_utilisateurs_tab.dart';
import 'admin_demandes_tab.dart';
import 'admin_bannieres_tab.dart';
import 'admin_prix_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final _service = AdminService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.vertPrimaire,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.wb_sunny, color: Colors.white),
            tooltip: 'Publier météo',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminMeteoScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.price_change_outlined, color: Colors.white),
            tooltip: 'Gérer prix des marchés',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminPrixScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.white),
            tooltip: 'Envoyer notification',
            onPressed: () => _dialogNotification(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
            Tab(icon: Icon(Icons.people), text: 'Utilisateurs'),
            Tab(icon: Icon(Icons.inbox), text: 'Demandes'),
            Tab(icon: Icon(Icons.image), text: 'Bannières'),
            Tab(icon: Icon(Icons.price_change_outlined), text: 'Prix'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AdminStatsTab(service: _service),
          AdminUtilisateursTab(service: _service, currentUserId: context.read<AuthProvider>().idUtilisateur ?? ''),
          AdminDemandesTab(service: _service),
          AdminBannieresTab(service: _service),
          const AdminPrixScreen(isTab: true),
        ],
      ),
    );
  }

  void _dialogNotification(BuildContext context) {
    final titreCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    bool envoi = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Envoyer une notification',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sera envoyée à TOUS les utilisateurs',
                          style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titreCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Titre *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: msgCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Message *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Annuler')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.vertPrimaire),
                      onPressed: envoi
                          ? null
                          : () async {
                              if (titreCtrl.text.trim().isEmpty ||
                                  msgCtrl.text.trim().isEmpty) {
                                return;
                              }
                              setS(() => envoi = true);
                              try {
                                final res =
                                    await _service.envoyerNotification(
                                  titre: titreCtrl.text.trim(),
                                  message: msgCtrl.text.trim(),
                                );
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(res['message'] ??
                                        'Notification envoyée'),
                                    backgroundColor: Colors.green,
                                  ));
                                }
                              } catch (e) {
                                setS(() => envoi = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Erreur lors de l\'envoi'),
                                        backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                      child: envoi
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Envoyer à tous',
                              style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
