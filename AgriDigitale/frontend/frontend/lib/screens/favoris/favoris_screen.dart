import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/favori_service.dart';
import '../../models/article.dart';
import '../../widgets/article_card.dart';
import '../../providers/auth_provider.dart';
import '../../core/design/app_colors.dart';
import '../home/article_detail_screen.dart';

class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});
  @override
  State<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends State<FavorisScreen> {
  final _service = FavoriService();
  List<Article> _favoris = [];
  List<Article> _filtres = [];
  bool _chargement = false;
  String? _erreur;
  bool? _dernierStatutAuth;
  String _triActif = 'recent';
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    if (_dernierStatutAuth != null && _dernierStatutAuth != auth.connecte) {
      _charger();
    }
    _dernierStatutAuth = auth.connecte;
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final liste = await _service.lister();
      if (mounted) {
        setState(() {
          _favoris = liste;
          _appliquerFiltres();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _erreur = e.toString());
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  void _appliquerFiltres() {
    List<Article> liste = List.from(_favoris);
    if (_recherche.isNotEmpty) {
      liste = liste
          .where((a) =>
              a.titre.toLowerCase().contains(_recherche.toLowerCase()) ||
              a.categorie.toLowerCase().contains(_recherche.toLowerCase()))
          .toList();
    }
    switch (_triActif) {
      case 'recent':
        liste.sort((a, b) => b.datePublication.compareTo(a.datePublication));
        break;
      case 'ancien':
        liste.sort((a, b) => a.datePublication.compareTo(b.datePublication));
        break;
      case 'az':
        liste.sort((a, b) => a.titre.compareTo(b.titre));
        break;
    }
    _filtres = liste;
  }

  Future<void> _retirer(int index) async {
    final article = _filtres[index];
    setState(() {
      _filtres.removeAt(index);
      _favoris.removeWhere((a) => a.id == article.id);
    });
    try {
      await _service.retirer(article.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Retiré des favoris'),
            action: SnackBarAction(
              label: 'Annuler',
              onPressed: () {
                setState(() {
                  _favoris.insert(0, article);
                  _appliquerFiltres();
                });
                _service.ajouter(article);
              },
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _favoris.insert(0, article);
          _appliquerFiltres();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _filtres.isNotEmpty ? 'Mes favoris (${_filtres.length})' : 'Mes favoris',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_favoris.isNotEmpty) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              onSelected: (val) => setState(() {
                _triActif = val;
                _appliquerFiltres();
              }),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'recent',
                  child: Row(children: [
                    Icon(Icons.arrow_downward,
                        size: 16,
                        color: _triActif == 'recent'
                            ? AppColors.vertPrimaire
                            : Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Plus récent'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'ancien',
                  child: Row(children: [
                    Icon(Icons.arrow_upward,
                        size: 16,
                        color: _triActif == 'ancien'
                            ? AppColors.vertPrimaire
                            : Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Plus ancien'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'az',
                  child: Row(children: [
                    Icon(Icons.sort_by_alpha,
                        size: 16,
                        color: _triActif == 'az'
                            ? AppColors.vertPrimaire
                            : Colors.grey),
                    const SizedBox(width: 8),
                    const Text('A → Z'),
                  ]),
                ),
              ],
            ),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _charger),
          ],
        ],
      ),
      body: _chargement
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.vertPrimaire))
              : _erreur != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text('Impossible de charger les favoris'),
                          TextButton(
                              onPressed: _charger,
                              child: const Text('Réessayer')),
                        ],
                      ),
                    )
                  : _favoris.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bookmark_border,
                                  size: 56, color: AppColors.grisIcone),
                              SizedBox(height: 12),
                              Text('Aucun article enregistré',
                                  style: TextStyle(fontSize: 15)),
                              SizedBox(height: 6),
                              Text(
                                  'Appuie sur 🔖 sur un article pour l\'enregistrer',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 13),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // Barre de recherche
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Rechercher dans mes favoris...',
                                  prefixIcon: const Icon(Icons.search,
                                      color: AppColors.grisIcone),
                                  suffixIcon: _recherche.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () => setState(() {
                                            _recherche = '';
                                            _appliquerFiltres();
                                          }),
                                        )
                                      : null,
                                ),
                                onChanged: (v) => setState(() {
                                  _recherche = v;
                                  _appliquerFiltres();
                                }),
                              ),
                            ),
                            if (_filtres.isEmpty)
                              const Expanded(
                                child: Center(
                                  child: Text('Aucun résultat',
                                      style: TextStyle(color: Colors.grey)),
                                ),
                              )
                            else
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: _charger,
                                  child: ListView.builder(
                                    itemCount: _filtres.length,
                                    itemBuilder: (context, i) => Dismissible(
                                      key: Key(_filtres[i].id),
                                      direction: DismissDirection.endToStart,
                                      confirmDismiss: (_) async {
                                        await _retirer(i);
                                        return false;
                                      },
                                      background: Container(
                                        color: Colors.red,
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 16),
                                        child: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.delete,
                                                color: Colors.white),
                                            SizedBox(height: 4),
                                            Text('Retirer',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      child: ArticleCard(
                                        article: _filtres[i],
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ArticleDetailScreen(
                                                articleId: _filtres[i].id),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
    );
  }
}
