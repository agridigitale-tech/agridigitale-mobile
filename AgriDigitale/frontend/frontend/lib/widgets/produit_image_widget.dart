import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/design/app_colors.dart';

/// Helper pour associer intelligemment chaque denrée agricole à sa vraie photo
class ProduitImageHelper {
  /// Bibliothèque officielle des images locales de céréales et vivres
  static const List<Map<String, String>> imagesDisponibles = [
    {
      'id': 'neutre',
      'nom': 'Image neutre (Défaut)',
      'fichier': 'neutre',
    },
    {
      'id': 'mais',
      'nom': 'Maïs (blanc / jaune)',
      'fichier': 'assets/images/cereales/mais.jpg',
    },
    {
      'id': 'soja',
      'nom': 'Soja grain',
      'fichier': 'assets/images/cereales/soja.jpeg',
    },
    {
      'id': 'haricot',
      'nom': 'Haricot (Niébé / local)',
      'fichier': 'assets/images/cereales/haricot.jpg',
    },
    {
      'id': 'haricot_grand',
      'nom': 'Haricot de grande taille',
      'fichier': 'assets/images/cereales/haricot_grand_tail.jpg',
    },
    {
      'id': 'mil',
      'nom': 'Mil (pénicillaire / local)',
      'fichier': 'assets/images/cereales/mil.webp',
    },
    {
      'id': 'sorgho',
      'nom': 'Sorgho (rouge / blanc)',
      'fichier': 'assets/images/cereales/sorgho.jpeg',
    },
    {
      'id': 'arachide',
      'nom': 'Arachides (décortiquées / coque)',
      'fichier': 'assets/images/cereales/arachide.jpg',
    },
    {
      'id': 'voandzou',
      'nom': 'Voandzou (Pois de terre)',
      'fichier': 'assets/images/cereales/voandzou.jpeg',
    },
    {
      'id': 'gari',
      'nom': 'Gari blanc fin',
      'fichier': 'assets/images/cereales/gari.jpg',
    },
    {
      'id': 'tomate',
      'nom': 'Tomate (ronde / locale)',
      'fichier': 'assets/images/cereales/tomate.jpeg',
    },
    {
      'id': 'piment_frais',
      'nom': 'Piment frais / vert',
      'fichier': 'assets/images/cereales/piment_frais.jpeg',
    },
    {
      'id': 'piment_guinee',
      'nom': 'Piment de Guinée',
      'fichier': 'assets/images/cereales/piment_de_guinée.jpg',
    },
    {
      'id': 'igname',
      'nom': 'Igname (Laboco / douce)',
      'fichier': 'assets/images/cereales/igname.jpg',
    },
    {
      'id': 'manioc',
      'nom': 'Manioc frais',
      'fichier': 'assets/images/cereales/manioc.jpeg',
    },
  ];

  /// Résolution intelligente de l'image à afficher
  static String? getImagePath(String nomProduit, {String? iconeOuImage}) {
    // 1. Choix neutre explicite
    if (iconeOuImage == 'neutre') {
      return 'neutre';
    }

    // 2. Si un chemin d'asset local, fichier ou URL http est déjà spécifié
    if (iconeOuImage != null && iconeOuImage.isNotEmpty) {
      if (iconeOuImage.startsWith('/uploads/')) {
        return 'https://agridigitale-mobile.onrender.com$iconeOuImage';
      }
      if (iconeOuImage.startsWith('http') ||
          iconeOuImage.startsWith('assets/') ||
          iconeOuImage.startsWith('/data/') ||
          iconeOuImage.startsWith('/storage/')) {
        return iconeOuImage;
      }
    }

    final nom = nomProduit.toLowerCase();

    // 3. Correspondance par mot-clé sur les dénominations togolaises courantes
    if (nom.contains('maïs') || nom.contains('mais')) {
      return 'assets/images/cereales/mais.jpg';
    }
    if (nom.contains('soja')) {
      return 'assets/images/cereales/soja.jpeg';
    }
    if (nom.contains('grande taille') || nom.contains('grand')) {
      return 'assets/images/cereales/haricot_grand_tail.jpg';
    }
    if (nom.contains('haricot') || nom.contains('niébé') || nom.contains('niebe')) {
      return 'assets/images/cereales/haricot.jpg';
    }
    if (nom.contains('voandzou')) {
      return 'assets/images/cereales/voandzou.jpeg';
    }
    if (nom.contains('arachide')) {
      return 'assets/images/cereales/arachide.jpg';
    }
    if (nom.contains('mil')) {
      return 'assets/images/cereales/mil.webp';
    }
    if (nom.contains('sorgho')) {
      return 'assets/images/cereales/sorgho.jpeg';
    }
    if (nom.contains('gari')) {
      return 'assets/images/cereales/gari.jpg';
    }
    if (nom.contains('tomate')) {
      return 'assets/images/cereales/tomate.jpeg';
    }
    if (nom.contains('piment frais') || nom.contains('piment vert')) {
      return 'assets/images/cereales/piment_frais.jpeg';
    }
    if (nom.contains('piment') || nom.contains('guinée') || nom.contains('guinee')) {
      return 'assets/images/cereales/piment_de_guinée.jpg';
    }
    if (nom.contains('igname')) {
      return 'assets/images/cereales/igname.jpg';
    }
    if (nom.contains('manioc')) {
      return 'assets/images/cereales/manioc.jpeg';
    }

    return null;
  }
}

/// Widget affichant la vraie photo de la denrée avec design élégant et moderne
class ProduitImageWidget extends StatelessWidget {
  final String nomProduit;
  final String? imageOuIcone;
  final double size;
  final double borderRadius;

  const ProduitImageWidget({
    super.key,
    required this.nomProduit,
    this.imageOuIcone,
    this.size = 46,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final path = ProduitImageHelper.getImagePath(nomProduit, iconeOuImage: imageOuIcone);

    Widget imageContent;

    if (path == 'neutre') {
      imageContent = _buildFallback(isDark);
    } else if (path != null && path.startsWith('http')) {
      imageContent = CachedNetworkImage(
        imageUrl: path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: size,
          height: size,
          color: isDark ? AppColors.surfaceSombreLegere : Colors.grey.shade100,
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.vertPrimaire),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _buildFallback(isDark),
      );
    } else if (path != null && path.startsWith('/') && File(path).existsSync()) {
      imageContent = Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(isDark),
      );
    } else if (path != null && path.isNotEmpty && path.startsWith('assets/')) {
      imageContent = Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(isDark),
      );
    } else {
      imageContent = _buildFallback(isDark);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1),
        child: imageContent,
      ),
    );
  }

  Widget _buildFallback(bool isDark) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E2E22), const Color(0xFF283B2C)]
              : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.eco_rounded,
            color: isDark ? AppColors.vertClair : AppColors.vertPrimaire,
            size: size * 0.45,
          ),
        ],
      ),
    );
  }
}
