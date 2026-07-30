import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../core/design/app_colors.dart';
import 'admin_widgets.dart';

class AdminStatsTab extends StatefulWidget {
  final AdminService service;
  const AdminStatsTab({super.key, required this.service});

  @override
  State<AdminStatsTab> createState() => _AdminStatsTabState();
}

class _AdminStatsTabState extends State<AdminStatsTab> {
  late Future<Map<String, dynamic>> _futureStats;
  late Future<List<dynamic>> _futureUsers;

  @override
  void initState() {
    super.initState();
    _futureStats = widget.service.statistiques();
    _futureUsers = widget.service.listerUtilisateurs();
  }

  Future<void> _reload() async {
    setState(() {
      _futureStats = widget.service.statistiques();
      _futureUsers = widget.service.listerUtilisateurs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_futureStats, _futureUsers]),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.vertPrimaire));
        }
        if (snap.hasError) return adminErreur(_reload);

        final d = snap.data![0] as Map<String, dynamic>;
        final users = snap.data![1] as List<dynamic>;
        final articlesParCat = (d['articlesParCategorie'] as List?) ?? [];
        final plusLus = (d['articlesPlusLus'] as List?) ?? [];
        final parPays = (d['parPays'] as List?) ?? [];
        final parContinent = (d['parContinent'] as List?) ?? [];

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── KPIs ──
              Row(children: [
                Expanded(
                    child: adminCarteChiffre(Icons.article_outlined,
                        '${d['totalArticles'] ?? 0}', 'Articles', AppColors.vertPrimaire)),
                const SizedBox(width: 12),
                Expanded(
                    child: adminCarteChiffre(Icons.people_outline,
                        '${d['totalUtilisateurs'] ?? 0}', 'Utilisateurs', Colors.blue)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: adminCarteChiffre(Icons.inbox_outlined,
                        '${d['demandesEnAttente'] ?? 0}', 'En attente', Colors.orange)),
                const SizedBox(width: 12),
                Expanded(
                    child: adminCarteChiffre(Icons.category_outlined,
                        '${articlesParCat.length}', 'Catégories', Colors.purple)),
              ]),

              // ── Top 5 articles ──
              if (plusLus.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Top 5 articles les plus lus',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...List.generate(plusLus.length, (i) {
                  final a = plusLus[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6)
                      ],
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        backgroundColor: AppColors.vertPrimaire,
                        radius: 14,
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(a['titre'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13))),
                      const SizedBox(width: 8),
                      Row(children: [
                        const Icon(Icons.remove_red_eye,
                            size: 14, color: AppColors.grisIcone),
                        const SizedBox(width: 4),
                        Text('${a['vues'] ?? 0}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.grisTexte)),
                      ]),
                    ]),
                  );
                }),
              ],

              // ── Articles par catégorie ──
              if (articlesParCat.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Articles par catégorie',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...articlesParCat.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Expanded(
                            child: Text(c['_id'] ?? 'Non classé',
                                style: const TextStyle(fontSize: 13))),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.vertPrimaire.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${c['total']}',
                              style: const TextStyle(
                                  color: AppColors.vertPrimaire,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      ]),
                    )),
              ],

              // ── Répartition par pays ──
              _sectionGeo('Utilisateurs par pays', parPays),

              // ── Répartition par continent ──
              _sectionGeo('Utilisateurs par continent', parContinent),

              // ── Profils utilisateurs ──
              if (users.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Profils utilisateurs',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...users.map((u) => _carteUtilisateur(u)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _carteUtilisateur(Map<String, dynamic> u) {
    final actif = u['actif'] as bool? ?? true;
    final role = u['role'] as String? ?? 'utilisateur';
    final pays = (u['pays'] as String?) ?? '';
    final continent = (u['continent'] as String?) ?? '';
    final geo = [pays, continent].where((s) => s.isNotEmpty).join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)
        ],
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: role == 'administrateur'
              ? AppColors.vertPrimaire
              : AppColors.grisPastille,
          radius: 20,
          child: Text(
            ((u['nom'] as String?) ?? 'U')[0].toUpperCase(),
            style: TextStyle(
              color: role == 'administrateur' ? Colors.white : AppColors.grisTexte,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u['nom'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(u['email'] ?? '',
                style: const TextStyle(fontSize: 11, color: AppColors.grisTexte)),
            if (geo.isNotEmpty)
              Text(geo,
                  style: const TextStyle(fontSize: 11, color: AppColors.grisTexte)),
          ]),
        ),
        adminBadgeStatut(actif),
      ]),
    );
  }

  Widget _sectionGeo(String titre, List<dynamic> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(titre,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...items.map((c) {
          final label = (c['_id'] == null || (c['_id'] as String).isEmpty)
              ? 'Non renseigné'
              : c['_id'] as String;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              const Icon(Icons.place_outlined,
                  size: 16, color: AppColors.grisIcone),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(label, style: const TextStyle(fontSize: 13))),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${c['total']}',
                    style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ]),
          );
        }),
      ],
    );
  }
}
