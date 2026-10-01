// Widgets de carte article utilisés dans HomeScreen.
// ArticleCardVerticale : grande image en haut, utilisée dans le scroll horizontal "À ne pas manquer".
// ArticleCard : image à gauche (format compact), utilisée dans la liste verticale "Dernières actualités".
// _imgUrl() : sur le web, redirige les images via le proxy backend pour éviter les erreurs CORS.
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/article.dart';
import '../core/design/app_colors.dart';
import '../core/api_client.dart';
import '../services/favori_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_gate.dart';

// Retourne l'URL de l'image :
// - mobile : URL directe (pas de restriction CORS)
// - web : passe par le proxy backend /api/proxy-image pour éviter les erreurs CORS
String _imgUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.contains('/proxy-image')) return url; // déjà proxifié
  return '${ApiClient.baseUrl}/proxy-image?url=${Uri.encodeComponent(url)}';
}

// Couleur du badge catégorie selon la catégorie de l'article
Color _couleurCategorie(String cat) {
  switch (cat.toLowerCase()) {
    case 'togo': return const Color(0xFF2E7D32);
    case 'afrique': return const Color(0xFFE65100);
    case 'monde': return const Color(0xFF1565C0);
    default: return AppColors.vertPrimaire;
  }
}

// Card verticale : image 130px en haut + badge catégorie + titre + date/vues.
// Utilisée dans le scroll horizontal "À ne pas manquer" (top 6 par vues).
class ArticleCardVerticale extends StatelessWidget {
  final Article article;
  final VoidCallback? onTap;
  final double width;

  const ArticleCardVerticale({super.key, required this.article, this.onTap, this.width = 220});

  @override
  Widget build(BuildContext context) {
    final hasImage = article.image != null && article.image!.isNotEmpty;
    final couleur = _couleurCategorie(article.categorie);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Stack(
                children: [
                  SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: hasImage
                        ? CachedNetworkImage(imageUrl: _imgUrl(article.image), fit: BoxFit.cover,
                            httpHeaders: const {'User-Agent': 'Mozilla/5.0'},
                            errorWidget: (_, __, ___) => _placeholder())
                        : _placeholder(),
                  ),
                  Positioned(
                    top: 8, left: 8,
                    child: _badgeCategorie(article.categorie, couleur),
                  ),
                ],
              ),
              // Contenu
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article.titre, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.3)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.access_time, size: 10, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Text(_date(article.datePublication), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                      const SizedBox(width: 8),
                      Icon(Icons.remove_red_eye_outlined, size: 10, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Text('${article.vues}', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                    ]),
                    const SizedBox(height: 3),
                    Row(children: [
                      Icon(Icons.source_outlined, size: 10, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Text(article.source, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Card horizontale compacte : image 110x110 à gauche + titre + résumé + bouton favori.
// Utilisée dans la liste verticale "Dernières actualités".
class ArticleCard extends StatefulWidget {
  final Article article;
  final VoidCallback? onTap;

  const ArticleCard({super.key, required this.article, this.onTap});

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
  final _favoriService = FavoriService();
  bool _enCours = false;
  bool _enFavori = false;

  @override
  void initState() {
    super.initState();
    _verifierFavori();
  }

  Future<void> _verifierFavori() async {
    final estFavori = await _favoriService.estEnFavori(widget.article.id);
    if (mounted) setState(() => _enFavori = estFavori);
  }

  Future<void> _toggleFavori() async {
    final connecte = await exigerConnexion(context, motif: 'enregistrer cet article');
    if (!connecte) return;
    setState(() => _enCours = true);
    try {
      if (_enFavori) {
        await _favoriService.retirer(widget.article.id);
        if (mounted) setState(() => _enFavori = false);
      } else {
        await _favoriService.ajouter(widget.article);
        if (mounted) setState(() => _enFavori = true);
      }
    } catch (e) {
      if (mounted && e.toString().contains('409')) setState(() => _enFavori = true);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final hasImage = widget.article.image != null && widget.article.image!.isNotEmpty;
    final couleur = _couleurCategorie(widget.article.categorie);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Image gauche (hauteur 100% pour éviter l'overflow avec texte agrandi)
              Stack(
                children: [
                  SizedBox(
                    width: 110,
                    height: double.infinity,
                    child: hasImage
                        ? CachedNetworkImage(imageUrl: _imgUrl(widget.article.image), fit: BoxFit.cover,
                            httpHeaders: const {'User-Agent': 'Mozilla/5.0'},
                            errorWidget: (_, __, ___) => _placeholder())
                        : _placeholder(),
                  ),
                  Positioned(
                    bottom: 6, left: 6,
                    child: _badgeCategorie(widget.article.categorie, couleur),
                  ),
                ],
              ),
              // Contenu droite
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(widget.article.titre, maxLines: 3, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.35)),
                          ),
                          GestureDetector(
                            onTap: _toggleFavori,
                            child: _enCours
                                ? const SizedBox(width: 18, height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.vertPrimaire))
                                : Icon(
                                    (auth.connecte && _enFavori) ? Icons.bookmark : Icons.bookmark_border,
                                    size: 20, color: AppColors.vertPrimaire),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(widget.article.resume, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.access_time, size: 10, color: Colors.grey[400]),
                        const SizedBox(width: 3),
                        Text(_date(widget.article.datePublication),
                            style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                        const SizedBox(width: 8),
                        Icon(Icons.remove_red_eye_outlined, size: 10, color: Colors.grey[400]),
                        const SizedBox(width: 3),
                        Text('${widget.article.vues}', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                      ]),
                      const SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.source_outlined, size: 10, color: Colors.grey[400]),
                        const SizedBox(width: 3),
                        Text(widget.article.source, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ──
Widget _placeholder() => Container(
    color: Colors.green[50],
    child: const Center(child: Icon(Icons.article, size: 36, color: AppColors.vertPrimaire)));

Widget _badgeCategorie(String cat, Color couleur) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(20)),
    child: Text(cat.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)));

String _date(DateTime date) {
  try { return DateFormat('dd MMM · HH:mm', 'fr_FR').format(date); }
  catch (_) { return '${date.day}/${date.month}/${date.year}'; }
}
