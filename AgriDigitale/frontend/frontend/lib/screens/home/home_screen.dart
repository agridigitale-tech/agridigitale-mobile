// Écran d'accueil : expérience éditoriale premium.
// Structure :
//  - En-tête dégradé (greeting + date + actions favoris/notifications)
//  - Carousel de bannières
//  - Barre de recherche
//  - Chips de catégories animées
//  - "À LA UNE" : article le plus récent du flux RSS (hero immersif)
//  - "À ne pas manquer" : top 6 par vues (scroll horizontal)
//  - "Dernières actualités" : liste verticale avec pagination infinie
// Animations : entrées en fondu/glissement échelonnées, effet press, shimmer.
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/article_service.dart';
import '../../models/article.dart';
import '../../widgets/article_card.dart';
import '../../widgets/banner_carousel.dart';
import '../../widgets/animations.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
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
  bool _premierChargement = true;
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
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        _chargerPlus();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // La "une" = l'article le plus récent du flux RSS.
  // On privilégie le premier élément de la liste (triée par date desc),
  // avec /une en repli si la liste n'est pas encore chargée.
  Future<void> _chargerArticleUne() async {
    final article = await _service.articleUne();
    if (mounted) setState(() => _articleUne = article);
  }

  // Choisit la une : le plus récent entre la liste locale et /une.
  Article? get _uneEffective {
    if (_categorieActive != null) return null;
    final premier = _articles.isNotEmpty ? _articles.first : null;
    if (premier != null && _articleUne != null) {
      return premier.datePublication.isAfter(_articleUne!.datePublication)
          ? premier
          : _articleUne;
    }
    return premier ?? _articleUne;
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
        _premierChargement = false;
      });
    } catch (e) {
      debugPrint('[HOME] !! Erreur _chargerPlus: $e');
      if (mounted) setState(() => _premierChargement = false);
    }
    if (mounted) setState(() => _chargement = false);
  }

  void _filtrer(String? cat) {
    setState(() {
      _categorieActive = cat;
      _articles.clear();
      _page = 1;
      _toutCharge = false;
      _premierChargement = true;
    });
    _chargerPlus();
  }

  Future<void> _actualiser() async {
    setState(() {
      _articles.clear();
      _page = 1;
      _toutCharge = false;
      _premierChargement = true;
      _categoriesFuture = _service.listerCategories();
      _articleUne = null;
    });
    await Future.wait([_chargerArticleUne(), _chargerPlus(), _chargerNotifs()]);
  }

  void _allerFavoris() {
    final nav = context.findAncestorStateOfType<MainNavigationScreenState>();
    if (nav != null) nav.changerOnglet(3);
  }

  void _ouvrirArticle(String id) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ArticleDetailScreen(articleId: id)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      body: RefreshIndicator(
        color: AppColors.vertPrimaire,
        onRefresh: _actualiser,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildEnTete(context),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            const SliverToBoxAdapter(child: BannerCarousel()),
            SliverToBoxAdapter(child: _buildRecherche(l)),
            SliverToBoxAdapter(child: _buildCategories()),
            ..._buildCorps(l),
            if (_chargement && !_premierChargement)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.vertPrimaire, strokeWidth: 2)),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }

  // ── En-tête dégradé ──────────────────────────────────────────────────────────
  Widget _buildEnTete(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.vertFonce, AppColors.vertPrimaire],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(AppRadius.xl),
            bottomRight: Radius.circular(AppRadius.xl),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.eco_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AGRIDIGITALE',
                            style: GoogleFonts.inter(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            _salutation(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _iconeEnTete(
                      icon: Icons.bookmark_border_rounded,
                      tooltip: 'Mes favoris',
                      onTap: _allerFavoris,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _iconeEnTete(
                      icon: Icons.notifications_none_rounded,
                      tooltip: 'Notifications',
                      badge: _notifCount,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsListScreen()),
                        );
                        if (mounted) _chargerNotifs();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Toute l\'actualité\nagricole en direct',
                  style: GoogleFonts.ptSerif(
                    fontSize: 25,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconeEnTete({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Tooltip(
          message: tooltip,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 21),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                badge > 99 ? '99+' : '$badge',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  String _salutation() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour, bonne lecture';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir, bonne lecture';
  }

  // ── Recherche ────────────────────────────────────────────────────────────────
  Widget _buildRecherche(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: PressScale(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SearchScreen())),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadow.douce,
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded,
                  color: AppColors.grisIcone, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l.t('search'),
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.grisTexte),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Catégories (chips animées) ────────────────────────────────────────────────
  Widget _buildCategories() {
    return FutureBuilder<List<String>>(
      future: _categoriesFuture,
      builder: (context, snap) {
        final categories = [
          '__home__',
          'Togo',
          'Afrique',
          'Monde',
          ...(snap.data ?? [])
              .where((c) => !['Togo', 'Afrique', 'Monde'].contains(c)),
        ];
        return SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: 4),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final cat = categories[i];
              final estHome = cat == '__home__';
              final actif = (estHome && _categorieActive == null) ||
                  cat == _categorieActive;
              final libelle = estHome ? 'Accueil' : cat;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: GestureDetector(
                  onTap: () => _filtrer(estHome ? null : cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: actif ? AppColors.vertPrimaire : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: actif
                            ? AppColors.vertPrimaire
                            : AppColors.grisLigne,
                      ),
                      boxShadow: actif ? AppShadow.douce : null,
                    ),
                    child: Text(
                      libelle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
                        color: actif ? Colors.white : AppColors.grisTexte,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Corps : une + top + liste ─────────────────────────────────────────────────
  List<Widget> _buildCorps(AppLocalizations l) {
    if (_premierChargement && _articles.isEmpty) {
      return const [SliverToBoxAdapter(child: _SqueletteAccueil())];
    }
    if (_articles.isEmpty && !_chargement) {
      return [
        SliverToBoxAdapter(
          child: _etatMessage(Icons.article_outlined, l.t('no_articles'),
              l.t('no_articles_sub')),
        ),
      ];
    }

    final une = _uneEffective;
    final reste = une != null
        ? _articles.where((a) => a.id != une.id).toList()
        : _articles;
    final plusVus = [..._articles]
      ..sort((a, b) => b.vues.compareTo(a.vues));
    final top = plusVus.take(6).toList();

    return [
      // À la une (hero)
      if (une != null && _categorieActive == null)
        SliverToBoxAdapter(
          child: FadeSlideIn(
            child: _ArticleUne(
              article: une,
              onTap: () => _ouvrirArticle(une.id),
            ),
          ),
        ),
      // Section "À ne pas manquer"
      if (top.length > 1 && _categorieActive == null) ...[
        SliverToBoxAdapter(
          child: _titreSection('À ne pas manquer', Icons.local_fire_department_rounded),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: AppSpacing.lg),
              itemCount: top.length,
              itemBuilder: (context, i) => FadeSlideIn(
                delay: Duration(milliseconds: 60 * i),
                child: ArticleCardVerticale(
                  article: top[i],
                  onTap: () => _ouvrirArticle(top[i].id),
                ),
              ),
            ),
          ),
        ),
      ],
      // Titre "Dernières actualités"
      SliverToBoxAdapter(
        child: _titreSection(_categorieActive ?? 'Dernières actualités',
            Icons.newspaper_rounded),
      ),
      // Liste verticale
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            if (i >= reste.length) return null;
            final a = reste[i];
            return FadeSlideIn(
              delay: Duration(milliseconds: (i % 6) * 55),
              offsetY: 16,
              child: ArticleCard(
                article: a,
                onTap: () => _ouvrirArticle(a.id),
              ),
            );
          },
          childCount: reste.length,
        ),
      ),
    ];
  }

  Widget _titreSection(String titre, IconData icone) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          AccentBar(height: 18),
          const SizedBox(width: AppSpacing.sm),
          Icon(icone, size: 17, color: AppColors.vertFonce),
          const SizedBox(width: 6),
          Text(
            titre,
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.texteFort),
          ),
        ],
      ),
    );
  }

  Widget _etatMessage(IconData icone, String titre, String sousTitre) => Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 70, horizontal: AppSpacing.xl),
        child: Column(children: [
          Icon(icone, size: 46, color: AppColors.grisIcone),
          const SizedBox(height: AppSpacing.md),
          Text(titre,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(sousTitre,
              style: GoogleFonts.inter(
                  color: AppColors.grisTexte, fontSize: 13),
              textAlign: TextAlign.center),
        ]),
      );
}

