//permet de gérer l'affichage du détail d'un article avec son image, son titre, son contenu et un bouton pour ajouter aux favoris

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../services/article_service.dart';
import '../../services/favori_service.dart';
import '../../models/article.dart';
import '../../widgets/auth_gate.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String articleId;
  const ArticleDetailScreen({super.key, required this.articleId});
  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final _articleService = ArticleService();
  final _favoriService = FavoriService();
  late Future<Article> _future;
  bool _favoriTraite = false;

  @override
  void initState() {
    super.initState();
    _future = _articleService.detail(widget.articleId);
  }

   Future<void> _basculerFavori(Article article) async {
     // Vérifier si l'utilisateur est connecté avant d'ajouter aux favoris
     final connecte = await exigerConnexion(context, motif: "ajouter cet article à vos favoris");
     if (!connecte) return;

     setState(() => _favoriTraite = true);
     try {
       await _favoriService.ajouter(article);
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Ajouté aux favoris')));
     } catch (_) {
       // déjà en favoris ou erreur réseau : on ignore silencieusement ici, gérable via un état plus fin
     } finally {
       if (mounted) setState(() => _favoriTraite = false);
     }
   }
   String _formaterDate(DateTime date) {
    try {
      return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
    } catch (e) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Article>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final article = snapshot.data!;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: article.image != null
                      ? CachedNetworkImage(imageUrl: article.image!, fit: BoxFit.cover)
                      : Container(color: Colors.green.shade100),
                ),
                actions: [
                  IconButton(
                    icon: _favoriTraite
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.favorite_border),
                    onPressed: _favoriTraite ? null : () => _basculerFavori(article),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(article.titre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(article.contenu ?? article.resume, style: const TextStyle(fontSize: 16, height: 1.5)),
                      const SizedBox(height: 20),
                      if (article.lienSource != null)
                        TextButton.icon(
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Voir la source originale'),
                          onPressed: () => launchUrl(Uri.parse(article.lienSource!)),
                        ),
                    ], 
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}