import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/article_service.dart';
import '../../models/article.dart';
import '../../widgets/article_card.dart';
import '../../core/design/app_colors.dart';
import 'article_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _service = ArticleService();
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Article>? _resultats; // null = pas encore cherché, [] = aucun résultat
  bool _chargement = false;

  void _surChangement(String texte) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => _rechercher(texte));
  }

  Future<void> _rechercher(String motCle) async {
    if (motCle.trim().length < 2) { setState(() => _resultats = null); return; }
    setState(() => _chargement = true);
    try {
      final resultats = await _service.rechercher(motCle.trim());
      if (mounted) setState(() { _resultats = resultats; _chargement = false; });
    } catch (_) {
      if (mounted) setState(() { _resultats = []; _chargement = false; });
    }
  }

  @override
  void dispose() { _debounce?.cancel(); _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _surChangement,
          decoration: const InputDecoration(hintText: 'Rechercher un article...', border: InputBorder.none),
        ),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire))
          : _resultats == null
              ? const Center(child: Text('Tape au moins 2 caractères pour lancer la recherche'))
              : _resultats!.isEmpty
                  ? const Center(child: Text('Aucun résultat pour cette recherche'))
                  : ListView.builder(
                      itemCount: _resultats!.length,
                      itemBuilder: (context, i) => ArticleCard(
                        article: _resultats![i],
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => ArticleDetailScreen(articleId: _resultats![i].id))),
                      ),
                    ),
    );
  }
}