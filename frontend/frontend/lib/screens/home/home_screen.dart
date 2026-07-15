// voila le code pour lister les catégories d'articles dans le service article_service.dart

import 'package:flutter/material.dart';
import '../../services/article_service.dart';
import '../../models/article.dart';
import '../../widgets/article_card.dart';
import '../../widgets/banner_carousel.dart';
import '../../core/design/app_colors.dart';
import 'article_detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // évite de recharger l'onglet à chaque changement de tab

  final _service = ArticleService();
  late Future<List<Article>> _articlesFuture;
  late Future<List<String>> _categoriesFuture;
  String? _categorieActive;

  @override
  void initState() {
    super.initState();
    _articlesFuture = _service.lister();
    _categoriesFuture = _service.listerCategories();
  }

  void _filtrer(String? cat) {
    setState(() {
      _categorieActive = cat;
      _articlesFuture = _service.lister(categorie: cat);
    });
  }

  Future<void> _actualiser() async {
    setState(() {
      _articlesFuture = _service.lister(categorie: _categorieActive);
      _categoriesFuture = _service.listerCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('AGRIDIGITALE', style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(icon: const Icon(Icons.bookmark_border, color: AppColors.vertPrimaire), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _actualiser,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: BannerCarousel()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: Icon(Icons.search, color: AppColors.grisIcone),
                  ),
                  readOnly: true, // ouvre l'écran dédié, évite les frappes perdues
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<List<String>>(
                future: _categoriesFuture,
                builder: (context, snap) {
                  final categories = ['Home', ...(snap.data ?? [])];
                  return SizedBox(
                    height: 42,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length,
                      itemBuilder: (context, i) {
                        final cat = categories[i];
                        final actif = (cat == 'Home' && _categorieActive == null) || cat == _categorieActive;
                        return Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: GestureDetector(
                            onTap: () => _filtrer(cat == 'Home' ? null : cat),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(cat.toUpperCase(), style: TextStyle(
                                  fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
                                  color: actif ? AppColors.texteFort : AppColors.grisTexte,
                                  fontSize: 13.5,
                                )),
                                const SizedBox(height: 4),
                                Container(height: 2, width: 28,
                                  color: actif ? AppColors.vertPrimaire : Colors.transparent),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: Divider(height: 1)),
            FutureBuilder<List<Article>>(
              future: _articlesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire)));
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(child: _etatMessage(
                    Icons.wifi_off, 'Connexion impossible',
                    'Vérifie ta connexion internet et tire vers le bas pour réessayer.'));
                }
                final articles = snapshot.data!;
                if (articles.isEmpty) {
                  return SliverFillRemaining(child: _etatMessage(
                    Icons.article_outlined, 'Aucun article', 'Rien à afficher pour cette rubrique.'));
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => ArticleCard(
                      article: articles[i],
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => ArticleDetailScreen(articleId: articles[i].id))),
                    ),
                    childCount: articles.length,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _etatMessage(IconData icone, String titre, String sousTitre) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
    child: Column(children: [
      Icon(icone, size: 44, color: AppColors.grisIcone),
      const SizedBox(height: 10),
      Text(titre, style: const TextStyle(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
      const SizedBox(height: 4),
      Text(sousTitre, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), textAlign: TextAlign.center),
    ]),
  );
}