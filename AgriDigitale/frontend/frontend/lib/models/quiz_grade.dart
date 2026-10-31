// Système de Grades et Rangs du Quiz Agricole (de Novice à Légende).
// Progression basée sur les 100 niveaux et les 10 mondes thématiques.

import 'package:flutter/material.dart';

class QuizGrade {
  final int niveauRequis;
  final String titre;
  final String sousTitre;
  final String icone;
  final Color couleur;
  final Color couleurFond;
  final String description;

  const QuizGrade({
    required this.niveauRequis,
    required this.titre,
    required this.sousTitre,
    required this.icone,
    required this.couleur,
    required this.couleurFond,
    required this.description,
  });

  /// Liste officielle des 10 grades du jeu (du Niveau 1 au Niveau 100)
  static const List<QuizGrade> tousLesGrades = [
    QuizGrade(
      niveauRequis: 1,
      titre: 'Novice de la Terre',
      sousTitre: 'Premiers pas dans l\'art agricole',
      icone: '🌱',
      couleur: Color(0xFF43A047),
      couleurFond: Color(0xFFE8F5E9),
      description: 'Vous débutez votre voyage agronomique. Vous découvrez les secrets de la terre, du compost et du démarrage des plants.',
    ),
    QuizGrade(
      niveauRequis: 10,
      titre: 'Apprenti Planteur',
      sousTitre: 'Maîtrise des grandes cultures',
      icone: '🌿',
      couleur: Color(0xFF2E7D32),
      couleurFond: Color(0xFFC8E6C9),
      description: 'Le maïs, le sorgho, le riz pluvial et les légumineuses n\'ont plus de secret pour vous.',
    ),
    QuizGrade(
      niveauRequis: 20,
      titre: 'Maraîcher Pratiquant',
      sousTitre: 'Légumes et cultures vivrières',
      icone: '🥬',
      couleur: Color(0xFF00897B),
      couleurFond: Color(0xFFE0F2F1),
      description: 'Vous pilotez avec brio tomates, piments, oignons, gombos et légumes-feuilles de saison et contre-saison.',
    ),
    QuizGrade(
      niveauRequis: 30,
      titre: 'Arboriculteur Averti',
      sousTitre: 'Vergers et cultures pérennes',
      icone: '🌴',
      couleur: Color(0xFF558B2F),
      couleurFond: Color(0xFFDCEDC8),
      description: 'Anacardiers, palmiers à huile, caféiers, cacaoyers et manguiers s\'épanouissent sous vos soins experts.',
    ),
    QuizGrade(
      niveauRequis: 40,
      titre: 'Maître de l\'Irrigation',
      sousTitre: 'Gestion de l\'eau & Climat',
      icone: '💧',
      couleur: Color(0xFF0288D1),
      couleurFond: Color(0xFFE1F5FE),
      description: 'Goutte-à-goutte, pompage solaire, retenues collinaires et zaï vous rendent invincible face aux sécheresses.',
    ),
    QuizGrade(
      niveauRequis: 50,
      titre: 'Éleveur Émérite',
      sousTitre: 'Santé animale et provende',
      icone: '🐄',
      couleur: Color(0xFFF57C00),
      couleurFond: Color(0xFFFFF3E0),
      description: 'Volailles locales et améliorées, petits ruminants, porcs et poissons grandissent dans un cadre biosécurisé.',
    ),
    QuizGrade(
      niveauRequis: 60,
      titre: 'Sage Agroécologue',
      sousTitre: 'Protection bio et symbioses',
      icone: '🌍',
      couleur: Color(0xFF00796B),
      couleurFond: Color(0xFFB2DFDB),
      description: 'Vous protégez les récoltes avec le neem, les biopesticides naturels et la puissance des engrais verts.',
    ),
    QuizGrade(
      niveauRequis: 70,
      titre: 'Pionnier Agri-Tech',
      sousTitre: 'Mécanisation et innovation',
      icone: '⚙️',
      couleur: Color(0xFF5C6BC0),
      couleurFond: Color(0xFFE8EAF6),
      description: 'Motoculteurs, séchoirs solaires, alertes météo et capteurs propulsent votre ferme vers le futur.',
    ),
    QuizGrade(
      niveauRequis: 85,
      titre: 'Grand Maître Agronome',
      sousTitre: 'Transformation & Agro-Business',
      icone: '🏆',
      couleur: Color(0xFF7B1FA2),
      couleurFond: Color(0xFFF3E5F5),
      description: 'Gestion financière, rentabilité, normes HACCP, coopératives et marchés régionaux sont sous votre maîtrise.',
    ),
    QuizGrade(
      niveauRequis: 100,
      titre: 'Légende Agricole',
      sousTitre: 'Le Sommet Suprême du Savoir',
      icone: '👑',
      couleur: Color(0xFFD4AF37),
      couleurFond: Color(0xFFFFF9C4),
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
