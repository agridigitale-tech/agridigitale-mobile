import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../core/design/app_colors.dart';
import 'admin_widgets.dart';

class AdminUtilisateursTab extends StatefulWidget {
  final AdminService service;
  final String currentUserId;
  const AdminUtilisateursTab({super.key, required this.service, required this.currentUserId});

  @override
  State<AdminUtilisateursTab> createState() => _AdminUtilisateursTabState();
}

class _AdminUtilisateursTabState extends State<AdminUtilisateursTab> {
  List<dynamic> _users = [];
  bool _chargement = true;
  bool _erreur = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _chargement = true; _erreur = false; });
    try {
      final data = await widget.service.listerUtilisateurs();
      if (mounted) setState(() { _users = data; _chargement = false; });
    } catch (_) {
      if (mounted) setState(() { _chargement = false; _erreur = true; });
    }
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
            child: const Text('Désactiver', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.service.desactiverUtilisateur(id);
      await _charger();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Compte désactivé avec succès ✓'),
            backgroundColor: Colors.orange));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur : ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _promouvoir(String id, String nom) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Promouvoir en admin'),
        content: Text('Donner les droits administrateur à "$nom" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.vertPrimaire),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Promouvoir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.service.promouvoirAdmin(id);
      await _charger();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$nom est désormais administrateur'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur : ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _retrograder(String id, String nom) async {
    if (id == widget.currentUserId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Vous ne pouvez pas vous rétrograder vous-même'),
            backgroundColor: Colors.orange));
      }
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rétrograder l\'admin'),
        content: Text('Retirer les droits administrateur à "$nom" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rétrograder', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.service.retrograderAdmin(id);
      await _charger();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$nom a été rétrogradé en utilisateur'),
            backgroundColor: Colors.orange));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur : ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) return const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire));
    if (_erreur) return adminErreur(_charger);
    if (_users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 56, color: AppColors.grisIcone),
            SizedBox(height: 12),
            Text('Aucun utilisateur', style: TextStyle(color: AppColors.grisTexte)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _users.length,
        separatorBuilder: (context, i) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final u = _users[i];
          final actif = (u['actif'] as bool?) ?? true;
          final role = u['role'] ?? 'utilisateur';
          final pays = (u['pays'] as String?) ?? '';
          final continent = (u['continent'] as String?) ?? '';
          final geo = [pays, continent].where((s) => s.isNotEmpty).join(' • ');
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: role == 'administrateur' ? AppColors.vertPrimaire : AppColors.grisPastille,
              child: Text(
                ((u['nom'] as String?) ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                    color: role == 'administrateur' ? Colors.white : AppColors.grisTexte,
                    fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(u['nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u['email'] ?? '', style: const TextStyle(fontSize: 12)),
                if (geo.isNotEmpty)
                  Text(geo, style: const TextStyle(fontSize: 11, color: AppColors.grisTexte)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                adminBadgeStatut(actif),
                if (actif && role != 'administrateur') ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.shield_outlined, color: AppColors.vertPrimaire, size: 20),
                    tooltip: 'Promouvoir admin',
                    onPressed: () => _promouvoir(u['_id'], u['nom'] ?? ''),
                  ),
                  IconButton(
                    icon: const Icon(Icons.block, color: Colors.red, size: 20),
                    tooltip: 'Désactiver',
                    onPressed: () => _desactiver(u['_id'], u['nom'] ?? ''),
                  ),
                ],
                if (role == 'administrateur' && u['_id'] != widget.currentUserId) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.shield, color: Colors.orange, size: 20),
                    tooltip: 'Rétrograder',
                    onPressed: () => _retrograder(u['_id'], u['nom'] ?? ''),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
