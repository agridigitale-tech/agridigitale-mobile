// Système de Grades et Rangs du Quiz Agricole (de Novice à Légende).
// Progression basée sur les 100 niveaux et les 10 zones thématiques.
// Zéro émoticônes : 100% icônes vectorielles Material et typographie percutante.

import 'package:flutter/material.dart';

class QuizGrade {
  final int niveauRequis;
  final int niveauDebut;
  final int niveauFin;
  final String titre;
  final String sousTitre;
  final String nomZone;
  final IconData icone;
  final Color couleur;
  final List<Color> degrade;
  final Color couleurOmbre;
  final Color couleurFond;
  final String illustrationUrl;
  final String description;

  const QuizGrade({
    required this.niveauRequis,
    required this.niveauDebut,
    required this.niveauFin,
    required this.titre,
    required this.sousTitre,
    required this.nomZone,
    required this.icone,
    required this.couleur,
    required this.degrade,
    required this.couleurOmbre,
    required this.couleurFond,
    required this.illustrationUrl,
    required this.description,
  });

  /// Liste officielle des 10 grades du jeu (du Niveau 1 au Niveau 100)
  static const List<QuizGrade> tousLesGrades = [
    // 1. Novice de la Terre : Niveaux 1 à 9 (Thème Vert Clair)
    QuizGrade(
      niveauRequis: 1,
      niveauDebut: 1,
      niveauFin: 9,
      titre: 'Novice de la Terre',
      sousTitre: 'Premiers pas dans l\'art agricole',
      nomZone: 'Zone Terres & Semis',
      icone: Icons.yard_rounded,
      couleur: Color(0xFF4CAF50), // Vert clair
      degrade: [Color(0xFF81C784), Color(0xFF43A047)],
      couleurOmbre: Color(0xFF2E7D32),
      couleurFond: Color(0xFFE8F5E9),
      illustrationUrl: 'https://images.unsplash.com/photo-1592417817098-8f3d69104a47?w=800&q=80&auto=format&fit=crop',
      description: 'Vous débutez votre voyage agronomique. Vous découvrez les secrets de la terre, du compost et du démarrage des plants.',
    ),

    // 2. Apprenti Planteur : Niveaux 10 à 19 (Vert Forêt / Émeraude)
    QuizGrade(
      niveauRequis: 10,
      niveauDebut: 10,
      niveauFin: 19,
      titre: 'Apprenti Planteur',
      sousTitre: 'Grandes cultures & céréales',
      nomZone: 'Zone Grandes Moissons',
      icone: Icons.grass_rounded,
      couleur: Color(0xFF2E7D32),
      degrade: [Color(0xFF43A047), Color(0xFF1B5E20)],
      couleurOmbre: Color(0xFF0F4214),
      couleurFond: Color(0xFFC8E6C9),
      illustrationUrl: 'https://images.unsplash.com/photo-1551754655-cd27e38d2076?w=800&q=80&auto=format&fit=crop',
      description: 'Le maïs, le sorgho, le riz pluvial et les légumineuses n\'ont plus de secret pour vous.',
    ),

    // 3. Maraîcher Pratiquant : Niveaux 20 à 29 (Teal / Sarcelle)
    QuizGrade(
      niveauRequis: 20,
      niveauDebut: 20,
      niveauFin: 29,
      titre: 'Maraîcher Pratiquant',
      sousTitre: 'Légumes et cultures vivrières',
      nomZone: 'Zone Maraîchage Vivrier',
      icone: Icons.eco_rounded,
      couleur: Color(0xFF00897B),
      degrade: [Color(0xFF26A69A), Color(0xFF00695C)],
      couleurOmbre: Color(0xFF004D40),
      couleurFond: Color(0xFFE0F2F1),
      illustrationUrl: 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=800&q=80&auto=format&fit=crop',
      description: 'Vous pilotez avec brio tomates, piments, oignons, gombos et légumes-feuilles de saison et contre-saison.',
    ),

    // 4. Arboriculteur Averti : Niveaux 30 à 39 (Vert Olive / Pomme)
    QuizGrade(
      niveauRequis: 30,
      niveauDebut: 30,
      niveauFin: 39,
      titre: 'Arboriculteur Averti',
      sousTitre: 'Vergers et cultures pérennes',
      nomZone: 'Zone Vergers & Arbres',
      icone: Icons.park_rounded,
      couleur: Color(0xFF689F38),
      degrade: [Color(0xFF8BC34A), Color(0xFF558B2F)],
      couleurOmbre: Color(0xFF33691E),
      couleurFond: Color(0xFFDCEDC8),
      illustrationUrl: 'https://images.unsplash.com/photo-1618897996318-5a901fa6ca71?w=800&q=80&auto=format&fit=crop',
      description: 'Anacardiers, palmiers à huile, caféiers, cacaoyers et manguiers s\'épanouissent sous vos soins experts.',
    ),

    // 5. Maître de l'Irrigation : Niveaux 40 à 49 (Bleu Azur / Cyan Aquatique)
    QuizGrade(
      niveauRequis: 40,
      niveauDebut: 40,
      niveauFin: 49,
      titre: 'Maître de l\'Irrigation',
      sousTitre: 'Gestion de l\'eau & Climat',
      nomZone: 'Zone Maîtrise de l\'Eau',
      icone: Icons.water_drop_rounded,
      couleur: Color(0xFF0288D1),
      degrade: [Color(0xFF29B6F6), Color(0xFF01579B)],
      couleurOmbre: Color(0xFF013A6B),
      couleurFond: Color(0xFFE1F5FE),
      illustrationUrl: 'https://images.unsplash.com/photo-1563514227147-6d2ff665a6a0?w=800&q=80&auto=format&fit=crop',
      description: 'Goutte-à-goutte, pompage solaire, retenues collinaires et zaï vous rendent invincible face aux sécheresses.',
    ),

    // 6. Éleveur Émérite : Niveaux 50 à 59 (Orange Ambré / Cuivre)
    QuizGrade(
      niveauRequis: 50,
      niveauDebut: 50,
      niveauFin: 59,
      titre: 'Éleveur Émérite',
      sousTitre: 'Santé animale et provende',
      nomZone: 'Zone Élevage & Faune',
      icone: Icons.pets_rounded,
      couleur: Color(0xFFF57C00),
      degrade: [Color(0xFFFFA726), Color(0xFFE65100)],
      couleurOmbre: Color(0xFFBF360C),
      couleurFond: Color(0xFFFFF3E0),
      illustrationUrl: 'https://images.unsplash.com/photo-1548550023-2bdb3c5beed7?w=800&q=80&auto=format&fit=crop',
      description: 'Volailles locales et améliorées, petits ruminants, porcs et poissons grandissent dans un cadre biosécurisé.',
    ),

    // 7. Sage Agroécologue : Niveaux 60 à 69 (Menthe / Jade Bio Profond)
    QuizGrade(
      niveauRequis: 60,
      niveauDebut: 60,
      niveauFin: 69,
      titre: 'Sage Agroécologue',
      sousTitre: 'Protection bio et symbioses',
      nomZone: 'Zone Symbiose & Bio',
      icone: Icons.spa_rounded,
      couleur: Color(0xFF00796B),
      degrade: [Color(0xFF4DB6AC), Color(0xFF004D40)],
      couleurOmbre: Color(0xFF003028),
      couleurFond: Color(0xFFB2DFDB),
      illustrationUrl: 'https://images.unsplash.com/photo-1500651230702-0e2d8a49d4ad?w=800&q=80&auto=format&fit=crop',
      description: 'Vous protégez les récoltes avec le neem, les biopesticides naturels et la puissance des engrais verts.',
    ),

    // 8. Pionnier Agri-Tech : Niveaux 70 à 84 (Indigo Électrique / Cobalt)
    QuizGrade(
      niveauRequis: 70,
      niveauDebut: 70,
      niveauFin: 84,
      titre: 'Pionnier Agri-Tech',
      sousTitre: 'Mécanisation et innovation',
      nomZone: 'Zone Innovation Agri-Tech',
      icone: Icons.biotech_rounded,
      couleur: Color(0xFF3F51B5),
      degrade: [Color(0xFF5C6BC0), Color(0xFF283593)],
      couleurOmbre: Color(0xFF1A237E),
      couleurFond: Color(0xFFE8EAF6),
      illustrationUrl: 'https://images.unsplash.com/photo-1589923188900-85dae523342b?w=800&q=80&auto=format&fit=crop',
      description: 'Motoculteurs, séchoirs solaires, alertes météo et capteurs propulsent votre ferme vers le futur.',
    ),

    // 9. Grand Maître Agronome : Niveaux 85 à 99 (Pourpre Royal / Améthyste)
    QuizGrade(
      niveauRequis: 85,
      niveauDebut: 85,
      niveauFin: 99,
      titre: 'Grand Maître Agronome',
      sousTitre: 'Transformation & Agro-Business',
      nomZone: 'Zone Agro-Business & Marchés',
      icone: Icons.military_tech_rounded,
      couleur: Color(0xFF7B1FA2),
      degrade: [Color(0xFFAB47BC), Color(0xFF4A148C)],
      couleurOmbre: Color(0xFF38006B),
      couleurFond: Color(0xFFF3E5F5),
      illustrationUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=800&q=80&auto=format&fit=crop',
      description: 'Gestion financière, rentabilité, normes HACCP, coopératives et marchés régionaux sont sous votre maîtrise.',
    ),

    // 10. Légende Agricole : Niveau 100 (Or Solaire / Flamboyant)
    QuizGrade(
      niveauRequis: 100,
      niveauDebut: 100,
      niveauFin: 100,
      titre: 'Légende Agricole',
      sousTitre: 'Le Sommet Suprême du Savoir',
      nomZone: 'Le Sommet Suprême',
      icone: Icons.workspace_premium_rounded,
      couleur: Color(0xFFFFB300),
      degrade: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
      couleurOmbre: Color(0xFFC47D00),
      couleurFond: Color(0xFFFFF9C4),
      illustrationUrl: 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800&q=80&auto=format&fit=crop',
      description: 'Vous trônez au sommet des 100 niveaux. Une référence vivante de l\'agriculture africaine et un modèle pour tous.',
    ),
  ];

