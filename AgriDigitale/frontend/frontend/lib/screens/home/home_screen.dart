// Écran d'accueil : affiche les bannières, la recherche, les catégories,
// l'article à la une, le scroll horizontal "À ne pas manquer" (top 6 vues),
// et la liste verticale "Dernières actualités" avec pagination infinie.
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  Article? _articleUne;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _service.listerCategories();
    _chargerArticleUne();
    _chargerPlus();
    _chargerNotifs();
    // Pagination infinie : charge plus d'articles quand on approche du bas
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _chargerPlus();
      }
    });
    // Rafraîchir le badge quand une notif OneSignal arrive au premier plan.
    if (!kIsWeb) {
      try {
        OneSignal.Notifications.addForegroundWillDisplayListener((_) {
          if (mounted) _chargerNotifs();
        });
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _chargerArticleUne() async {
    final article = await _service.articleUne();
    if (mounted) setState(() => _articleUne = article);
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
      if (mounted) {
        setState(() {
          final Set<String> idsExistants = _articles.map((a) => a.id).toSet();
          final aAjouter = nouveaux.where((a) => !idsExistants.contains(a.id)).toList();
          _articles.addAll(aAjouter);
          _page++;
          // Si moins de 20 reçus ou aucun nouvel article unique (ex. cache hors-ligne), arrêter le scroll infini
          if (nouveaux.length < 20 || (nouveaux.isNotEmpty && aAjouter.isEmpty)) {
            _toutCharge = true;
          }
        });
      }
    } catch (e) {
      debugPrint('[HOME] !! Erreur _chargerPlus: $e');
    }
    if (mounted) setState(() => _chargement = false);
  }

  // Filtre les articles par catégorie (null = toutes) et recharge depuis la page 1
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
      _articleUne = null;
    });
    BannerCarousel.actualiser();
    await Future.wait([_chargerArticleUne(), _chargerPlus(), _chargerNotifs()]);
  }

  // Navigue vers l'onglet favoris (index 3) via le parent MainNavigationScreen
  void _allerFavoris() {
    final nav = context.findAncestorStateOfType<MainNavigationScreenState>();
    if (nav != null) {
      nav.changerOnglet(3);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('AGRIDIGITALE',
            style: TextStyle(
              color: isDark ? AppColors.vertClair : AppColors.vertFonce,
              fontWeight: FontWeight.w900,
              fontSize: 17,
              letterSpacing: 1.2,
            )),
        actions: [
          // Icône favoris → navigue vers l'onglet favoris
          IconButton(
            icon: Icon(Icons.bookmark_border, color: isDark ? AppColors.vertClair : AppColors.vertPrimaire),
            tooltip: 'Mes favoris',
            onPressed: _allerFavoris,
          ),
          // Icône notification avec badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none, color: isDark ? AppColors.texteSombreFort : AppColors.texteFort),
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
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
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
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _actualiser,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: BannerCarousel()),
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
                  final categories = ['Home', 'Togo', 'Afrique', 'Monde', ...(snap.data ?? []).where((c) => !['Togo','Afrique','Monde'].contains(c))];
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
                                          ? (isDark ? AppColors.vertClair : AppColors.vertFonce)
                                          : (isDark ? AppColors.texteSombreMoyen : AppColors.grisTexte),
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
              else ...[
                // Article à la une
                if (_articleUne != null && _categorieActive == null)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.redAccent, Colors.orange],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('À la une',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '🔥 TENDANCE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.redAccent,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _ArticleUne(
                          article: _articleUne!,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => ArticleDetailScreen(articleId: _articleUne!.id))),
                        ),
                      ],
                    ),
                  ),
                // Scroll horizontal "À ne pas manquer" = les 6 articles les plus vus
                if (_articles.length > 1 && _categorieActive == null)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0xFFE65100), Colors.amber],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('À ne pas manquer',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 236,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(left: 14),
                            itemBuilder: (context, i) {
                              final top = _articles.take(6).toList();
                              if (i >= top.length) return null;
                              final a = top[i];
                              return ArticleCardVerticale(
                                article: a,
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => ArticleDetailScreen(articleId: a.id))),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [AppColors.vertPrimaire, Color(0xFF66BB6A)],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Dernières actualités',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // Liste verticale = tous les articles par date
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      if (i >= _articles.length) return null;
                      final a = _articles[i];
                      return ArticleCard(
                        article: a,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => ArticleDetailScreen(articleId: a.id))),
                      );
                    },
                    childCount: _articles.length,
                  ),
                ),
              ],
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

// Widget Article à la Une
class _ArticleUne extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;
  const _ArticleUne({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = article.image;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.vertPrimaire.withValues(alpha: 0.15),
              blurRadius: 25,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Grande image pleine largeur
              hasImage
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      memCacheWidth: 900,
                      maxWidthDiskCache: 1200,
                      httpHeaders: const {'Accept': 'image/*'},
                      placeholder: (ctx, url) => Container(
                          height: 240,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFF0F4F1), Color(0xFFE8F5E9)],
                            ),
                          )),
                      errorWidget: (ctx, url, err) => Container(
                        height: 240,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFF0F4F1), Color(0xFFE8F5E9)],
                          ),
                        ),
                        child: const Icon(Icons.article,
                            size: 60, color: AppColors.vertPrimaire),
                      ),
                    )
                  : Container(
                      height: 240,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF0F4F1), Color(0xFFE8F5E9)],
                        ),
                      ),
                      child: const Icon(Icons.article,
                          size: 60, color: AppColors.vertPrimaire),
                    ),
              // Dégradé bas
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.9),
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              // Badge "À la une"
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.redAccent, Color(0xFFFF6B6B)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flash_on, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('À LA UNE',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8)),
                    ],
                  ),
                ),
              ),
              // Titre en bas
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.vertPrimaire,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        article.categorie.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Text(
                      article.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: Colors.white.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(article.datePublication),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return 'Il y a ${diff.inMinutes} min';
      }
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays}j';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
