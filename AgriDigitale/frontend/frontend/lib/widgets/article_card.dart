import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/article.dart';
import '../core/design/app_colors.dart';
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
      if (mounted && e.toString().contains('409')) {
        setState(() => _enFavori = true);
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  String _formaterDate(DateTime date) {
    try {
      return DateFormat('dd MMM yyyy · HH:mm', 'fr_FR').format(date);
    } catch (_) {
      return '${date.day}/${date.month}/${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final imageUrl = widget.article.image;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image verticale à gauche ──
              SizedBox(
                width: 140,
                height: double.infinity,
                child: hasImage
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.vertPrimaire),
                          ),
                        ),
                        errorWidget: (ctx, url, err) => Container(
                          color: Colors.green[50],
                          child: const Icon(Icons.article,
                              size: 48, color: AppColors.vertPrimaire),
                        ),
                      )
                    : Container(
                        color: Colors.green[50],
                        child: const Icon(Icons.article,
                            size: 48, color: AppColors.vertPrimaire),
                      ),
              ),

              // ── Contenu à droite ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge catégorie + bouton favori
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.vertPrimaire.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.article.categorie.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.vertPrimaire,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                          GestureDetector(
                            onTap: _toggleFavori,
                            child: _enCours
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.vertPrimaire))
                                : Icon(
                                    (auth.connecte && _enFavori)
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    size: 20,
                                    color: AppColors.vertPrimaire,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Titre
                      Text(
                        widget.article.titre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Résumé
                      Expanded(
                        child: Text(
                          widget.article.resume,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ),

                      // Date + vues
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 11, color: Colors.grey[400]),
                          const SizedBox(width: 3),
                          Text(
                            _formaterDate(widget.article.datePublication),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[400]),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.remove_red_eye_outlined,
                              size: 11, color: Colors.grey[400]),
                          const SizedBox(width: 3),
                          Text(
                            '${widget.article.vues}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[400]),
                          ),
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
    );
  }
}