  /// Calcule le grade actif pour un niveau donné
  static QuizGrade getGradePourNiveau(int niveau) {
    QuizGrade gradeActuel = tousLesGrades.first;
    for (final grade in tousLesGrades) {
      if (niveau >= grade.niveauRequis) {
        gradeActuel = grade;
      } else {
        break;
      }
    }
    return gradeActuel;
  }

  /// Retourne le prochain grade à atteindre, ou null si rang Légende atteint
  static QuizGrade? getProchainGrade(int niveau) {
    for (final grade in tousLesGrades) {
      if (niveau < grade.niveauRequis) {
        return grade;
      }
    }
    return null;
  }

  /// Calcule la progression (0.0 à 1.0) vers le prochain grade
  static double getProgressionVersProchainGrade(int niveau) {
    final actuel = getGradePourNiveau(niveau);
    final prochain = getProchainGrade(niveau);
    if (prochain == null) return 1.0;

    final etape = prochain.niveauRequis - actuel.niveauRequis;
    if (etape <= 0) return 1.0;

    final fait = niveau - actuel.niveauRequis;
    return (fait / etape).clamp(0.0, 1.0);
  }

  /// Nombre de niveaux restants à réussir pour être promu
  static int getNiveauxRestants(int niveau) {
    final prochain = getProchainGrade(niveau);
    if (prochain == null) return 0;
    return (prochain.niveauRequis - niveau).clamp(0, 100);
  }
}
