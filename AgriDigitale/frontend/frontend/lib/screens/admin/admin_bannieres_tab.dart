import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../core/design/app_colors.dart';
import '../../core/api_client.dart';
import 'admin_widgets.dart';
import '../../widgets/banner_carousel.dart';

// Retourne le statut d'une bannière selon ses dates et son état actif
_StatutBanniere _statut(Map<String, dynamic> b) {
  if (b['actif'] != true) return _StatutBanniere.inactive;
  final now = DateTime.now();
  final debut = b['dateDebut'] != null ? DateTime.tryParse(b['dateDebut']) : null;
  final fin = b['dateFin'] != null ? DateTime.tryParse(b['dateFin']) : null;
  if (fin != null && now.isAfter(fin)) return _StatutBanniere.expiree;
  if (debut != null && now.isBefore(debut)) return _StatutBanniere.aVenir;
  return _StatutBanniere.active;
}

enum _StatutBanniere { active, expiree, aVenir, inactive }

extension _StatutExt on _StatutBanniere {
  String get label {
    switch (this) {
      case _StatutBanniere.active:   return 'Active';
      case _StatutBanniere.expiree:  return 'Expirée';
      case _StatutBanniere.aVenir:   return 'À venir';
      case _StatutBanniere.inactive: return 'Inactive';
    }
  }
  Color get couleur {
    switch (this) {
      case _StatutBanniere.active:   return Colors.green;
      case _StatutBanniere.expiree:  return Colors.red;
      case _StatutBanniere.aVenir:   return Colors.orange;
      case _StatutBanniere.inactive: return Colors.grey;
    }
  }
}

class AdminBannieresTab extends StatefulWidget {
  final AdminService service;
  const AdminBannieresTab({super.key, required this.service});

  @override
  State<AdminBannieresTab> createState() => _AdminBannieresTabState();
}

