import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../core/design/app_colors.dart';
import 'admin_widgets.dart';

class AdminDemandesTab extends StatefulWidget {
  final AdminService service;
  const AdminDemandesTab({super.key, required this.service});

  @override
  State<AdminDemandesTab> createState() => _AdminDemandesTabState();
}

class _AdminDemandesTabState extends State<AdminDemandesTab> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.listerDemandes();
  }

  Future<void> _reload() async {
    setState(() => _future = widget.service.listerDemandes());
  }

  Future<void> _traiter(String id) async {
    try {
      await widget.service.traiterDemande(id);
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Demande marquée comme traitée ✓'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint('[Admin] traiterDemande erreur: $e');
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

        final demandes = snap.data!;
        if (demandes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 56, color: AppColors.grisIcone),
                SizedBox(height: 12),
                Text('Aucune demande',
                    style: TextStyle(color: AppColors.grisTexte)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: demandes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = demandes[i];
              final traite = d['statut'] == 'TRAITE';
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: traite
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(d['nomComplet'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14))),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: traite
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          traite ? 'Traité' : 'En attente',
                          style: TextStyle(
                              fontSize: 11,
                              color: traite ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                        '${d['profession'] ?? ''} • ${d['email'] ?? ''}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.grisTexte)),
                    if ((d['telephone'] ?? '').isNotEmpty)
                      Text(d['telephone'],
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.grisTexte)),
                    const SizedBox(height: 8),
                    Text(d['message'] ?? '',
                        style: const TextStyle(fontSize: 13, height: 1.4)),
                    if (!traite) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => _traiter(d['_id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.vertPrimaire,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                          ),
                          icon: const Icon(Icons.check,
                              color: Colors.white, size: 16),
                          label: const Text('Marquer traité',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ),
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