// ── Squelette de chargement de la page d'accueil ────────────────────────────────
class _SqueletteAccueil extends StatelessWidget {
  const _SqueletteAccueil();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(height: 210, radius: AppRadius.lg),
          const SizedBox(height: AppSpacing.lg),
          const ShimmerBox(height: 18, width: 160),
          const SizedBox(height: AppSpacing.md),
          for (int i = 0; i < 3; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 110, height: 100, radius: AppRadius.md),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(height: 13, width: double.infinity),
                      SizedBox(height: AppSpacing.sm),
                      ShimmerBox(height: 13, width: 200),
                      SizedBox(height: AppSpacing.sm),
                      ShimmerBox(height: 11, width: 130),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

// ── Carte "À la une" (hero immersif, animé) ─────────────────────────────────────
class _ArticleUne extends StatefulWidget {
  final Article article;
  final VoidCallback onTap;
  const _ArticleUne({required this.article, required this.onTap});

  @override
  State<_ArticleUne> createState() => _ArticleUneState();
}

class _ArticleUneState extends State<_ArticleUne> {
  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final imageUrl = article.image;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return PressScale(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadow.moyenne,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            children: [
              // Image plein cadre
              SizedBox(
                height: 240,
                width: double.infinity,
                child: hasImage
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        httpHeaders: const {'User-Agent': 'Mozilla/5.0'},
                        placeholder: (_, _) =>
                            const ShimmerBox(height: 240, radius: 0),
                        errorWidget: (_, _, _) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              // Dégradé bas pour la lisibilité du texte
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.10),
                        Colors.black.withValues(alpha: 0.82),
                      ],
                      stops: const [0.35, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              // Badge "À LA UNE"
              Positioned(
                top: AppSpacing.md,
                left: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.vertPrimaire,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: AppShadow.douce,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded,
                          color: Colors.white, size: 13),
                      const SizedBox(width: 3),
                      Text('À LA UNE',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
              // Contenu bas
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _pastilleCategorie(article.categorie),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(Icons.schedule_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.85)),
                        const SizedBox(width: 3),
                        Text(_tempsRelatif(article.datePublication),
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.85))),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      article.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.ptSerif(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.menu_book_rounded,
                            size: 12, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text('Lire l\'article',
                            style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        const Spacer(),
                        Text('${article.vues} vues',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: Colors.white70)),
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

  Widget _pastilleCategorie(String categorie) {
    Color couleur;
    switch (categorie.toLowerCase()) {
      case 'togo':
        couleur = const Color(0xFF2E7D32);
        break;
      case 'afrique':
        couleur = const Color(0xFFE65100);
        break;
      case 'monde':
        couleur = const Color(0xFF1565C0);
        break;
      default:
        couleur = AppColors.vertPrimaire;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: couleur,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(categorie.toUpperCase(),
          style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.4)),
    );
  }

  String _tempsRelatif(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _placeholder() => Container(
        height: 240,
        color: const Color(0xFFEDF3EE),
        child: const Center(
            child: Icon(Icons.article_outlined,
                size: 64, color: AppColors.vertPrimaire)),
      );
}
