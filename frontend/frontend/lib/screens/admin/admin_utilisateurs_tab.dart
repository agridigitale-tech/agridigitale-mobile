import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../core/design/app_colors.dart';
import 'admin_widgets.dart';

class AdminUtilisateursTab extends StatefulWidget {
  final AdminService service;
  const AdminUtilisateursTab({super.key, required this.service});

  @override
  State<AdminUtilisateursTab> createState() => _AdminUtilisateursTabState();
}

class _AdminUtilisateursTabState extends State<AdminUtilisateursTab> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.listerUtilisateurs();
  }

  Future<void> _reload() async {
    setState(() => _future = widget.service.listerUtilisateurs());
  }

  Future<void> _desactiver(String id, String nom) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Désactiver le compte'),
        content: Text('Désactiver le compte de "$nom" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Désactiver',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.service.desactiverUtilisateur(id);
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Compte désactivé avec succès ✓'),
            backgroundColor: Colors.orange));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Erreur : ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.vertPrimaire));
        }
        if (snap.hasError) return adminErreur(_reload);

        final users = snap.data!;
        if (users.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 56, color: AppColors.grisIcone),
                SizedBox(height: 12),
                Text('Aucun utilisateur',
                    style: TextStyle(color: AppColors.grisTexte)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final u = users[i];
              final actif = (u['actif'] as bool?) ?? true;
              final role = u['role'] ?? 'utilisateur';
              final pays = (u['pays'] as String?) ?? '';
              final continent = (u['continent'] as String?) ?? '';
              final geo = [pays, continent]
                  .where((s) => s.isNotEmpty)
                  .join(' • ');

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: role == 'administrateur'
                      ? AppColors.vertPrimaire
                      : AppColors.grisPastille,
                  child: Text(
                    ((u['nom'] as String?) ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                        color: role == 'administrateur'
                            ? Colors.white
                            : AppColors.grisTexte,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(u['nom'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u['email'] ?? '',
                        style: const TextStyle(fontSize: 12)),
                    if (geo.isNotEmpty)
                      Text(geo,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.grisTexte)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    adminBadgeStatut(actif),
                    if (actif && role != 'administrateur') ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.block,
                            color: Colors.red, size: 20),
                        tooltip: 'Désactiver',
                        onPressed: () =>
                            _desactiver(u['_id'], u['nom'] ?? ''),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
