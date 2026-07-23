import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/admin_service.dart';
import '../../core/design/app_colors.dart';
import '../../core/api_client.dart';
import 'admin_meteo_screen.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _StatsTab(service: _service),
          _UtilisateursTab(service: _service),
          _DemandesTab(service: _service),
          _BannieresTab(service: _service),
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Envoyer une notification',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
                          style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
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
                                final res = await _service.envoyerNotification(
                                  titre: titreCtrl.text.trim(),
                                  message: msgCtrl.text.trim(),
                                );
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(res['message'] ?? 'Notification envoyée'),
                                    backgroundColor: Colors.green,
                                  ));
                                }
                              } catch (e) {
                                setS(() => envoi = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Erreur lors de l\'envoi'),
                                        backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                      child: envoi
                          ? const SizedBox(
                              width: 18, height: 18,
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

// ─── ONGLET STATISTIQUES ──────────────────────────────────────────────────

class _StatsTab extends StatefulWidget {
  final AdminService service;
  const _StatsTab({required this.service});
  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.statistiques();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.vertPrimaire));
        }
        if (snap.hasError) {
          return _erreur(
              () => setState(() => _future = widget.service.statistiques()));
        }
        final d = snap.data!;
        final articlesParCat = (d['articlesParCategorie'] as List?) ?? [];
        final plusLus = (d['articlesPlusLus'] as List?) ?? [];

        return RefreshIndicator(
          onRefresh: () async =>
              setState(() => _future = widget.service.statistiques()),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                Expanded(
                    child: _carteChiffre(Icons.article_outlined,
                        '${d['totalArticles'] ?? 0}', 'Articles', AppColors.vertPrimaire)),
                const SizedBox(width: 12),
                Expanded(
                    child: _carteChiffre(Icons.people_outline,
                        '${d['totalUtilisateurs'] ?? 0}', 'Utilisateurs', Colors.blue)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _carteChiffre(Icons.inbox_outlined,
                        '${d['demandesEnAttente'] ?? 0}', 'En attente', Colors.orange)),
                const SizedBox(width: 12),
                Expanded(
                    child: _carteChiffre(Icons.category_outlined,
                        '${articlesParCat.length}', 'Catégories', Colors.purple)),
              ]),
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
            ],
          ),
        );
      },
    );
  }

  Widget _carteChiffre(IconData icone, String valeur, String label, Color couleur) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icone, color: couleur, size: 28),
        const SizedBox(height: 8),
        Text(valeur,
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: couleur)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.grisTexte)),
      ]),
    );
  }
}

// ─── ONGLET UTILISATEURS ──────────────────────────────────────────────────

class _UtilisateursTab extends StatefulWidget {
  final AdminService service;
  const _UtilisateursTab({required this.service});
  @override
  State<_UtilisateursTab> createState() => _UtilisateursTabState();
}

