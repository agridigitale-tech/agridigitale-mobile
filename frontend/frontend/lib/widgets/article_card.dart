import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/article.dart';
import '../screens/home/article_detail_screen.dart';
import '../services/favori_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_gate.dart';

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

  String _formaterDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _toggleFavori() async {
    final connecte = await exigerConnexion(context, motif: 'enregistrer cet article');
    if (!connecte) return;

    setState(() => _enCours = true);
    try {
      if (_enFavori) {
        await _favoriService.retirer(widget.article.id);
        setState(() => _enFavori = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Retiré des favoris'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        await _favoriService.ajouter(widget.article);
        setState(() => _enFavori = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Article enregistré dans vos favoris'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('409')
                ? 'Déjà dans vos favoris'
                : 'Erreur lors de l\'enregistrement'),
            backgroundColor: Colors.orange,
          ),
        );
        // Si déjà en favori côté serveur, mettre à jour l'état local
        if (e.toString().contains('409')) {
          setState(() => _enFavori = true);
        }
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final imageUrl = widget.article.image;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: widget.onTap ??
            () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ArticleDetailScreen(articleId: widget.article.id),
                  ),
                ),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          httpHeaders: const {
                            'Accept': 'image/*',
                          },
                          placeholder: (_, _) => Container(
                            height: 180,
                            color: Colors.grey[200],
                            child: const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.green)),
                          ),
                          errorWidget: (context, url, err) {
                            return Container(
                              height: 180,
                              color: Colors.green[50],
                              child: const Icon(Icons.article,
                                  size: 60, color: Colors.green),
                            );
                          },
                        )
                      : Container(
                          height: 180,
                          color: Colors.green[50],
                          child: const Icon(Icons.article,
                              size: 60, color: Colors.green),
                        ),
                ),
                // Bouton favori
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _toggleFavori,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          )
                        ],
                      ),
                      child: _enCours
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.green))
                          : Icon(
                              (auth.connecte && _enFavori)
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              size: 20,
                              color: Colors.green,
                            ),
                    ),
                  ),
                ),
              ],
            ),

            // Contenu
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.article.categorie.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.article.titre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  if (widget.article.resume.isNotEmpty)
                    Text(
                      widget.article.resume,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formaterDate(widget.article.datePublication),
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      Row(children: [
                        Icon(Icons.remove_red_eye_outlined,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text('${widget.article.vues}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
