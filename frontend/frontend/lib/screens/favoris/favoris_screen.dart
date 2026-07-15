//permet de gérer l'écran des favoris de l'application

import 'package:flutter/material.dart';
import '../../services/favori_service.dart';
import '../../models/article.dart';
import '../../widgets/article_card.dart';
import '../home/article_detail_screen.dart';
import '../../widgets/auth_gate.dart';

class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});
  @override
  State<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends State<FavorisScreen> {
  final _service = FavoriService();
  late Future<List<Article>> _future;

  @override
  void initState() {
    super.initState();
    _verifierAuthEtCharger();
  }

  Future<void> _verifierAuthEtCharger() async {
    final connecte = await exigerConnexion(context, motif: "accéder à vos favoris");
    if (connecte) {
      _future = _service.lister();
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

   @override
   Widget build(BuildContext context) {
     return Scaffold(
      appBar: AppBar(title: const Text('Mes favoris')),
      body: FutureBuilder<List<Article>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final favoris = snapshot.data!;
          if (favoris.isEmpty) return const Center(child: Text('Aucun favori pour le moment'));
          return ListView.builder(
            itemCount: favoris.length,
            itemBuilder: (context, i) => Dismissible(
              key: Key(favoris[i].id),
              onDismissed: (_) => _service.retirer(favoris[i].id),
              background: Container(color: Colors.red, alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
              child: ArticleCard(
                article: favoris[i],
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ArticleDetailScreen(articleId: favoris[i].id))),
              ),
            ),
          );
        },
      ),
    );
  }
}