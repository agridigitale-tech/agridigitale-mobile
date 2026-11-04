// Écran d'administration complet : Gestion intégrale (CRUD) des marchés et des cours des produits agricoles.
// Permet d'ajouter, modifier et supprimer des marchés, des denrées et leurs prix, avec sélection
// des vraies photos de céréales et diffusion instantanée des notifications d'alertes à tous les utilisateurs.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/design/app_colors.dart';
import '../../data/marches_data.dart';
import '../../services/prix_produits_service.dart';
import '../../widgets/mini_graphe_tendance.dart';
import '../../widgets/produit_image_widget.dart';

class AdminPrixScreen extends StatefulWidget {
  final bool isTab;
  const AdminPrixScreen({super.key, this.isTab = false});

  @override
  State<AdminPrixScreen> createState() => _AdminPrixScreenState();
}

class _AdminPrixScreenState extends State<AdminPrixScreen>
    with SingleTickerProviderStateMixin {
  final _service = PrixProduitsService();
  List<MarcheAgricole> _marches = [];
  bool _chargement = true;
  String _marcheSelectionneId = 'tous';
  String _recherche = '';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _charger();
    _service.changeNotifier.addListener(_charger);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _service.changeNotifier.removeListener(_charger);
    super.dispose();
  }

  Future<void> _charger() async {
    final list = await _service.getMarches();
    if (mounted) {
      setState(() {
        _marches = list;
        _chargement = false;
      });
    }
  }

  // ════════════════════════════════════════════════════════════════
  // ── SÉLECTEUR D'IMAGE (GALERIE CÉRÉALES, TÉLÉPHONE & NEUTRE)
  // ════════════════════════════════════════════════════════════════

  Future<String?> _choisirImageDepuisTelephone(BuildContext ctx) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Choisir une photo de la denrée',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.photo_library_outlined, color: AppColors.vertPrimaire),
              ),
              title: const Text('Galerie photo du téléphone'),
              subtitle: const Text('Sélectionner depuis la mémoire de votre appareil'),
              onTap: () => Navigator.pop(bCtx, ImageSource.gallery),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.camera_alt_outlined, color: AppColors.vertPrimaire),
              ),
              title: const Text('Prendre une photo'),
              subtitle: const Text('Prendre en direct avec l\'appareil photo'),
              onTap: () => Navigator.pop(bCtx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (picked != null) {
        final file = File(picked.path);
        final url = await _service.televerserImageProduit(file);
        return url ?? picked.path;
      }
    } catch (e) {
      debugPrint('[AdminPrix] Erreur choix image: $e');
    }
    return null;
  }

  Widget _buildSelecteurImageProduit({
    required BuildContext ctx,
    required String imageSelectionnee,
    required void Function(String) onSelectionner,
    required void Function(void Function()) setModalState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Photo du produit', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5)),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.vertPrimaire,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              icon: const Icon(Icons.add_a_photo_outlined, size: 16),
              label: Text('Depuis le téléphone', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
              onPressed: () async {
                final url = await _choisirImageDepuisTelephone(ctx);
                if (url != null) {
                  setModalState(() {
                    onSelectionner(url);
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 72,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // 1. Bouton "Téléphone" dans le carrousel
              InkWell(
                onTap: () async {
                  final url = await _choisirImageDepuisTelephone(ctx);
                  if (url != null) {
                    setModalState(() {
                      onSelectionner(url);
                    });
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 64,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.vertPrimaire.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined, color: AppColors.vertPrimaire, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        'Téléphone',
                        style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.vertPrimaire),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Image personnalisée uploadée si sélectionnée
              if (imageSelectionnee.startsWith('http') || imageSelectionnee.startsWith('/uploads/') || imageSelectionnee.startsWith('/data/')) ...[
                Builder(
                  builder: (_) {
                    final displayUrl = imageSelectionnee.startsWith('/uploads/')
                        ? 'https://agridigitale-mobile.onrender.com$imageSelectionnee'
                        : imageSelectionnee;
                    return Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.vertPrimaire, width: 2.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: displayUrl.startsWith('http')
                            ? CachedNetworkImage(imageUrl: displayUrl, fit: BoxFit.cover)
                            : Image.file(File(displayUrl), fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              ],

              // 3. Toutes les images disponibles de céréales + option Neutre
              ...ProduitImageHelper.imagesDisponibles.map((img) {
                final path = img['fichier']!;
                final isNeutre = path == 'neutre';
                final isSel = imageSelectionnee == path;

                return InkWell(
                  onTap: () {
                    setModalState(() {
                      onSelectionner(path);
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isNeutre ? const Color(0xFFE8F5E9) : null,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSel ? AppColors.vertPrimaire : Colors.grey.shade300,
                        width: isSel ? 2.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: isNeutre
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.eco_rounded, color: AppColors.vertPrimaire, size: 24),
                                const SizedBox(height: 2),
                                Text(
                                  'Neutre',
                                  style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.vertPrimaire),
                                ),
                              ],
                            )
                          : Image.asset(path, fit: BoxFit.cover),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // ── DIALOGUES CRUD PRODUIT & PRIX
  // ════════════════════════════════════════════════════════════════

  void _ouvrirDialogueNouveauProduit({String? preselectMarcheId}) {
    HapticFeedback.lightImpact();
    if (_marches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez d\'abord créer un marché')),
      );
      return;
    }

    String selectedMarcheId = preselectMarcheId ??
        (_marcheSelectionneId != 'tous' ? _marcheSelectionneId : _marches.first.id);

    final produitNomCtrl = TextEditingController();
    final prixActuelCtrl = TextEditingController(text: '800');
    final prixPrecedentCtrl = TextEditingController(text: '750');
    final uniteCtrl = TextEditingController(text: 'Bol (2.5 kg)');
    String imageSelectionnee = ProduitImageHelper.imagesDisponibles.first['fichier']!;
    final customUrlCtrl = TextEditingController();
    bool useCustomUrl = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final int nouveauPrix = int.tryParse(prixActuelCtrl.text.replaceAll(' ', '')) ?? 800;
          final int precedent = int.tryParse(prixPrecedentCtrl.text.replaceAll(' ', '')) ?? 750;

          final t = nouveauPrix > precedent
              ? TendancePrix.hausse
              : (nouveauPrix < precedent ? TendancePrix.baisse : TendancePrix.stable);

          final diff = nouveauPrix - precedent;
          final pct = precedent > 0 ? (diff / precedent) * 100 : 0.0;
          final couleurTendance = t == TendancePrix.hausse
              ? const Color(0xFFD32F2F)
              : (t == TendancePrix.baisse ? const Color(0xFF2E7D32) : Colors.grey);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.88),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.vertPrimaire.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_shopping_cart, color: AppColors.vertPrimaire, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nouveau Produit & Prix', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16)),
                              Text('Ajouter une denrée sur un marché togolais', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.grisTexte)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Sélection du Marché
                    Text('Marché cible', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMarcheId,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _marches.map((m) {
                        return DropdownMenuItem(value: m.id, child: Text('${m.nom} (${m.ville})', style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedMarcheId = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Nom du produit
                    Text('Nom de la denrée agricole', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: produitNomCtrl,
                      decoration: InputDecoration(
                        hintText: 'ex: Maïs blanc, Soja grain, Tomate...',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (val) {
                        // Correspondance automatique d'image si non customisée
                        if (!useCustomUrl) {
                          final auto = ProduitImageHelper.getImagePath(val);
                          if (auto != null) {
                            setModalState(() => imageSelectionnee = auto);
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Sélection de la Photo du Produit (Galerie, Téléphone, Neutre)
                    _buildSelecteurImageProduit(
                      ctx: ctx,
                      imageSelectionnee: imageSelectionnee,
                      onSelectionner: (nouvelleImage) {
                        useCustomUrl = false;
                        imageSelectionnee = nouvelleImage;
                      },
                      setModalState: setModalState,
                    ),
                    const SizedBox(height: 14),

                    // Aperçu en direct de la tendance
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: couleurTendance.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: couleurTendance.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          ProduitImageWidget(
                            nomProduit: produitNomCtrl.text.isNotEmpty ? produitNomCtrl.text : 'Produit',
                            imageOuIcone: useCustomUrl && customUrlCtrl.text.isNotEmpty ? customUrlCtrl.text : imageSelectionnee,
                            size: 36,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t == TendancePrix.hausse
                                      ? 'Alerte : Hausse du cours'
                                      : (t == TendancePrix.baisse ? 'Alerte : Baisse du cours' : 'Cours stable'),
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.5, color: couleurTendance),
                                ),
                                Text(
                                  diff != 0
                                      ? '${diff > 0 ? '+' : ''}$diff F (${pct > 0 ? '+' : ''}${pct.toStringAsFixed(1)}%)'
                                      : 'Aucune variation',
                                  style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.grisTexte, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Text('$nouveauPrix F', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15, color: couleurTendance)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Prix actuel & précédent
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Prix Actuel (FCFA)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: prixActuelCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  suffixText: 'F',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                onChanged: (_) => setModalState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Prix Précédent', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: prixPrecedentCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  suffixText: 'F',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                onChanged: (_) => setModalState(() {}),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Unité
                    Text('Unité de vente', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: uniteCtrl,
                      decoration: InputDecoration(
                        hintText: 'ex: Bol (2.5 kg), Sac 100 kg, Panier...',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bouton Enregistrer
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.vertPrimaire,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final nom = produitNomCtrl.text.trim();
                          if (nom.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Veuillez renseigner le nom de la denrée')),
                            );
                            return;
                          }

                          final pActuel = int.tryParse(prixActuelCtrl.text.replaceAll(' ', '')) ?? 0;
                          final pPrec = int.tryParse(prixPrecedentCtrl.text.replaceAll(' ', '')) ?? pActuel;
                          if (pActuel <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Le prix doit être supérieur à 0')),
                            );
                            return;
                          }

                          Navigator.pop(ctx);

                          final imgFinale = useCustomUrl && customUrlCtrl.text.isNotEmpty
                              ? customUrlCtrl.text.trim()
                              : imageSelectionnee;

                          final nouveauProduit = PrixProduit(
                            produit: nom,
                            unite: uniteCtrl.text.trim().isNotEmpty ? uniteCtrl.text.trim() : 'Bol (2.5 kg)',
                            prixActuel: pActuel,
                            prixPrecedent: pPrec,
                            tendance: t,
                            icone: imgFinale,
                            historiquePrix: [pPrec, pActuel],
                          );

                          await _service.ajouterProduit(
                            marcheId: selectedMarcheId,
                            produit: nouveauProduit,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('"$nom" ajouté avec succès. Notification diffusée à tous les utilisateurs ! ✓'),
                                backgroundColor: AppColors.vertFonce,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: Text(
                          'AJOUTER LE PRODUIT & DIFFUSER L\'ALERTE',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _ouvrirDialogueEdition({required MarcheAgricole marche, required PrixProduit produit}) {
    HapticFeedback.lightImpact();

    final prixActuelCtrl = TextEditingController(text: '${produit.prixActuel}');
    final prixPrecedentCtrl = TextEditingController(text: '${produit.prixPrecedent}');
    final uniteCtrl = TextEditingController(text: produit.unite);
    String imageSelectionnee = produit.icone;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final int nouveauPrix = int.tryParse(prixActuelCtrl.text.replaceAll(' ', '')) ?? produit.prixActuel;
          final int precedent = int.tryParse(prixPrecedentCtrl.text.replaceAll(' ', '')) ?? produit.prixPrecedent;

          final t = nouveauPrix > precedent
              ? TendancePrix.hausse
              : (nouveauPrix < precedent ? TendancePrix.baisse : TendancePrix.stable);

          final diff = nouveauPrix - precedent;
          final pct = precedent > 0 ? (diff / precedent) * 100 : 0.0;
          final couleurTendance = t == TendancePrix.hausse
              ? const Color(0xFFD32F2F)
              : (t == TendancePrix.baisse ? const Color(0xFF2E7D32) : Colors.grey);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.88),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        ProduitImageWidget(
                          nomProduit: produit.produit,
                          imageOuIcone: imageSelectionnee,
                          size: 46,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(produit.produit, style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.texteFort)),
                              Text('${marche.nom} (${marche.ville})', style: GoogleFonts.inter(fontSize: 12, color: AppColors.grisTexte)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Sélection de la Photo du Produit (Galerie, Téléphone, Neutre)
                    _buildSelecteurImageProduit(
                      ctx: ctx,
                      imageSelectionnee: imageSelectionnee,
                      onSelectionner: (nouvelleImage) {
                        imageSelectionnee = nouvelleImage;
                      },
                      setModalState: setModalState,
                    ),
                    const SizedBox(height: 14),

                    // Prévisualisation en direct
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: couleurTendance.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: couleurTendance.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          MiniGrapheTendance(
                            tendance: t,
                            couleur: couleurTendance,
                            width: 58,
                            height: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t == TendancePrix.hausse
                                      ? 'Tendance : Hausse du cours'
                                      : (t == TendancePrix.baisse ? 'Tendance : Baisse du cours' : 'Tendance : Cours stable'),
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: couleurTendance),
                                ),
                                Text(
                                  diff != 0
                                      ? '${diff > 0 ? '+' : ''}$diff F (${pct > 0 ? '+' : ''}${pct.toStringAsFixed(1)}%)'
                                      : 'Aucune variation',
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.grisTexte, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Text('$nouveauPrix F', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: couleurTendance)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nouveau Prix
                    Text('Nouveau Prix Actuel (en FCFA)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: prixActuelCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.monetization_on_outlined, color: AppColors.vertPrimaire),
                        suffixText: 'FCFA',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Prix Précédent
                    Text('Prix Précédent (de référence)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: prixPrecedentCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.history, color: Colors.blueGrey),
                        suffixText: 'FCFA',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Unité
                    Text('Unité de mesure', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: uniteCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.scale_outlined, color: AppColors.grisIcone),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bouton Enregistrer
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final valActuel = int.tryParse(prixActuelCtrl.text.replaceAll(' ', ''));
                          final valPrec = int.tryParse(prixPrecedentCtrl.text.replaceAll(' ', ''));
                          if (valActuel == null || valActuel <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Veuillez saisir un prix valide supérieur à 0')),
                            );
                            return;
                          }

                          Navigator.pop(ctx);

                          await _service.updatePrixProduit(
                            marcheId: marche.id,
                            nomProduit: produit.produit,
                            nouveauPrix: valActuel,
                            nouveauPrixPrecedent: valPrec,
                            nouvelleUnite: uniteCtrl.text.trim().isNotEmpty ? uniteCtrl.text.trim() : null,
                            nouvelleIcone: imageSelectionnee,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Prix de "${produit.produit}" mis à jour ($valActuel FCFA). Notification diffusée ! ✓'),
                                backgroundColor: AppColors.vertFonce,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.vertPrimaire,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'ENREGISTRER & DIFFUSER LA NOTIFICATION',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmerSuppressionProduit(MarcheAgricole marche, PrixProduit produit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer "${produit.produit}" ?'),
        content: Text('Voulez-vous retirer cette denrée du marché ${marche.nom} (${marche.ville}) ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.supprimerProduit(marcheId: marche.id, nomProduit: produit.produit);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"${produit.produit}" retiré avec succès ✓')),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // ── DIALOGUES CRUD MARCHÉS
  // ════════════════════════════════════════════════════════════════

  void _ouvrirDialogueNouveauMarche() {
    final nomCtrl = TextEditingController();
    final villeCtrl = TextEditingController();
    String regionSelectionnee = 'Maritime';
    const regions = ['Maritime', 'Plateaux', 'Centrale', 'Kara', 'Savanes'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.storefront, color: AppColors.vertPrimaire),
              const SizedBox(width: 8),
              const Text('Nouveau Marché', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nom du marché', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: nomCtrl,
                  decoration: const InputDecoration(hintText: 'ex: Marché d\'Adawlato, Marché d\'Aného...'),
                ),
                const SizedBox(height: 12),
                const Text('Ville', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: villeCtrl,
                  decoration: const InputDecoration(hintText: 'ex: Lomé, Tsévié, Atakpamé...'),
                ),
                const SizedBox(height: 12),
                const Text('Région du Togo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: regionSelectionnee,
                  items: regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) {
                    if (v != null) setDlgState(() => regionSelectionnee = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.vertPrimaire, foregroundColor: Colors.white),
              onPressed: () async {
                final nom = nomCtrl.text.trim();
                final ville = villeCtrl.text.trim();
                if (nom.isEmpty || ville.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Le nom et la ville sont obligatoires')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                final slug = nom.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
                final suffix = DateTime.now().millisecondsSinceEpoch % 1000;
                final id = '${slug}_$suffix';
                final nouveauMarche = MarcheAgricole(
                  id: id,
                  nom: nom,
                  ville: ville,
                  region: regionSelectionnee,
                  produits: [],
                );
                await _service.ajouterMarche(marche: nouveauMarche);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Marché "$nom" créé avec succès ✓'), backgroundColor: AppColors.vertFonce),
                  );
                }
              },
              child: const Text('Créer le marché'),
            ),
          ],
        ),
      ),
    );
  }

  void _ouvrirDialogueModifierMarche(MarcheAgricole m) {
    final nomCtrl = TextEditingController(text: m.nom);
    final villeCtrl = TextEditingController(text: m.ville);
    String regionSelectionnee = m.region.isNotEmpty ? m.region : 'Maritime';
    const regions = ['Maritime', 'Plateaux', 'Centrale', 'Kara', 'Savanes'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Modifier le marché', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nom du marché', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(controller: nomCtrl),
                const SizedBox(height: 12),
                const Text('Ville', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(controller: villeCtrl),
                const SizedBox(height: 12),
                const Text('Région du Togo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: regions.contains(regionSelectionnee) ? regionSelectionnee : regions.first,
                  items: regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) {
                    if (v != null) setDlgState(() => regionSelectionnee = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.vertPrimaire, foregroundColor: Colors.white),
              onPressed: () async {
                final nom = nomCtrl.text.trim();
                final ville = villeCtrl.text.trim();
                if (nom.isEmpty || ville.isEmpty) return;
                Navigator.pop(ctx);
                await _service.modifierMarche(id: m.id, nom: nom, ville: ville, region: regionSelectionnee);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Marché "$nom" mis à jour ✓'), backgroundColor: AppColors.vertFonce),
                  );
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmerSuppressionMarche(MarcheAgricole m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer le marché "${m.nom}" ?'),
        content: Text('Attention : cela supprimera également tous les ${m.produits.length} cours associés à ce marché.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.supprimerMarche(id: m.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Marché "${m.nom}" supprimé ✓')),
                );
              }
            },
            child: const Text('Supprimer définitivement', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _dialogReinitialiser() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Réinitialiser les prix ?'),
        content: const Text('Tous les cours personnalisés seront remis aux valeurs par défaut officielles du Togo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.resetToDefaults();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Réinitialisation terminée avec succès ✓'), backgroundColor: Colors.blueGrey),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Réinitialiser', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = _chargement
        ? const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire))
        : Column(
            children: [
              // Onglets : Cours des denrées / Marchés
              Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceSombre : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.vertPrimaire,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? AppColors.texteSombreMoyen : Colors.black87,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.grain, size: 16),
                          const SizedBox(width: 6),
                          Text('Cours & Prix (${_compterTotalProduits()})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.storefront, size: 16),
                          const SizedBox(width: 6),
                          Text('Marchés (${_marches.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOngletPrix(isDark),
                    _buildOngletMarches(isDark),
                  ],
                ),
              ),
            ],
          );

    if (widget.isTab) return content;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Prix & Marchés', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.vertPrimaire,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Rétablir les valeurs par défaut',
            onPressed: _dialogReinitialiser,
          ),
        ],
      ),
      body: content,
    );
  }

  int _compterTotalProduits() {
    int total = 0;
    for (final m in _marches) {
      total += m.produits.length;
    }
    return total;
  }

  // ════════════════════════════════════════════════════════════════
  // ── ONGLET 1 : COURS DES DENRÉES ET PRIX PAR MARCHÉ
  // ════════════════════════════════════════════════════════════════

  Widget _buildOngletPrix(bool isDark) {
    final List<Map<String, dynamic>> itemsFiltres = [];
    int totalHausse = 0;
    int totalBaisse = 0;
    int totalStable = 0;

    for (final marche in _marches) {
      for (final produit in marche.produits) {
        if (produit.tendance == TendancePrix.hausse) totalHausse++;
        if (produit.tendance == TendancePrix.baisse) totalBaisse++;
        if (produit.tendance == TendancePrix.stable) totalStable++;

        if (_marcheSelectionneId != 'tous' && marche.id != _marcheSelectionneId) {
          continue;
        }

        if (_recherche.isNotEmpty) {
          final q = _recherche.toLowerCase();
          final match = produit.produit.toLowerCase().contains(q) ||
              marche.nom.toLowerCase().contains(q) ||
              marche.ville.toLowerCase().contains(q);
          if (!match) continue;
        }

        itemsFiltres.add({
          'marche': marche,
          'produit': produit,
        });
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bouton d'action principal : Ajouter un prix / denrée
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vertPrimaire,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              onPressed: () => _ouvrirDialogueNouveauProduit(),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: Text(
                'AJOUTER UN NOUVEAU PRIX PRODUIT',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Statistiques
          Row(
            children: [
              Expanded(
                child: _buildCarteStat(
                  titre: 'En hausse',
                  valeur: '$totalHausse',
                  couleur: const Color(0xFFD32F2F),
                  icone: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCarteStat(
                  titre: 'En baisse',
                  valeur: '$totalBaisse',
                  couleur: const Color(0xFF2E7D32),
                  icone: Icons.trending_down,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCarteStat(
                  titre: 'Stables',
                  valeur: '$totalStable',
                  couleur: Colors.blueGrey,
                  icone: Icons.trending_flat,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Recherche
          TextField(
            onChanged: (val) => setState(() => _recherche = val),
            decoration: InputDecoration(
              hintText: 'Rechercher une denrée (maïs, soja, gari...)...',
              prefixIcon: const Icon(Icons.search, color: AppColors.grisIcone, size: 20),
              filled: true,
              fillColor: isDark ? AppColors.surfaceSombre : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),

          // Filtre Marchés
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildMarcheChip('tous', 'Tous les marchés'),
                const SizedBox(width: 8),
                ..._marches.map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildMarcheChip(m.id, '${m.ville} (${m.nom})'),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Liste des denrées
          if (itemsFiltres.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text('Aucun cours répertorié pour ce filtre.', style: TextStyle(color: AppColors.grisTexte)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemsFiltres.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final MarcheAgricole m = itemsFiltres[i]['marche'];
                final PrixProduit p = itemsFiltres[i]['produit'];

                final couleurTendance = p.tendance == TendancePrix.hausse
                    ? const Color(0xFFD32F2F)
                    : (p.tendance == TendancePrix.baisse ? const Color(0xFF2E7D32) : Colors.grey);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceSombre : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.bordureSombre : Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Vraie photo du produit
                      ProduitImageWidget(
                        nomProduit: p.produit,
                        imageOuIcone: p.icone,
                        size: 46,
                        borderRadius: 10,
                      ),
                      const SizedBox(width: 12),

                      // Infos produit
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.produit,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: isDark ? AppColors.texteSombreFort : AppColors.texteFort,
                              ),
                            ),
                            Text(
                              '${m.nom} • ${m.ville}',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: isDark ? AppColors.texteSombreMoyen : AppColors.grisTexte,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.vertPrimaire.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                p.unite,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.vertClair : AppColors.vertPrimaire,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Prix et mini graphe
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${p.prixActuel} F',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: couleurTendance),
                          ),
                          const SizedBox(height: 2),
                          MiniGrapheTendance(
                            tendance: p.tendance,
                            couleur: couleurTendance,
                            points: p.historiquePrix,
                            width: 50,
                            height: 16,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Préc. ${p.prixPrecedent} F',
                            style: GoogleFonts.inter(fontSize: 10.5, color: isDark ? AppColors.texteSombreMoyen : AppColors.grisTexte),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),

                      // Bouton d'édition
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.vertPrimaire, size: 20),
                        tooltip: 'Modifier ce prix',
                        onPressed: () => _ouvrirDialogueEdition(marche: m, produit: p),
                      ),

                      // Bouton de suppression
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        tooltip: 'Retirer ce produit',
                        onPressed: () => _confirmerSuppressionProduit(m, p),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // ── ONGLET 2 : CRUD DES MARCHÉS AGRICOLES
  // ════════════════════════════════════════════════════════════════

  Widget _buildOngletMarches(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bouton Ajouter un marché
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vertPrimaire,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              onPressed: _ouvrirDialogueNouveauMarche,
              icon: const Icon(Icons.add_business_rounded, size: 20),
              label: Text(
                'AJOUTER UN NOUVEAU MARCHÉ',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            '${_marches.length} marchés répertoriés au Togo',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 10),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _marches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final m = _marches[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceSombre : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.bordureSombre : Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.vertClair : AppColors.vertPrimaire).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.storefront_rounded, color: isDark ? AppColors.vertClair : AppColors.vertPrimaire, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.nom,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ville : ${m.ville} • Région ${m.region}',
                            style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.texteSombreMoyen : AppColors.grisTexte),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${m.produits.length} denrée(s) suivie(s)',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.vertPrimaire, size: 20),
                      tooltip: 'Ajouter une denrée à ce marché',
                      onPressed: () => _ouvrirDialogueNouveauProduit(preselectMarcheId: m.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey, size: 20),
                      tooltip: 'Modifier le marché',
                      onPressed: () => _ouvrirDialogueModifierMarche(m),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      tooltip: 'Supprimer ce marché',
                      onPressed: () => _confirmerSuppressionMarche(m),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCarteStat({required String titre, required String valeur, required Color couleur, required IconData icone}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, size: 14, color: couleur),
              const SizedBox(width: 4),
              Text(titre, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: couleur)),
            ],
          ),
          const SizedBox(height: 2),
          Text(valeur, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: couleur)),
        ],
      ),
    );
  }

  Widget _buildMarcheChip(String id, String label) {
    final estSelectionne = (_marcheSelectionneId == id);
    return ChoiceChip(
      label: Text(label),
      selected: estSelectionne,
      onSelected: (_) => setState(() => _marcheSelectionneId = id),
      selectedColor: AppColors.vertPrimaire,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: estSelectionne ? FontWeight.bold : FontWeight.normal,
        color: estSelectionne ? Colors.white : Colors.black87,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
