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
    // (event.notification.display() est déjà géré par NotificationService,
    //  on ne le rappelle pas ici pour éviter un double affichage.)
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
      setState(() {
        _articles.addAll(nouveaux);
        _page++;
        if (nouveaux.length < 20) _toutCharge = true;
      });
    } catch (e) {
      debugPrint('[HOME] !! Erreur _chargerPlus: $e');
    }
    setState(() => _chargement = false);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        color: AppColors.vertPrimaire,
        backgroundColor: Colors.white,
        onRefresh: _actualiser,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: 110,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.vertFonce,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F4C2A),
                        AppColors.vertFonce,
                        AppColors.vertPrimaire,
                      ],
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.eco, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'AGRIDIGITALE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.bookmark_border, color: Colors.white),
                    tooltip: 'Mes favoris',
                    onPressed: _allerFavoris,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.white),
                        tooltip: 'Notifications',
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NotificationsListScreen()),
                          );
                          if (mounted) _chargerNotifs();
                        },
                      ),
                      if (_notifCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
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
                ),
              ],
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            const SliverToBoxAdapter(child: BannerCarousel()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SearchScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.vertPrimaire.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: AppColors.vertPrimaire.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.vertPrimaire.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.search, color: AppColors.vertPrimaire, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l.t('search'),
                          style: TextStyle(
                            color: AppColors.grisTexte.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.tune, color: AppColors.grisIcone.withOpacity(0.5), size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
                              colors: [AppColors.vertPrimaire, AppColors.vertFonce],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Catégories',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.texteFort,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FutureBuilder<List<String>>(
                    future: _categoriesFuture,
                    builder: (context, snap) {
                      final categories = ['Home', 'Togo', 'Afrique', 'Monde', ...(snap.data ?? []).where((c) => !['Togo','Afrique','Monde'].contains(c))];
                      return SizedBox(
                        height: 44,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: categories.length,
                          itemBuilder: (context, i) {
                            final cat = categories[i];
                            final actif = (cat == 'Home' &&
                                    _categorieActive == null) ||
                                cat == _categorieActive;
                            final displayCat = cat == 'Home' ? 'Tout' : cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                child: GestureDetector(
                                  onTap: () =>
                                      _filtrer(cat == 'Home' ? null : cat),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: actif
                                          ? const LinearGradient(
                                              colors: [AppColors.vertPrimaire, AppColors.vertFonce],
                                            )
                                          : null,
                                      color: actif ? null : Colors.white,
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: actif
                                          ? [
                                              BoxShadow(
                                                color: AppColors.vertPrimaire.withOpacity(0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.03),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                      border: Border.all(
                                        color: actif ? Colors.transparent : AppColors.grisLigne.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Text(
                                      displayCat.toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: actif ? FontWeight.w700 : FontWeight.w600,
                                        color: actif ? Colors.white : AppColors.grisTexte,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
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
                                const SizedBox(width: 10),
                                const Text(
                                  'À LA UNE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.texteFort,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.1),
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
                                      colors: [AppColors.vertPrimaire, Color(0xFF2D9C5C)],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'À ne pas manquer',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.texteFort,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 215,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(left: 16),
                              itemBuilder: (context, i) {
                                final plusVus = [..._articles]..sort((a, b) => b.vues.compareTo(a.vues));
                                final top = plusVus.take(6).toList();
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
                                      colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Dernières actualités',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.texteFort,
                                    letterSpacing: -0.3,
                                  ),
                                ),
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ArticleCard(
                          article: a,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => ArticleDetailScreen(articleId: a.id))),
                        ),
                      );
                    },
                    childCount: _articles.length,
                  ),
                ),
              ],
            if (_chargement)
              const               SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                      child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                        color: AppColors.vertPrimaire, strokeWidth: 2.5),
                  )),
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
              color: AppColors.vertPrimaire.withOpacity(0.15),
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
                        Colors.black.withOpacity(0.9),
                        Colors.black.withOpacity(0.4),
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
                        color: Colors.redAccent.withOpacity(0.4),
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
                        Icon(Icons.access_time, size: 12, color: Colors.white.withOpacity(0.8)),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(article.datePublication),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.remove_red_eye_outlined, size: 12, color: Colors.white.withOpacity(0.8)),
                        const SizedBox(width: 4),
                        Text(
                          '${article.vues} vues',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
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
