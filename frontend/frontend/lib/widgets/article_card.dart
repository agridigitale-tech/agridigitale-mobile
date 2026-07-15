//permet de créer une carte d'article avec image, titre, catégorie et date de publication

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/article.dart';
import '../core/design/app_colors.dart';

class ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;
  const ArticleCard({super.key, required this.article, required this.onTap});

  bool get _aUneImageValide =>
      article.image != null && article.image!.trim().isNotEmpty && article.image!.startsWith('http');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _aUneImageValide
                  ? CachedNetworkImage(
                      imageUrl: article.image!,
                      width: 90, height: 90, fit: BoxFit.cover,
                      placeholder: (_, __) => Container(width: 90, height: 90, color: AppColors.grisPastille),
                      errorWidget: (_, __, ___) => _iconeParDefaut(), // si l'URL casse au chargement réel
                    )
                  : _iconeParDefaut(), // pas d'image du tout : jamais un carré blanc/cassé
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.categorie.toUpperCase(),
                    style: const TextStyle(color: AppColors.vertPrimaire, fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(article.titre, maxLines: 3, overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(_formaterDate(article.datePublication),
                    style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

   Widget _iconeParDefaut() => Container(
     width: 90, height: 90, color: AppColors.grisPastille,
     child: const Icon(Icons.eco, color: AppColors.vertPrimaire, size: 30),
   );

   String _formaterDate(DateTime date) {
     try {
       return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
     } catch (e) {
       return '${date.day}/${date.month}/${date.year}';
     }
   }
}
