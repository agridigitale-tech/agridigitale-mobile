// Écran détail d'un article : hero immersif, contenu éditorial, réseaux sociaux,
// commentaires et articles similaires.
// Gère aussi le partage (WhatsApp, Facebook, X, copier lien, autres) et les favoris.
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/article_service.dart';
import '../../services/favori_service.dart';
import '../../services/commentaire_service.dart';
import '../../models/article.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_gate.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/api_client.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String articleId;
  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final _articleService = ArticleService();
  final _favoriService = FavoriService();
  final _commentaireService = CommentaireService();
  final _commentaireCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  /// Progression de lecture (0..1) pour la barre de progression de l'AppBar.
  final _progression = ValueNotifier<double>(0);

  late Future<Article> _future;
  late Future<List<Article>> _autresFuture;
  List<Commentaire> _commentaires = [];
  bool _chargementCommentaires = false;
  bool _envoi = false;
  bool _favoriTraite = false;

  @override
  void initState() {
    super.initState();
    _future = _articleService.detail(widget.articleId);
    _autresFuture = _articleService.lister();
    _chargerCommentaires();
    _scrollCtrl.addListener(_majProgression);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_majProgression);
    _commentaireCtrl.dispose();
    _scrollCtrl.dispose();
    _progression.dispose();
    super.dispose();
  }

  void _majProgression() {
    if (!_scrollCtrl.hasClients) return;
    final max = _scrollCtrl.position.maxScrollExtent;
    _progression.value = max <= 0 ? 0 : (_scrollCtrl.offset / max).clamp(0.0, 1.0);
  }

  Future<void> _chargerCommentaires() async {
    setState(() => _chargementCommentaires = true);
    try {
      final liste = await _commentaireService.lister(widget.articleId);
      if (mounted) setState(() => _commentaires = liste);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _chargementCommentaires = false);
    }
  }

  Future<void> _envoyerCommentaire() async {
    final texte = _commentaireCtrl.text.trim();
    if (texte.length < 2) return;
    final connecte = await exigerConnexion(context, motif: 'laisser un commentaire');
    if (!connecte) return;
    setState(() => _envoi = true);
    try {
      final c = await _commentaireService.ajouter(widget.articleId, texte);
      _commentaireCtrl.clear();
      if (mounted) {
        setState(() => _commentaires.insert(0, c));
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _supprimerCommentaire(Commentaire c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Voulez-vous supprimer ce commentaire ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _commentaireService.supprimer(widget.articleId, c.id);
      if (mounted) setState(() => _commentaires.remove(c));
    } catch (_) {}
  }

  // ── Partage ────────────────────────────────────────────────────────────────

  void _partagerArticle(Article article) {
    final lien = article.lienSource.isNotEmpty
        ? article.lienSource
        : 'https://agridigitale.com/articles/${article.id}';
    final texte = '${article.titre}\n$lien';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Partager cet article',
                style: GoogleFonts.inter(
                    fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.texteFort)),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _boutonPartage(
                  icone: FontAwesomeIcons.whatsapp,
                  label: 'WhatsApp',
                  couleur: const Color(0xFF25D366),
                  onTap: () {
                    Navigator.pop(context);
                    launchUrl(
                      Uri.parse('https://wa.me/?text=${Uri.encodeComponent(texte)}'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
                _boutonPartage(
                  icone: FontAwesomeIcons.facebookF,
                  label: 'Facebook',
                  couleur: const Color(0xFF1877F2),
                  onTap: () {
                    Navigator.pop(context);
                    launchUrl(
                      Uri.parse('https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(lien)}'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
                _boutonPartage(
                  icone: FontAwesomeIcons.xTwitter,
                  label: 'X',
                  couleur: Colors.black,
                  onTap: () {
                    Navigator.pop(context);
                    launchUrl(
                      Uri.parse('https://twitter.com/intent/tweet?text=${Uri.encodeComponent(texte)}'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
                _boutonPartage(
                  icone: FontAwesomeIcons.link,
                  label: 'Copier',
                  couleur: AppColors.grisIcone,
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: lien));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lien copié !'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                _boutonPartage(
                  icone: FontAwesomeIcons.shareNodes,
                  label: 'Autres',
                  couleur: AppColors.vertPrimaire,
                  onTap: () {
                    Navigator.pop(context);
                    Share.share(texte, subject: article.titre);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _boutonPartage({
    required FaIconData icone,
    required String label,
    required Color couleur,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(child: FaIcon(icone, color: couleur, size: 22)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(label,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.grisTexte)),
        ],
      ),
    );
  }

  Future<void> _basculerFavori(Article article) async {
    final connecte = await exigerConnexion(context, motif: 'ajouter cet article a vos favoris');
    if (!connecte) return;
    setState(() => _favoriTraite = true);
    try {
      await _favoriService.ajouter(article);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajouté aux favoris'),
            backgroundColor: AppColors.vertFonce,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted && e.toString().contains('409')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Déjà dans vos favoris'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _favoriTraite = false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _formaterDate(DateTime date) {
    try {
      return DateFormat('dd MMM yyyy · HH:mm', 'fr_FR').format(date);
    } catch (_) {
      return '${date.day}/${date.month}/${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  String _tempsRelatif(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Temps de lecture estimé (moyenne 200 mots/min).
  String _tempsLecture(Article article) {
    final texte = article.contenu.replaceAll(RegExp(r'<[^>]*>'), ' ');
    final mots = texte.split(RegExp(r'\s+')).where((m) => m.isNotEmpty).length;
    final minutes = (mots / 200).ceil().clamp(1, 60);
    return '$minutes min de lecture';
  }

  // Domaine public des images de contenu (agridigitale.com est down)
  static const _domaineImages = 'https://agridigitale.net';

  // Base du backend pour le proxy CORS (sans le suffixe /api)
  static String get _backendBase =>
      ApiClient.baseUrl.replaceAll('/api', '');

  // Sur le web, les images agridigitale.net n'exposent pas d'en-tête CORS :
  // on passe donc par le proxy backend. Sur mobile, l'accès direct fonctionne.
  String _proxyImage(String url) {
    if (!kIsWeb) return url;
    if (!url.startsWith('https://agridigitale.net') &&
        !url.startsWith('http://agridigitale.net') &&
        !url.startsWith('https://agridigitale.com') &&
        !url.startsWith('http://agridigitale.com')) {
      return url;
    }
    return '$_backendBase/api/proxy-image?url=${Uri.encodeComponent(url)}';
  }

  // Retourne le contenu HTML à afficher :
  // priorité au contenu complet, fallback sur le résumé, puis message par défaut
  String _getContenuHtml(Article article) {
    final texte = article.contenu.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    if (texte.isNotEmpty) {
      // Réécrit les images inline : {{BASE_URL}} + chemins relatifs → URL absolues
      return _normaliserImagesContenu(article.contenu);
    }
    if (article.resume.isNotEmpty) return '<p>${article.resume}</p>';
    return '<p>Contenu non disponible.</p>';
  }

  // Convertit une URL d'image relative (/ck/xxx.jpg) ou un marqueur en URL absolue
  String _urlAbsolue(String url) {
    final u = url.trim();
    if (u.isEmpty) return url;
    if (RegExp(r'^(data:|blob:|mailto:|tel:|#)', caseSensitive: false).hasMatch(u)) {
      return url;
    }
    if (RegExp(r'^https?://', caseSensitive: false).hasMatch(u)) {
      return _proxyImage(
        u.replaceAll(
                RegExp(r'agridigitale\.com', caseSensitive: false), 'agridigitale.net')
            .replaceAllMapped(
                RegExp(r'^(https?://[^/]+)/ck/', caseSensitive: false),
                (m) => '${m.group(1)}/storage/ck/'),
      );
    }
    if (u.startsWith('//')) return _proxyImage('https:$u');
    return _proxyImage(
      '$_domaineImages${u.startsWith('/') ? u : '/$u'}'.replaceAllMapped(
          RegExp(r'^(https?://[^/]+)/ck/', caseSensitive: false),
          (m) => '${m.group(1)}/storage/ck/'),
    );
  }

  // Normalise une valeur srcset ("url1 1x, url2 2x") en absolutisant chaque URL
  String _normaliserSrcset(String valeur) => valeur.split(',').map((partie) {
        final bits = partie.trim().split(RegExp(r'\s+'));
        if (bits.isEmpty || bits[0].isEmpty) return partie.trim();
        bits[0] = _urlAbsolue(bits[0]);
        return bits.join(' ');
      }).join(', ');

  // Filtre de réécriture des balises <img> :
  //  - {{BASE_URL}} et agridigitale.com → agridigitale.net
  //  - src / data-src / srcset relatifs → URL absolues
  //  - promeut data-src en src (lazy-loading) quand src est vide
  String _normaliserImagesContenu(String html) {
    if (html.isEmpty) return html;
    var resultat = html
        .replaceAll(RegExp(r'\{\{BASE_URL\}\}', caseSensitive: false), _domaineImages)
        .replaceAll(RegExp(r'agridigitale\.com', caseSensitive: false), 'agridigitale.net');

    resultat = resultat.replaceAllMapped(
      RegExp(r'<img\b[^>]*>', caseSensitive: false),
      (tagMatch) {
        var tag = tagMatch.group(0)!;

        final dataSrc = RegExp(r'''\sdata-src\s*=\s*(["'])([\s\S]*?)\1''',
                caseSensitive: false)
            .firstMatch(tag);
        final srcMatch = RegExp(r'''\ssrc\s*=\s*(["'])([\s\S]*?)\1''',
                caseSensitive: false)
            .firstMatch(tag);
        final srcVide = srcMatch == null || srcMatch.group(2)!.trim().isEmpty;

        if (dataSrc != null && srcVide) {
          final absolue = _urlAbsolue(dataSrc.group(2)!);
          if (srcMatch != null) {
            tag = tag.replaceFirst(
                RegExp(r'''\ssrc\s*=\s*(["'])[\s\S]*?\1''', caseSensitive: false),
                ' src="$absolue"');
          } else {
            tag = tag.replaceFirst('<img', '<img src="$absolue"');
          }
        }

        tag = tag.replaceAllMapped(
          RegExp(r'''(\ssrc\s*=\s*)(["'])([\s\S]*?)\2''', caseSensitive: false),
          (m) => '${m[1]}${m[2]}${_urlAbsolue(m[3]!)}${m[2]}',
        );
        tag = tag.replaceAllMapped(
          RegExp(r'''(\sdata-src\s*=\s*)(["'])([\s\S]*?)\2''', caseSensitive: false),
          (m) => '${m[1]}${m[2]}${_urlAbsolue(m[3]!)}${m[2]}',
        );
        tag = tag.replaceAllMapped(
          RegExp(r'''(\ssrcset\s*=\s*)(["'])([\s\S]*?)\2''', caseSensitive: false),
          (m) => '${m[1]}${m[2]}${_normaliserSrcset(m[3]!)}${m[2]}',
        );

        return tag;
      },
    );
    return resultat;
  }

  // ── Figures HTML ─────────────────────────────────────────────────────────────

  // Construit une figure HTML (<figure><img><figcaption>) :
  //  - classe "image-style-side" → image à gauche, légende à droite
  //  - sinon → image puis légende empilées (rendu bloc classique)
  Widget _construireFigure(ExtensionContext context) {
    final img = _extraireImageFigure(context);
    final legende = _extraireLegendeFigure(context);
    final src =
        (img.$1 != null && img.$1!.trim().isNotEmpty) ? _urlAbsolue(img.$1!) : null;
    final alt = img.$2 ?? '';

    if (src == null) {
      if (legende == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          legende,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: AppColors.grisTexte,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: CachedNetworkImage(
        imageUrl: src,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, _) => _skeletonImage(180),
        errorWidget: (_, _, _) => Container(
          height: 180,
          color: AppColors.grisPastille,
          child: const Center(
            child: Icon(Icons.image_not_supported_outlined,
                color: AppColors.grisIcone, size: 32),
          ),
        ),
      ),
    );

    final estSurLeCote = context.classes.contains('image-style-side');

    if (estSurLeCote) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 150, child: image),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                legende ?? alt,
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: AppColors.grisTexte, height: 1.45),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          image,
          if (legende != null && legende.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              legende,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.grisTexte,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Récupère (src, alt) de la première <img> de la figure (même imbriquée dans <a>)
  (String?, String?) _extraireImageFigure(ExtensionContext context) {
    for (final el in context.elementChildren) {
      if (el.localName == 'img') {
        return (el.attributes['src'], el.attributes['alt']);
      }
      if (el.localName == 'a') {
        for (final sub in el.children) {
          if (sub.localName == 'img') {
            return (sub.attributes['src'], sub.attributes['alt']);
          }
        }
      }
    }
    return (null, null);
  }

  // Récupère le texte de la <figcaption> de la figure
  String? _extraireLegendeFigure(ExtensionContext context) {
    for (final el in context.elementChildren) {
      if (el.localName == 'figcaption') {
        final texte = el.text.trim();
        if (texte.isNotEmpty) return texte;
      }
    }
    return null;
  }

  // ── Widgets de base ──────────────────────────────────────────────────────────

  Widget _skeletonImage(double height) => Container(
        height: height,
        color: AppColors.grisPastille,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                color: AppColors.vertPrimaire, strokeWidth: 2),
          ),
        ),
      );

  Widget _imagePlaceholder() => Container(
        color: const Color(0xFFEDF3EE),
        child: const Center(
          child: Icon(Icons.article_outlined, size: 64, color: AppColors.vertPrimaire),
        ),
      );

  Color _couleurCategorie(String cat) {
    switch (cat.toLowerCase()) {
      case 'togo':
        return const Color(0xFF2E7D32);
      case 'afrique':
        return const Color(0xFFE65100);
      case 'monde':
        return const Color(0xFF1565C0);
      default:
        return AppColors.vertPrimaire;
    }
  }

  Widget _pastilleCategorie(String categorie) {
    final couleur = _couleurCategorie(categorie);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: couleur,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadow.douce,
      ),
      child: Text(
        categorie.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Article>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.vertPrimaire));
          }
          if (snapshot.hasError) {
            return _vueErreur();
          }
          final article = snapshot.data!;
          return CustomScrollView(
            controller: _scrollCtrl,
            slivers: [
              _buildAppBar(article),
              _buildContenu(article),
              _buildSectionCommentaires(auth),
              _buildAutresArticles(article),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          );
        },
      ),
    );
  }

  Widget _vueErreur() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.grisPastille,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 32, color: AppColors.grisIcone),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Impossible de charger l\'article',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.texteFort)),
            const SizedBox(height: AppSpacing.xs),
            Text('Vérifiez votre connexion puis réessayez.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.grisTexte)),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _future = _articleService.detail(widget.articleId);
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.vertPrimaire,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // AppBar immersive : image en hero + dégradé + accents + barre de progression lecture.
  Widget _buildAppBar(Article article) {
    final hasImage = article.image != null && article.image!.isNotEmpty;
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.vertFonce,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const SizedBox.shrink(),
      leading: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: _boutonRond(
          icone: FontAwesomeIcons.arrowLeft,
          onTap: () => Navigator.maybePop(context),
        ),
      ),
      actions: [
        _boutonRond(
          icone: FontAwesomeIcons.shareNodes,
          onTap: () => _partagerArticle(article),
        ),
        const SizedBox(width: AppSpacing.sm),
        _boutonRond(
          icone: _favoriTraite ? FontAwesomeIcons.spinner : FontAwesomeIcons.solidBookmark,
          onTap: _favoriTraite ? null : () => _basculerFavori(article),
        ),
        const SizedBox(width: AppSpacing.md),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: ValueListenableBuilder<double>(
          valueListenable: _progression,
          builder: (_, valeur, _) => LinearProgressIndicator(
            value: valeur,
            minHeight: 3,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              CachedNetworkImage(
                imageUrl: article.image!,
                fit: BoxFit.cover,
                placeholder: (_, _) => _imagePlaceholder(),
                errorWidget: (_, _, _) => _imagePlaceholder(),
              )
            else
              _imagePlaceholder(),
            // Dégradé pour garantir la lisibilité des boutons/texte par-dessus l'image
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent, Colors.black87],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
            // Bas du hero : catégorie + temps de lecture
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: Row(
                children: [
                  _pastilleCategorie(article.categorie),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 13, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(_tempsLecture(article),
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bouton circulaire translucide pour la barre supérieure.
  Widget _boutonRond({required FaIconData icone, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Center(child: FaIcon(icone, size: 16, color: Colors.white)),
      ),
    );
  }

  SliverToBoxAdapter _buildContenu(Article article) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre éditorial (serif)
            Text(
              article.titre,
              style: GoogleFonts.ptSerif(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.28,
                color: AppColors.texteFort,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Bandeau méta (source · date · vues)
            _buildMeta(article),
            const SizedBox(height: AppSpacing.lg),
            // Filet d'accent
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.vertPrimaire,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Corps de l'article
            Html(
              data: _getContenuHtml(article),
              extensions: [
                TagExtension(
                  tagsToExtend: {'figure'},
                  builder: _construireFigure,
                ),
              ],
              onLinkTap: (url, attrs, element) {
                if (url != null) {
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              },
              style: {
                'body': Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontSize: FontSize(16),
                  lineHeight: LineHeight(1.85),
                  color: AppColors.texteFort,
                  fontFamily: GoogleFonts.ptSerif().fontFamily,
                ),
                'p': Style(
                  textAlign: TextAlign.justify,
                  margin: Margins.only(bottom: 16),
                ),
                'h1': Style(
                    fontSize: FontSize(23),
                    fontWeight: FontWeight.w700,
                    color: AppColors.texteFort,
                    fontFamily: GoogleFonts.inter().fontFamily,
                    margin: Margins.only(bottom: 10, top: 20)),
                'h2': Style(
                    fontSize: FontSize(21),
                    fontWeight: FontWeight.w700,
                    color: AppColors.texteFort,
                    fontFamily: GoogleFonts.inter().fontFamily,
                    margin: Margins.only(bottom: 10, top: 18)),
                'h3': Style(
                    fontSize: FontSize(18.5),
                    fontWeight: FontWeight.w700,
                    color: AppColors.texteFort,
                    fontFamily: GoogleFonts.inter().fontFamily,
                    margin: Margins.only(bottom: 8, top: 16)),
                'h4': Style(
                    fontSize: FontSize(16.5),
                    fontWeight: FontWeight.w700,
                    color: AppColors.texteFort,
                    fontFamily: GoogleFonts.inter().fontFamily,
                    margin: Margins.only(bottom: 8, top: 14)),
                'ul': Style(margin: Margins.only(left: 18, bottom: 14)),
                'ol': Style(margin: Margins.only(left: 18, bottom: 14)),
                'li': Style(margin: Margins.only(bottom: 6), lineHeight: LineHeight(1.7)),
                'blockquote': Style(
                  backgroundColor: const Color(0xFFF3F8F4),
                  padding: HtmlPaddings.symmetric(horizontal: 16, vertical: 12),
                  margin: Margins.symmetric(vertical: 16),
                  border: Border(
                      left: BorderSide(color: AppColors.vertPrimaire, width: 4)),
                  fontStyle: FontStyle.italic,
                ),
                'strong': Style(fontWeight: FontWeight.w700),
                'em': Style(fontStyle: FontStyle.italic),
                'a': Style(
                    color: AppColors.vertFonce,
                    textDecoration: TextDecoration.underline,
                    textDecorationColor: AppColors.vertPrimaire),
                'img': Style(margin: Margins.symmetric(vertical: 12)),
                'figure': Style(margin: Margins.symmetric(vertical: 12)),
                'figcaption': Style(
                  fontSize: FontSize(12.5),
                  color: AppColors.grisTexte,
                  textAlign: TextAlign.center,
                  fontFamily: GoogleFonts.inter().fontFamily,
                  margin: Margins.only(top: 6),
                ),
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            // Bouton source originale
            if (article.lienSource.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Voir l\'article source'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.vertFonce,
                    side: BorderSide(color: AppColors.vertPrimaire.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle:
                        GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  onPressed: () => launchUrl(
                    Uri.parse(article.lienSource),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            _buildReseauxSociaux(),
          ],
        ),
      ),
    );
  }

  // Ligne méta avec pastilles "source / date / vues"
  Widget _buildMeta(Article article) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _metaItem(Icons.source_outlined, article.source),
        _metaItem(Icons.calendar_today_outlined, _formaterDate(article.datePublication)),
        _metaItem(Icons.remove_red_eye_outlined, '${article.vues} vues'),
      ],
    );
  }

  Widget _metaItem(IconData icone, String texte) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 14, color: AppColors.grisIcone),
        const SizedBox(width: 5),
        Text(texte,
            style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.grisTexte)),
      ],
    );
  }

  // Section "Suivez-nous" : 6 réseaux sociaux cliquables
  Widget _buildReseauxSociaux() {
    const reseaux = [
      (icone: FontAwesomeIcons.whatsapp, couleur: Color(0xFF25D366), url: 'https://whatsapp.com/channel/0029VaWrkLsBqbr71Q6DvW2y'),
      (icone: FontAwesomeIcons.xTwitter, couleur: Color(0xFF000000), url: 'https://x.com/agridigitale1'),
      (icone: FontAwesomeIcons.youtube, couleur: Color(0xFFFF0000), url: 'https://youtube.com/@agridigitaletv'),
      (icone: FontAwesomeIcons.facebookF, couleur: Color(0xFF1877F2), url: 'https://facebook.com/agridigitale'),
      (icone: FontAwesomeIcons.instagram, couleur: Color(0xFFE1306C), url: 'https://instagram.com/agridigitale'),
      (icone: FontAwesomeIcons.linkedin, couleur: Color(0xFF0A66C2), url: 'https://linkedin.com/company/agridigitale'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF7),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.grisLigne),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Suivez AgriDigitale',
              style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.texteFort)),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: reseaux
                .map((r) => GestureDetector(
                      onTap: () => launchUrl(Uri.parse(r.url),
                          mode: LaunchMode.externalApplication),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: r.couleur.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                            child: FaIcon(r.icone, color: r.couleur, size: 17)),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Commentaires ─────────────────────────────────────────────────────────────

  SliverToBoxAdapter _buildSectionCommentaires(AuthProvider auth) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Commentaires',
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.texteFort)),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.vertPrimaire.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text('${_commentaires.length}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.vertFonce)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Champ de saisie
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.grisLigne),
                boxShadow: AppShadow.douce,
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  TextField(
                    controller: _commentaireCtrl,
                    maxLines: 4,
                    minLines: 1,
                    maxLength: 1000,
                    enabled: auth.connecte,
                    onTap: !auth.connecte
                        ? () => exigerConnexion(context, motif: 'commenter')
                        : null,
                    style: GoogleFonts.inter(fontSize: 14.5, height: 1.5),
                    decoration: InputDecoration(
                      hintText: auth.connecte
                          ? 'Partagez votre point de vue...'
                          : 'Connectez-vous pour commenter',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.grisIcone),
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton.icon(
                        onPressed: (_envoi || !auth.connecte)
                            ? null
                            : _envoyerCommentaire,
                        icon: _envoi
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Publier'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.vertPrimaire,
                          disabledBackgroundColor:
                              AppColors.grisPastille,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                          textStyle: GoogleFonts.inter(
                              fontSize: 13.5, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_chargementCommentaires)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.vertPrimaire)),
              )
            else if (_commentaires.isEmpty)
              _etatVideCommentaires()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _commentaires.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, i) => _carteCommentaire(_commentaires[i], auth),
              ),
          ],
        ),
      ),
    );
  }

  Widget _etatVideCommentaires() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF7),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          const Icon(Icons.forum_outlined, size: 32, color: AppColors.grisIcone),
          const SizedBox(height: AppSpacing.sm),
          Text('Soyez le premier à commenter',
              style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.grisTexte)),
        ],
      ),
    );
  }

  Widget _carteCommentaire(Commentaire c, AuthProvider auth) {
    final estMien = auth.connecte && auth.nomUtilisateur == c.nomAuteur;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.grisLigne),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.vertPrimaire, AppColors.vertFonce],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                c.nomAuteur.isNotEmpty ? c.nomAuteur[0].toUpperCase() : '?',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(c.nomAuteur,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, fontSize: 13.5)),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('· ${_tempsRelatif(c.createdAt)}',
                        style: GoogleFonts.inter(
                            fontSize: 11.5, color: AppColors.grisIcone)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(c.contenu,
                    style: GoogleFonts.inter(fontSize: 14, height: 1.5)),
              ],
            ),
          ),
          if (estMien)
            InkWell(
              onTap: () => _supprimerCommentaire(c),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.xs),
                child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
              ),
            ),
        ],
      ),
    );
  }

  // ── À lire aussi ─────────────────────────────────────────────────────────────

  Widget _buildAutresArticles(Article courant) {
    return FutureBuilder<List<Article>>(
      future: _autresFuture,
      builder: (context, snap) {
        if (!snap.hasData) return const SliverToBoxAdapter(child: SizedBox.shrink());
        final autres =
            snap.data!.where((a) => a.id != widget.articleId).take(5).toList();
        if (autres.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              if (i == 0) return _enteteSimilaires();
              return _carteArticleSimilaire(autres[i - 1]);
            },
            childCount: autres.length + 1,
          ),
        );
      },
    );
  }

  Widget _enteteSimilaires() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.vertPrimaire,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('À lire aussi',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.texteFort)),
        ],
      ),
    );
  }

  Widget _carteArticleSimilaire(Article a) {
    final hasImage = a.image != null && a.image!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ArticleDetailScreen(articleId: a.id)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.grisLigne),
            boxShadow: AppShadow.douce,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 104,
                    height: double.infinity,
                    child: hasImage
                        ? CachedNetworkImage(
                            imageUrl: a.image!,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => _skeletonImage(0),
                            errorWidget: (_, _, _) =>
                                Container(color: AppColors.grisPastille),
                          )
                        : Container(
                            color: const Color(0xFFEDF3EE),
                            child: const Icon(Icons.article_outlined,
                                color: AppColors.vertPrimaire),
                          ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            a.categorie.toUpperCase(),
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _couleurCategorie(a.categorie),
                                letterSpacing: 0.5),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            a.titre,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.ptSerif(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                                color: AppColors.texteFort),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 11, color: AppColors.grisIcone),
                              const SizedBox(width: 4),
                              Text(_tempsRelatif(a.datePublication),
                                  style: GoogleFonts.inter(
                                      fontSize: 11, color: AppColors.grisIcone)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
