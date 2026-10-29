// Vue dédiée pour la catégorie "CONSEIL DU JOUR" accessible depuis la barre d'onglets.
// Permet de voir le conseil du jour en grand, d'écouter la voix TTS, de réafficher l'overlay
// et d'explorer la bibliothèque complète des 31 conseils agronomiques pratiques du mois.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/design/app_colors.dart';
import '../data/conseils_data.dart';
import '../services/quiz_service.dart';
import 'conseil_du_jour_overlay.dart';

class ConseilDuJourSection extends StatefulWidget {
  final VoidCallback? onReafficherOverlay;

  const ConseilDuJourSection({
    super.key,
    this.onReafficherOverlay,
  });

  @override
  State<ConseilDuJourSection> createState() => _ConseilDuJourSectionState();
}

class _ConseilDuJourSectionState extends State<ConseilDuJourSection> {
  final ConseilAgricole _conseilDuJour = ConseilsData.getConseilDuJour();
  final FlutterTts _tts = FlutterTts();
  final QuizService _quizService = QuizService();

  int? _idEnLecture;
  String _filtreCategorie = 'Tous';
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _idEnLecture = null);
      });
      _tts.setErrorHandler((_) {
        if (mounted) setState(() => _idEnLecture = null);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _lireConseil(ConseilAgricole c) async {
    HapticFeedback.lightImpact();
    if (_idEnLecture == c.id) {
      await _tts.stop();
      if (mounted) setState(() => _idEnLecture = null);
    } else {
      if (mounted) setState(() => _idEnLecture = c.id);
      final texte = '${c.titre}. ${c.texte}. Astuce clé : ${c.astuceCle}';
      await _tts.speak(texte);

      // Attribution de grains si c'est le conseil du jour
      if (c.id == _conseilDuJour.id) {
        final grains = await _quizService.getTotalGrains();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('quiz_agri_grains', grains + 5);
        _quizService.changeNotifier.value++;
      }
    }
  }

  void _partagerConseil(ConseilAgricole c) {
    final texte = '🌾 Conseil AgriDigitale : ${c.titre}\n\n'
        '${c.texte}\n\n'
        '💡 Astuce clé : ${c.astuceCle}\n\n'
        'Retrouvez chaque jour les conseils et cours des marchés sur AgriDigitale : https://agridigitale.net';
    Share.share(texte);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Catégories uniques pour les filtres
    final categories = ['Tous', ...{...ConseilsData.conseils.map((c) => c.categorie)}];

    // Filtrage des conseils
    final conseilsFiltres = ConseilsData.conseils.where((c) {
      final matchCat = _filtreCategorie == 'Tous' || c.categorie == _filtreCategorie;
      final matchRecherche = _recherche.isEmpty ||
          c.titre.toLowerCase().contains(_recherche.toLowerCase()) ||
          c.texte.toLowerCase().contains(_recherche.toLowerCase()) ||
          c.astuceCle.toLowerCase().contains(_recherche.toLowerCase());
      return matchCat && matchRecherche;
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de section
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Le Conseil du Jour',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.4),
              ),
              const Spacer(),
              // Bouton pour rouvrir en pop-up superposition
              TextButton.icon(
                onPressed: () {
                  if (widget.onReafficherOverlay != null) {
                    widget.onReafficherOverlay!();
                  } else {
                    ConseilDuJourOverlay.afficher(context);
                  }
                },
                icon: const Icon(Icons.fullscreen, size: 18, color: AppColors.vertPrimaire),
                label: const Text(
                  'Mode Pop-up',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.vertPrimaire),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Grande carte héro du conseil du jour
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E3A2B), const Color(0xFF152A1F)]
                    : [const Color(0xFFF1F8E9), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.vertPrimaire.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '☀️ AUJOURD\'HUI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.vertPrimaire.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _conseilDuJour.categorie,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.vertPrimaire,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 20, color: AppColors.vertPrimaire),
                      tooltip: 'Partager',
                      onPressed: () => _partagerConseil(_conseilDuJour),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Titre
                Text(
                  _conseilDuJour.titre,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                    color: isDark ? Colors.white : AppColors.texteFort,
                  ),
                ),
                const SizedBox(height: 10),

                // Texte complet
                Text(
                  _conseilDuJour.texte,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: isDark ? Colors.white70 : AppColors.grisTexte,
                  ),
                ),
                const SizedBox(height: 14),

                // Encadré Astuce clé
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD54F)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _conseilDuJour.astuceCle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5D4037),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Bouton lecteur audio TTS
                InkWell(
                  onTap: () => _lireConseil(_conseilDuJour),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _idEnLecture == _conseilDuJour.id
                            ? [Colors.orange, Colors.deepOrange]
                            : [AppColors.vertPrimaire, const Color(0xFF4CAF50)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: (_idEnLecture == _conseilDuJour.id ? Colors.orange : AppColors.vertPrimaire)
                              .withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _idEnLecture == _conseilDuJour.id ? Icons.pause_circle_filled : Icons.play_circle_fill,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _idEnLecture == _conseilDuJour.id
                              ? 'Pause la lecture audio'
                              : 'Écouter le conseil à haute voix (30s)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // En-tête Bibliothèque des conseils
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.vertPrimaire,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Bibliothèque des 31 conseils du mois',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Explorez et écoutez toutes les astuces agronomiques à appliquer sur vos parcelles.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.texteSombreMoyen : AppColors.grisTexte,
            ),
          ),
          const SizedBox(height: 12),

          // Champ de recherche rapide
          TextField(
            onChanged: (val) => setState(() => _recherche = val),
            decoration: InputDecoration(
              hintText: 'Rechercher une culture, ravageur, engrais...',
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.grisIcone),
              filled: true,
              fillColor: isDark ? AppColors.surfaceSombre : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Filtres par thème
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = categories[i];
                final actif = _filtreCategorie == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: actif,
                  onSelected: (val) {
                    if (val) setState(() => _filtreCategorie = cat);
                  },
                  selectedColor: AppColors.vertPrimaire,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: actif ? FontWeight.bold : FontWeight.w500,
                    color: actif ? Colors.white : (isDark ? Colors.white70 : AppColors.texteFort),
                  ),
                  backgroundColor: isDark ? AppColors.surfaceSombre : Colors.grey.shade200,
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Liste des conseils filtrés
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: conseilsFiltres.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final c = conseilsFiltres[index];
              final enLecture = _idEnLecture == c.id;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceSombre : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: enLecture
                        ? Colors.orange
                        : (isDark ? Colors.white12 : Colors.black12),
                    width: enLecture ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.vertPrimaire.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            c.categorie,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.vertPrimaire,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Bouton lecture audio pour ce conseil précis
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            enLecture ? Icons.pause_circle_filled : Icons.volume_up_outlined,
                            color: enLecture ? Colors.orange : AppColors.vertPrimaire,
                            size: 22,
                          ),
                          tooltip: 'Écouter',
                          onPressed: () => _lireConseil(c),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.share_outlined, size: 18, color: AppColors.grisIcone),
                          tooltip: 'Partager',
                          onPressed: () => _partagerConseil(c),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.titre,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.texteFort,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.texte,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark ? Colors.white70 : AppColors.grisTexte,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : const Color(0xFFFFFDE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              c.astuceCle,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF795548),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