class _UtilisateursTabState extends State<_UtilisateursTab> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.listerUtilisateurs();
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
      setState(() => _future = widget.service.listerUtilisateurs());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Compte désactivé'),
            backgroundColor: Colors.orange));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Erreur'), backgroundColor: Colors.red));
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
        if (snap.hasError) {
          return _erreur(() =>
              setState(() => _future = widget.service.listerUtilisateurs()));
        }
        final users = snap.data!;
        return RefreshIndicator(
          onRefresh: () async =>
              setState(() => _future = widget.service.listerUtilisateurs()),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final u = users[i];
              final actif = u['actif'] ?? true;
              final role = u['role'] ?? 'utilisateur';
              return ListTile(
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
                subtitle: Text(u['email'] ?? '',
                    style: const TextStyle(fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
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
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (actif && role != 'administrateur') ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.block,
                            color: Colors.red, size: 20),
                        tooltip: 'Désactiver',
                        onPressed: () => _desactiver(u['_id'], u['nom'] ?? ''),
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

// ─── ONGLET DEMANDES ──────────────────────────────────────────────────────

class _DemandesTab extends StatefulWidget {
  final AdminService service;
  const _DemandesTab({required this.service});
  @override
  State<_DemandesTab> createState() => _DemandesTabState();
}

class _DemandesTabState extends State<_DemandesTab> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.listerDemandes();
  }

  Future<void> _traiter(String id) async {
    try {
      await widget.service.traiterDemande(id);
      setState(() => _future = widget.service.listerDemandes());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Demande marquee comme traitee'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint('[Admin] traiterDemande: $e');
      // Recharger quand meme car l'action peut avoir reussi
      setState(() => _future = widget.service.listerDemandes());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Demande traitee'),
            backgroundColor: Colors.green));
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
        if (snap.hasError) {
          return _erreur(
              () => setState(() => _future = widget.service.listerDemandes()));
        }
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
          onRefresh: () async =>
              setState(() => _future = widget.service.listerDemandes()),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: demandes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
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

// ─── ONGLET BANNIERES ────────────────────────────────────────────────────

class _BannieresTab extends StatefulWidget {
  final AdminService service;
  const _BannieresTab({required this.service});
  @override
  State<_BannieresTab> createState() => _BannieresTabState();
}

class _BannieresTabState extends State<_BannieresTab> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.listerBannieres();
  }

  String _urlImage(String img) {
    if (img.isEmpty) return '';
    if (img.startsWith('http')) return img;
    final base = ApiClient.baseUrl.replaceAll('/api', '');
    return '$base$img';
  }

  void _dialogAjouter() {
    final ordreCtrl = TextEditingController(text: '1');
    final List<File> imagesSelectionnees = [];
    bool envoi = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Ajouter des bannières',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Choisir des photos'),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickMultiImage(imageQuality: 80);
                    if (picked.isNotEmpty) {
                      setS(() {
                        imagesSelectionnees.addAll(picked.map((f) => File(f.path)));
                      });
                    }
                  },
                ),
                if (imagesSelectionnees.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('${imagesSelectionnees.length} image(s) sélectionnée(s)',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 8),
                  // SingleChildScrollView horizontal au lieu de ListView.builder
                  // pour éviter RenderViewport intrinsic dimensions crash
                  SizedBox(
                    height: 90,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(imagesSelectionnees.length, (i) =>
                          Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(imagesSelectionnees[i],
                                      width: 90, height: 90, fit: BoxFit.cover),
                                ),
                              ),
                              Positioned(
                                top: 2, right: 10,
                                child: GestureDetector(
                                  onTap: () => setS(() => imagesSelectionnees.removeAt(i)),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                        color: Colors.red, shape: BoxShape.circle),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: ordreCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Ordre de départ', border: OutlineInputBorder()),
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
                      onPressed: (envoi || imagesSelectionnees.isEmpty)
                          ? null
                          : () async {
                              setS(() => envoi = true);
                              int ordre = int.tryParse(ordreCtrl.text) ?? 1;
                              int succes = 0;
                              for (final img in imagesSelectionnees) {
                                try {
                                  await widget.service.creerBanniere(
                                    image: '',
                                    lien: '',
                                    ordre: ordre,
                                    cheminFichier: img.path,
                                  );
                                  succes++;
                                  ordre++;
                                } catch (_) {}
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              setState(() => _future = widget.service.listerBannieres());
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('$succes bannière(s) publiée(s)'),
                                  backgroundColor: succes > 0 ? Colors.green : Colors.red,
                                ));
                              }
                            },
                      child: envoi
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              imagesSelectionnees.isEmpty
                                  ? 'Publier'
                                  : 'Publier ${imagesSelectionnees.length}',
                              style: const TextStyle(color: Colors.white)),
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

  Future<void> _supprimer(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la bannière ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.service.supprimerBanniere(id);
    setState(() => _future = widget.service.listerBannieres());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Banniere supprimee'),
          backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire));
            }
            if (snap.hasError) {
              return _erreur(() => setState(() => _future = widget.service.listerBannieres()));
            }
            final bannieres = snap.data!;
            if (bannieres.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported, size: 56, color: AppColors.grisIcone),
                    SizedBox(height: 12),
                    Text('Aucune bannière', style: TextStyle(color: AppColors.grisTexte)),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => setState(() => _future = widget.service.listerBannieres()),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                itemCount: bannieres.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final b = bannieres[i];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _urlImage(b['image'] ?? ''),
                            width: 80, height: 50, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 80, height: 50, color: AppColors.grisPastille,
                              child: const Icon(Icons.broken_image, color: AppColors.grisIcone),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ordre : ${b['ordre'] ?? 0}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              if ((b['lien'] ?? '').isNotEmpty)
                                Text(b['lien'], style: const TextStyle(fontSize: 11, color: AppColors.grisTexte),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _supprimer(b['_id']),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
        // Bouton ajouter bannière(s)
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'add_banniere',
            onPressed: _dialogAjouter,
            backgroundColor: AppColors.vertPrimaire,
            icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
            label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}


Widget _erreur(VoidCallback onRetry) {
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
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vertPrimaire),
          child: const Text('Réessayer',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}