class _AdminBannieresTabState extends State<AdminBannieresTab> {
  List<dynamic> _bannieres = [];
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
      final data = await widget.service.listerBannieres();
      if (mounted) setState(() { _bannieres = data; _chargement = false; });
    } catch (_) {
      if (mounted) setState(() { _chargement = false; _erreur = true; });
    }
  }

  String _urlImage(String img) {
    if (img.isEmpty) return '';
    if (img.startsWith('http')) return img;
    final base = ApiClient.baseUrl.replaceAll('/api', '');
    return '$base$img';
  }

  void _dialogAjouter() {
    final ordreCtrl = TextEditingController(text: '1');
    final lienCtrl = TextEditingController();
    final List<File> images = [];
    DateTime dateDebut = DateTime.now();
    DateTime dateFin = DateTime.now().add(const Duration(days: 30));
    bool envoi = false;
    String? erreurDate;
    final fmt = DateFormat('dd/MM/yyyy');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Ajouter des bannières',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),

                // ── Sélection images ──
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Choisir des photos'),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickMultiImage(
                      imageQuality: 80,
                      requestFullMetadata: false, // Photo Picker natif Android 13+
                    );
                    if (picked.isNotEmpty) {
                      setS(() =>
                          images.addAll(picked.map((f) => File(f.path))));
                    }
                  },
                ),
                if (images.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('${images.length} image(s) sélectionnée(s)',
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 90,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(images.length, (i) => Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(images[i],
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 10,
                              child: GestureDetector(
                                onTap: () =>
                                    setS(() => images.removeAt(i)),
                                child: Container(
                                  decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        )),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),

                // ── Lien ──
                TextField(
                  controller: lienCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                      labelText: 'Lien (optionnel)',
                      hintText: 'https://...',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),

                // ── Ordre ──
                TextField(
                  controller: ordreCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Ordre de départ',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),

                // ── Date début ──
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today,
                      color: AppColors.vertPrimaire),
                  title: const Text('Date de début',
                      style: TextStyle(fontSize: 13)),
                  subtitle: Text(fmt.format(dateDebut),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dateDebut,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setS(() { dateDebut = picked; erreurDate = null; });
                  },
                ),

                // ── Date fin ──
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event, color: Colors.orange),
                  title: const Text('Date de fin',
                      style: TextStyle(fontSize: 13)),
                  subtitle: Text(fmt.format(dateFin),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dateFin.isAfter(dateDebut) ? dateFin : dateDebut.add(const Duration(days: 1)),
                      firstDate: dateDebut.add(const Duration(days: 1)), // min = lendemain du début
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setS(() { dateFin = picked; erreurDate = null; });
                  },
                ),

                // Message d'erreur date
                if (erreurDate != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(erreurDate!,
                        style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                const SizedBox(height: 16),

                // ── Boutons ──
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
                      onPressed: (envoi || images.isEmpty)
                          ? null
                          : () async {
                              // Validation date
                              if (!dateFin.isAfter(dateDebut)) {
                                setS(() => erreurDate = 'La date de fin doit être après la date de début');
                                return;
                              }
                              setS(() => envoi = true);
                              int ordre = int.tryParse(ordreCtrl.text) ?? 1;
                              int succes = 0;
                              for (final img in images) {
                                try {
                                  await widget.service.creerBanniere(
                                    image: '',
                                    lien: lienCtrl.text.trim(),
                                    ordre: ordre,
                                    cheminFichier: img.path,
                                    dateDebut: dateDebut,
                                    dateFin: dateFin,
                                  );
                                  succes++;
                                  ordre++;
                                } catch (_) {}
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (succes > 0) {
                                BannerCarousel.actualiser();
                              }
                              if (mounted) {
                                await _charger();
                                if (!mounted) return;
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
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
                              images.isEmpty ? 'Publier' : 'Publier ${images.length}',
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

  // Dialog pour modifier les dates, l'ordre et le lien d'une bannière existante
  void _dialogModifier(Map<String, dynamic> b) {
    final lienCtrl = TextEditingController(text: b['lien'] ?? '');
    final ordreCtrl = TextEditingController(text: '${b['ordre'] ?? 0}');
    DateTime dateDebut = b['dateDebut'] != null ? DateTime.parse(b['dateDebut']) : DateTime.now();
    DateTime dateFin = b['dateFin'] != null ? DateTime.parse(b['dateFin']) : DateTime.now().add(const Duration(days: 30));
    bool envoi = false;
    String? erreurDate;
    final fmt = DateFormat('dd/MM/yyyy');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Modifier la bannière',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),

                TextField(
                  controller: lienCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                      labelText: 'Lien (optionnel)',
                      hintText: 'https://...',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ordreCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Ordre',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, color: AppColors.vertPrimaire),
                  title: const Text('Date de début', style: TextStyle(fontSize: 13)),
                  subtitle: Text(fmt.format(dateDebut),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dateDebut,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setS(() { dateDebut = picked; erreurDate = null; });
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event, color: Colors.orange),
                  title: const Text('Date de fin', style: TextStyle(fontSize: 13)),
                  subtitle: Text(fmt.format(dateFin),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dateFin.isAfter(dateDebut) ? dateFin : dateDebut.add(const Duration(days: 1)),
                      firstDate: dateDebut.add(const Duration(days: 1)),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setS(() { dateFin = picked; erreurDate = null; });
                  },
                ),

                if (erreurDate != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(erreurDate!,
                        style: const TextStyle(color: Colors.red, fontSize: 12)),
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
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.vertPrimaire),
                      onPressed: envoi ? null : () async {
                        // Validation date
                        if (!dateFin.isAfter(dateDebut)) {
                          setS(() => erreurDate = 'La date de fin doit être après la date de début');
                          return;
                        }
                        setS(() => envoi = true);
                        try {
                          await widget.service.modifierBanniere(
                            id: b['_id'],
                            dateDebut: dateDebut,
                            dateFin: dateFin,
                            ordre: int.tryParse(ordreCtrl.text) ?? 0,
                            lien: lienCtrl.text.trim(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          BannerCarousel.actualiser();
                          await _charger();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bannière mise à jour'), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          setS(() { envoi = false; erreurDate = e.toString(); });
                        }
                      },
                      child: envoi
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Enregistrer', style: TextStyle(color: Colors.white)),
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
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.service.supprimerBanniere(id);
      BannerCarousel.actualiser();
      await _charger();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Bannière supprimée'),
            backgroundColor: Colors.green));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy');
    return Stack(
      children: [
        if (_chargement)
          const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire))
        else if (_erreur)
          adminErreur(_charger)
        else if (_bannieres.isEmpty)
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported, size: 56, color: AppColors.grisIcone),
                SizedBox(height: 12),
                Text('Aucune bannière', style: TextStyle(color: AppColors.grisTexte)),
              ],
            ),
          )
        else
          RefreshIndicator(
            onRefresh: _charger,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount: _bannieres.length,
              separatorBuilder: (context, i) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final b = _bannieres[i];
                final debut = b['dateDebut'] != null ? fmt.format(DateTime.parse(b['dateDebut'])) : '—';
                final fin = b['dateFin'] != null ? fmt.format(DateTime.parse(b['dateFin'])) : '—';
                final st = _statut(b);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
                  ),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _urlImage(b['image'] ?? ''),
                        width: 80, height: 50, fit: BoxFit.cover,
                        errorBuilder: (ctx, e, s) => Container(
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
                          Row(
                            children: [
                              Text('Ordre : ${b['ordre'] ?? 0}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 8),
                              // Badge statut visuel
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: st.couleur.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: st.couleur.withValues(alpha: 0.4)),
                                ),
                                child: Text(st.label,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: st.couleur)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('$debut → $fin',
                              style: const TextStyle(fontSize: 11, color: AppColors.grisTexte)),
                          if ((b['lien'] ?? '').isNotEmpty)
                            Text(b['lien'],
                                style: const TextStyle(fontSize: 11, color: AppColors.grisTexte),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    // Bouton modifier
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.vertPrimaire),
                      onPressed: () => _dialogModifier(b),
                    ),
                    // Bouton supprimer
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _supprimer(b['_id']),
                    ),
                  ]),
                );
              },
            ),
          ),
        Positioned(
          bottom: 16, right: 16,
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
