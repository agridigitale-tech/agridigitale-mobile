import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/admin_service.dart';
import '../../core/design/app_colors.dart';
import '../../core/api_client.dart';
import 'admin_widgets.dart';
import '../../widgets/banner_carousel.dart';
import '../../widgets/boosted_banner_overlay.dart';

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
    if (!img.startsWith('/')) return '$base/$img';
    return '$base$img';
  }

  // Affiche la bannière en plein format (telle qu'elle est, sans rognage)
  void _afficherBannierePleinFormat(Map<String, dynamic> b) {
    final url = _urlImage(b['image'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: url.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.contain, // Format original sans coupure
                        placeholder: (_, __) => const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.vertPrimaire),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Image non disponible sur le serveur', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    : const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Aucune image disponible'),
                      ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _dialogAjouter() {
    final ordreCtrl = TextEditingController(text: '1');
    final lienCtrl = TextEditingController();
    final List<File> images = [];
    DateTime dateDebut = DateTime.now();
    DateTime dateFin = DateTime.now().add(const Duration(days: 30));
    bool boostee = false;
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

                // ── Option Booster ──
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: boostee,
                  onChanged: (v) => setS(() => boostee = v),
                  title: const Text('Booster cette bannière',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text(
                      'S\'affiche au centre en carré arrondi avec animation à l\'ouverture',
                      style: TextStyle(fontSize: 11, color: AppColors.grisTexte)),
                  secondary: Icon(Icons.rocket_launch,
                      color: boostee ? Colors.amber.shade700 : AppColors.grisIcone),
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
                                    boostee: boostee,
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
    bool boostee = b['boostee'] == true;
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

                // ── Option Booster ──
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: boostee,
                  onChanged: (v) => setS(() => boostee = v),
                  title: const Text('Booster cette bannière',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text(
                      'S\'affiche au centre en carré arrondi avec animation à l\'ouverture',
                      style: TextStyle(fontSize: 11, color: AppColors.grisTexte)),
                  secondary: Icon(Icons.rocket_launch,
                      color: boostee ? Colors.amber.shade700 : AppColors.grisIcone),
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
                            boostee: boostee,
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

  Future<void> _toggleBooster(Map<String, dynamic> b) async {
    final actuel = b['boostee'] == true;
    final nouveau = !actuel;
    try {
      await widget.service.toggleBoosterBanniere(b['_id'], boostee: nouveau);
      BannerCarousel.actualiser();
      await _charger();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nouveau
                ? 'Bannière boostée 🚀 ! Elle s\'affichera au centre de l\'accueil pour toute personne qui ouvre l\'application.'
                : 'Boost désactivé pour cette bannière.'),
            backgroundColor: nouveau ? Colors.amber.shade800 : Colors.grey.shade700,
          ),
        );
        if (nouveau) {
          BoostedBannerOverlay.afficherApercu(context, {
            'image': _urlImage(b['image'] ?? ''),
            'lien': b['lien'],
            'titre': b['titre'],
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
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
                final estBoostee = b['boostee'] == true;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
                  ),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => _afficherBannierePleinFormat(b),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: _urlImage(b['image'] ?? ''),
                              width: 80,
                              height: 50,
                              fit: BoxFit.cover,
                              placeholder: (ctx, url) => Container(
                                width: 80,
                                height: 50,
                                color: AppColors.grisPastille,
                                child: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.vertPrimaire,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (ctx, e, s) => Container(
                                width: 80,
                                height: 50,
                                color: AppColors.grisPastille,
                                child: const Icon(Icons.broken_image, color: AppColors.grisIcone),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(3),
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.fullscreen, color: Colors.white, size: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('Ordre : ${b['ordre'] ?? 0}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                              if (estBoostee)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.amber.shade700),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.rocket_launch, size: 10, color: Colors.amber.shade900),
                                      const SizedBox(width: 3),
                                      Text('BOOSTÉ',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                                    ],
                                  ),
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
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Bouton Booster (on/off)
                              InkWell(
                                onTap: () => _toggleBooster(b),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: estBoostee ? Colors.amber.shade600 : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: estBoostee ? Colors.amber.shade800 : Colors.grey.shade400,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        estBoostee ? Icons.rocket_launch : Icons.rocket_launch_outlined,
                                        size: 13,
                                        color: estBoostee ? Colors.white : Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        estBoostee ? 'Boosté' : 'Booster',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: estBoostee ? Colors.white : Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Bouton Aperçu animation
                              InkWell(
                                onTap: () => BoostedBannerOverlay.afficherApercu(context, {
                                  'image': _urlImage(b['image'] ?? ''),
                                  'lien': b['lien'],
                                  'titre': b['titre'],
                                }),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.vertClair.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.play_circle_outline, size: 13, color: AppColors.vertPrimaire),
                                      SizedBox(width: 3),
                                      Text('Aperçu', style: TextStyle(fontSize: 11, color: AppColors.vertPrimaire, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Boutons d'actions compacts
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit_outlined, color: AppColors.vertPrimaire, size: 20),
                          tooltip: 'Modifier',
                          onPressed: () => _dialogModifier(b),
                        ),
                        const SizedBox(height: 6),
                        IconButton(
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          tooltip: 'Supprimer',
                          onPressed: () => _supprimer(b['_id']),
                        ),
                      ],
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
