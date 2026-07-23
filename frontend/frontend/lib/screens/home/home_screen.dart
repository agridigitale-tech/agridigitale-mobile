import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../services/article_service.dart';
import '../../models/article.dart';
import '../../widgets/article_card.dart';
import '../../widgets/banner_carousel.dart';
import '../../core/design/app_colors.dart';
import '../../core/app_localizations.dart';
import '../../core/api_client.dart';
import '../main_navigation_screen.dart';
import 'article_detail_screen.dart';
import 'search_screen.dart';
import 'notifications_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _service = ArticleService();
  final _apiClient = ApiClient();
  late Future<List<String>> _categoriesFuture;
  String? _categorieActive;
  final List<Article> _articles = [];
  int _page = 1;
  bool _chargement = false;
  bool _toutCharge = false;
  final _scrollController = ScrollController();
  int _notifCount = 0;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _service.listerCategories();
    _chargerPlus();
    _chargerNotifs();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _chargerPlus();
      }
    });
    // Rafraîchir le badge quand une notif FCM arrive en foreground
    FirebaseMessaging.onMessage.listen((_) {
      if (mounted) _chargerNotifs();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _chargerNotifs() async {
    try {
      final rep = await _apiClient.dio.get('/notifications/non-lues');
      if (mounted) setState(() => _notifCount = rep.data['count'] ?? 0);
    } catch (_) {}
  }

  Future<void> _chargerPlus() async {
    if (_chargement || _toutCharge) return;
    setState(() => _chargement = true);
    try {
      final nouveaux =
          await _service.lister(categorie: _categorieActive, page: _page);
      setState(() {
        _articles.addAll(nouveaux);
        _page++;
        if (nouveaux.length < 20) _toutCharge = true;
      });
    } catch (_) {}
    setState(() => _chargement = false);
  }

  void _filtrer(String? cat) {
    setState(() {
      _categorieActive = cat;
      _articles.clear();
      _page = 1;
      _toutCharge = false;
    });
    _chargerPlus();
  }

  Future<void> _actualiser() async {
    setState(() {
      _articles.clear();
      _page = 1;
      _toutCharge = false;
      _categoriesFuture = _service.listerCategories();
    });
    await _chargerPlus();
    await _chargerNotifs();
  }

  void _allerFavoris() {
    // Navigue vers l'onglet favoris (index 3) via le parent MainNavigationScreen
    final nav = context.findAncestorStateOfType<MainNavigationScreenState>();
    if (nav != null) {
      nav.changerOnglet(3);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('AGRIDIGITALE', style: Theme.of(context).textTheme.titleLarge),
        actions: [
          // Icône favoris → navigue vers l'onglet favoris
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: AppColors.vertPrimaire),
            tooltip: 'Mes favoris',
            onPressed: _allerFavoris,
          ),
          // Icône notification avec badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                tooltip: 'Notifications',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsListScreen()),
                  );
                  // Rafraîchir le badge après retour
                  if (mounted) _chargerNotifs();
                },
              ),
              if (_notifCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        _notifCount > 99 ? '99+' : '$_notifCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _actualiser,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            const SliverToBoxAdapter(child: BannerCarousel()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l.t('search'),
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.grisIcone),
                  ),
                  readOnly: true,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SearchScreen())),
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
                        final actif = (cat == 'Home' &&
                                _categorieActive == null) ||
                            cat == _categorieActive;
                        return Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: GestureDetector(
                            onTap: () =>
                                _filtrer(cat == 'Home' ? null : cat),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(cat.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: actif
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: actif
                                          ? AppColors.texteFort
                                          : AppColors.grisTexte,
                                      fontSize: 13.5,
                                    )),
                                const SizedBox(height: 4),
                                Container(
                                    height: 2,
                                    width: 28,
                                    color: actif
                                        ? AppColors.vertPrimaire
                                        : Colors.transparent),
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
            if (_articles.isEmpty && _chargement)
              const SliverFillRemaining(
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.vertPrimaire)))
            else if (_articles.isEmpty && !_chargement)
              SliverFillRemaining(
                  child: _etatMessage(Icons.article_outlined,
                      l.t('no_articles'), l.t('no_articles_sub')))
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => ArticleCard(
                    article: _articles[i],
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ArticleDetailScreen(
                                articleId: _articles[i].id))),
                  ),
                  childCount: _articles.length,
                ),
              ),
            if (_chargement)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.vertPrimaire)),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _etatMessage(IconData icone, String titre, String sousTitre) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
        child: Column(children: [
          Icon(icone, size: 44, color: AppColors.grisIcone),
          const SizedBox(height: 10),
          Text(titre,
              style: const TextStyle(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(sousTitre,
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center),
        ]),
      );
}

// Classe utilitaire pour écouter les notifs FCM depuis HomeScreen
class FirebaseMessagingListener {
  static VoidCallback? onForegroundMessage;
}
