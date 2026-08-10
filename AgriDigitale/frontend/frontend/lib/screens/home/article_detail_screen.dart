import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/article_service.dart';
import '../../services/favori_service.dart';
import '../../services/commentaire_service.dart';
import '../../models/article.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_gate.dart';
import '../../core/design/app_colors.dart';

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
  }

  @override
  void dispose() {
    _commentaireCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
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

  void _partagerArticle(Article article) {
    final lien = article.lienSource.isNotEmpty
        ? article.lienSource
        : 'https://agridigitale.com/articles/${article.id}';
    final texte = '${article.titre}\n$lien';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Partager via',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
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
                  label: 'X / Twitter',
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
                  label: 'Copier lien',
                  couleur: Colors.grey.shade700,
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: lien));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lien copié !')),
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
    required IconData icone,
    required String label,
    required Color couleur,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: couleur.withValues(alpha: 0.12),
            child: FaIcon(icone, color: couleur, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
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
          const SnackBar(content: Text('Ajoute aux favoris'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted && e.toString().contains('409')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deja dans vos favoris')),
        );
      }
    } finally {
      if (mounted) setState(() => _favoriTraite = false);
    }
  }

  String _formaterDate(DateTime date) {
    try {
      return DateFormat('dd MMM yyyy · HH:mm', 'fr_FR').format(date);
    } catch (_) {
      return '${date.day}/${date.month}/${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  String _tempsRelatif(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return '${date.day}/${date.month}/${date.year}';
  }

  // Retourne le contenu HTML à afficher — contenu complet en priorité, résumé en fallback
  String _getContenuHtml(Article article) {
    final texte = article.contenu.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    if (texte.isNotEmpty) return article.contenu;
    if (article.resume.isNotEmpty) return '<p>${article.resume}</p>';
    return '<p>Contenu non disponible.</p>';
  }

  Widget _imagePlaceholder() => Container(
        color: Colors.green.shade100,
        child: const Icon(Icons.article, size: 80, color: Colors.green),
      );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: FutureBuilder<Article>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Impossible de charger l\'article'),
                  TextButton(
                    onPressed: () {
                      final future = _articleService.detail(widget.articleId);
                      setState(() => _future = future);
                    },
                    child: const Text('Reessayer'),
                  ),
                ],
              ),
            );
          }
          final article = snapshot.data!;
          return CustomScrollView(
            controller: _scrollCtrl,
            slivers: [
              _buildAppBar(article),
              _buildContenu(article),
              _buildSectionCommentaires(auth),
              _buildAutresArticles(),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(Article article) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.vertPrimaire,
      flexibleSpace: FlexibleSpaceBar(
        background: (article.image != null && article.image!.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: article.image!,
                fit: BoxFit.cover,
              errorWidget: (ctx, url, err) => _imagePlaceholder(),
              )
            : _imagePlaceholder(),
      ),
      actions: [
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.shareNodes, color: Colors.white, size: 20),
          onPressed: () => _partagerArticle(article),
        ),
        IconButton(
          icon: _favoriTraite
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.favorite_border, color: Colors.white),
          onPressed: _favoriTraite ? null : () => _basculerFavori(article),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildContenu(Article article) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge catégorie
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                article.categorie.toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),
            const SizedBox(height: 12),
            // Titre
            Text(
              article.titre,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
            ),
            const SizedBox(height: 8),
            // Date + vues
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(_formaterDate(article.datePublication),
                    style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                const SizedBox(width: 16),
                Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text('${article.vues} vues',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ],
            ),
            const Divider(height: 28),
            // Contenu HTML complet — PAS de IntrinsicHeight qui casse le rendu
            Html(
              data: _getContenuHtml(article),
              onLinkTap: (url, attrs, element) {
                if (url != null) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
              style: {
                'body': Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontSize: FontSize(15.5),
                  lineHeight: LineHeight(1.7),
                ),
                'p': Style(
                  textAlign: TextAlign.justify,
                  margin: Margins.only(bottom: 14),
                ),
                'h1': Style(fontSize: FontSize(22), fontWeight: FontWeight.bold, margin: Margins.only(bottom: 10, top: 16)),
                'h2': Style(fontSize: FontSize(20), fontWeight: FontWeight.bold, margin: Margins.only(bottom: 10, top: 14)),
                'h3': Style(fontSize: FontSize(18), fontWeight: FontWeight.bold, margin: Margins.only(bottom: 8, top: 12)),
                'h4': Style(fontSize: FontSize(16), fontWeight: FontWeight.bold, margin: Margins.only(bottom: 8, top: 10)),
                'ul': Style(margin: Margins.only(left: 16, bottom: 12)),
                'ol': Style(margin: Margins.only(left: 16, bottom: 12)),
                'li': Style(margin: Margins.only(bottom: 6), lineHeight: LineHeight(1.6)),
                'blockquote': Style(
                  backgroundColor: Colors.grey[100],
                  padding: HtmlPaddings.symmetric(horizontal: 14, vertical: 10),
                  margin: Margins.symmetric(vertical: 12),
                  border: Border(left: BorderSide(color: AppColors.vertPrimaire, width: 4)),
                  fontStyle: FontStyle.italic,
                ),
                'strong': Style(fontWeight: FontWeight.bold),
                'em': Style(fontStyle: FontStyle.italic),
                'a': Style(color: AppColors.vertPrimaire, textDecoration: TextDecoration.underline),
                'img': Style(
                  width: Width(double.infinity),
                  margin: Margins.symmetric(vertical: 10),
                ),
                'figure': Style(margin: Margins.symmetric(vertical: 10)),
                'figcaption': Style(
                  fontSize: FontSize(12),
                  color: Colors.grey[600],
                  textAlign: TextAlign.center,
                  margin: Margins.only(top: 4),
                ),
              },
            ),
            const SizedBox(height: 20),
            // Bouton source originale
            if (article.lienSource.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Voir la source originale'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.vertPrimaire,
                    side: const BorderSide(color: AppColors.vertPrimaire),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => launchUrl(
                    Uri.parse(article.lienSource),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            _buildReseauxSociaux(),
          ],
        ),
      ),
    );
  }

  Widget _buildReseauxSociaux() {
    const reseaux = [
      (icone: FontAwesomeIcons.whatsapp,  couleur: Color(0xFF25D366), url: 'https://whatsapp.com/channel/0029VaWrkLsBqbr71Q6DvW2y'),
      (icone: FontAwesomeIcons.xTwitter,  couleur: Color(0xFF000000), url: 'https://x.com/agridigitale1'),
      (icone: FontAwesomeIcons.youtube,   couleur: Color(0xFFFF0000), url: 'https://youtube.com/@agridigitaletv'),
      (icone: FontAwesomeIcons.facebookF, couleur: Color(0xFF1877F2), url: 'https://facebook.com/agridigitale'),
      (icone: FontAwesomeIcons.instagram, couleur: Color(0xFFE1306C), url: 'https://instagram.com/agridigitale'),
      (icone: FontAwesomeIcons.linkedin,  couleur: Color(0xFF0A66C2), url: 'https://linkedin.com/company/agridigitale'),
    ];
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            const Text('Suivez-nous',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: reseaux.map((r) => GestureDetector(
                  onTap: () => launchUrl(Uri.parse(r.url), mode: LaunchMode.externalApplication),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: r.couleur.withValues(alpha: 0.12),
                    child: FaIcon(r.icone, color: r.couleur, size: 14),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      );
  }

  SliverToBoxAdapter _buildSectionCommentaires(AuthProvider auth) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.grey[50],
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.comment_outlined, color: AppColors.vertPrimaire),
                const SizedBox(width: 8),
                Text('Commentaires (${_commentaires.length})',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentaireCtrl,
                    maxLines: 3,
                    minLines: 1,
                    maxLength: 1000,
                    enabled: auth.connecte,
                    onTap: !auth.connecte
                        ? () => exigerConnexion(context, motif: 'commenter')
                        : null,
                    decoration: InputDecoration(
                      hintText: auth.connecte
                          ? 'Ecrire un commentaire...'
                          : 'Connectez-vous pour commenter',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _envoi ? null : _envoyerCommentaire,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vertPrimaire,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: _envoi
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_chargementCommentaires)
              const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire))
            else if (_commentaires.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('Soyez le premier a commenter !',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _commentaires.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final c = _commentaires[i];
                  final estMien = auth.connecte && auth.nomUtilisateur == c.nomAuteur;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.vertPrimaire,
                      radius: 18,
                      child: Text(
                        c.nomAuteur.isNotEmpty ? c.nomAuteur[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(c.nomAuteur,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(width: 8),
                        Text(_tempsRelatif(c.createdAt),
                            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(c.contenu,
                          style: const TextStyle(fontSize: 14, height: 1.4)),
                    ),
                    trailing: estMien
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            onPressed: () => _supprimerCommentaire(c),
                          )
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutresArticles() {
    return FutureBuilder<List<Article>>(
      future: _autresFuture,
      builder: (context, snap) {
        if (!snap.hasData) return const SliverToBoxAdapter(child: SizedBox.shrink());
        final autres = snap.data!.where((a) => a.id != widget.articleId).take(5).toList();
        if (autres.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final a = autres[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (a.image != null && a.image!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: a.image!,
                          width: 72, height: 56, fit: BoxFit.cover,
                          errorWidget: (ctx, url, err) => Container(
                            width: 72, height: 56, color: Colors.green[50],
                            child: const Icon(Icons.article, color: Colors.green),
                          ),
                        )
                      : Container(
                          width: 72, height: 56, color: Colors.green[50],
                          child: const Icon(Icons.article, color: Colors.green),
                        ),
                ),
                title: Text(a.titre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(a.categorie,
                    style: const TextStyle(fontSize: 11, color: AppColors.vertPrimaire)),
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ArticleDetailScreen(articleId: a.id)),
                ),
              );
            },
            childCount: autres.length,
          ),
        );
      },
    );
  }
}
