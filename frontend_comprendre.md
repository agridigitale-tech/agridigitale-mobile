# AgriDigitale — Frontend V2 (corrigé, fidèle à ta maquette)
### Diagnostic des bugs, nouvelle architecture d'authentification, design conforme à tes captures d'écran

Ce document **remplace** la partie visuelle du guide précédent (`AGRIDIGITALE_DESIGN_UI_PREMIUM.md`). Garde tes services (`article_service.dart`, `favori_service.dart`, `meteo_service.dart`, `agdtv_service.dart`, `demande_service.dart`, `auth_service.dart`) du guide solo — ils sont corrects. On corrige ici : la connexion réseau, le flux d'authentification, et tous les écrans visuels.

---

## 0. Corriger la connexion au backend (LA cause de la plupart de tes bugs)

**`lib/core/api_client.dart`** — version corrigée avec détection d'environnement et logs visibles

```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final _storage = const FlutterSecureStorage();

  // ⚠️ ÉTAPE OBLIGATOIRE : choisis la bonne URL selon où tourne ton backend.
  static String get _baseUrl {
    // Backend déployé (Render/Railway) : utilise toujours cette ligne en priorité si dispo.
    const backendDeploye = 'https://agridigitale-api.onrender.com/api';
    if (!kDebugMode) return backendDeploye;

    // En développement local, remplace 'localhost' selon ton support de test :
    // - Émulateur Android  : 10.0.2.2   (traduit vers le localhost de TA machine)
    // - Téléphone physique : IP LAN de ta machine, ex. 192.168.1.42 (fais `ipconfig`/`ifconfig`)
    // - Simulateur iOS     : localhost fonctionne directement
    return 'http://10.0.2.2:5000/api';
  }

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {'Content-Type': 'application/json'},
    ));

    // Logs clairs dans la console pendant le développement : indispensable pour
    // voir immédiatement si une requête part vers la bonne adresse et ce que
    // répond réellement le serveur (au lieu de deviner pourquoi "ça ne marche pas").
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true, responseBody: true, error: true,
      ));
    }

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _storage.delete(key: 'jwt_token');
        }
        handler.next(error);
      },
    ));
  }
}
```

**Deux choses à vérifier en plus, sinon ça bloque quand même :**

1. **Android bloque le HTTP non chiffré par défaut** dès qu'on cible une IP locale (`10.0.2.2` ou ton IP LAN) plutôt que du HTTPS. Ajoute dans `android/app/src/main/AndroidManifest.xml`, dans la balise `<application>` :
```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```
*(à retirer une fois que tu pointes uniquement vers ton backend déployé en HTTPS)*

2. **Vérifie que ton backend écoute bien sur `0.0.0.0` et pas seulement `127.0.0.1`** — dans `server.js`, `app.listen(PORT, ...)` sans préciser d'hôte suffit normalement, mais si tu as mis une IP explicite, remets-le générique.

Avec `LogInterceptor` actif, lance l'app et regarde ta console : tu verras immédiatement si une requête part, vers quelle URL, et ce que le serveur répond (200, 401, timeout...). **Ne code rien d'autre tant que tu ne vois pas une connexion réussie dans les logs.**

---

## 1. Nouvelle architecture d'authentification : contextuelle, pas au démarrage

### Le principe
- L'app s'ouvre **toujours** sur l'accueil, en mode invité. Aucun écran de connexion forcé.
- Le visiteur peut lire les actualités, la météo, AGDTV, et faire une recherche librement.
- Dès qu'il clique sur ❤️ (favori) ou sur *Envoyer* (formulaire de demande), une **feuille modale de connexion** apparaît. S'il se connecte avec succès, l'action reprend automatiquement. S'il annule, rien ne se passe.

### `lib/providers/auth_provider.dart` (mis à jour)

```dart
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();
  bool connecte = false;
  bool enVerification = true;

  Future<void> verifierSession() async {
    connecte = await _service.estConnecte();
    enVerification = false;
    notifyListeners();
  }

  Future<void> connecter(String email, String mdp) async {
    await _service.connecter(email, mdp);
    connecte = true;
    notifyListeners();
  }

  Future<void> inscrire(String nom, String email, String mdp) async {
    await _service.inscrire(nom, email, mdp);
    connecte = true;
    notifyListeners();
  }

  Future<void> deconnecter() async {
    await _service.deconnecter();
    connecte = false;
    notifyListeners();
  }
}
```

### `lib/widgets/auth_gate.dart` — la pièce centrale

C'est cette fonction que tu appelles **avant** toute action qui nécessite un compte (favori, envoi de demande). Elle affiche une feuille modale si l'utilisateur n'est pas connecté, et renvoie `true` seulement s'il s'est authentifié avec succès.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/design/app_colors.dart';

/// Retourne true si l'utilisateur est (ou vient de se rendre) connecté.
/// Si non connecté, ouvre une feuille de connexion/inscription contextuelle.
/// À appeler avant toute action protégée : favori, envoi de demande.
Future<bool> exigerConnexion(BuildContext context, {String motif = "continuer"}) async {
  final auth = context.read<AuthProvider>();
  if (auth.connecte) return true;

  final resultat = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FeuilleConnexion(motif: motif),
  );
  return resultat ?? false;
}

class _FeuilleConnexion extends StatefulWidget {
  final String motif;
  const _FeuilleConnexion({required this.motif});

  @override
  State<_FeuilleConnexion> createState() => _FeuilleConnexionState();
}

class _FeuilleConnexionState extends State<_FeuilleConnexion> {
  bool _modeInscription = false;
  final _formKey = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _mdp = TextEditingController();
  bool _chargement = false;
  String? _erreur;

  Future<void> _valider() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _chargement = true; _erreur = null; });
    try {
      final auth = context.read<AuthProvider>();
      if (_modeInscription) {
        await auth.inscrire(_nom.text.trim(), _email.text.trim(), _mdp.text);
      } else {
        await auth.connecter(_email.text.trim(), _mdp.text);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _erreur = _modeInscription
          ? "Cet e-mail est peut-être déjà utilisé"
          : "E-mail ou mot de passe incorrect");
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Connecte-toi pour ${widget.motif}',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Ça prend 30 secondes, et tu peux continuer ta lecture juste après.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 20),
                if (_modeInscription)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextFormField(
                      controller: _nom,
                      decoration: const InputDecoration(labelText: 'Nom complet'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                    ),
                  ),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (v) => (v == null || !v.contains('@')) ? 'E-mail invalide' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _mdp,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 caractères' : null,
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 8),
                  Text(_erreur!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _chargement ? null : _valider,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vertPrimaire,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _chargement
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_modeInscription ? "S'inscrire" : "Se connecter",
                            style: const TextStyle(color: Colors.white)),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _modeInscription = !_modeInscription),
                    child: Text(_modeInscription
                        ? 'J\'ai déjà un compte — me connecter'
                        : 'Pas de compte — s\'inscrire'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

**Utilisation dans l'écran de détail (favori) :**
```dart
onTap: () async {
  final autorise = await exigerConnexion(context, motif: "ajouter cet article à tes favoris");
  if (autorise) await _basculerFavori(article);
}
```

**Utilisation dans l'écran de demande, juste avant l'envoi :**
```dart
Future<void> _envoyer() async {
  if (!_formKey.currentState!.validate()) return;
  final autorise = await exigerConnexion(context, motif: "envoyer ta demande");
  if (!autorise) return;
  // ... envoi normal
}
```

C'est exactement le comportement que tu avais demandé : zéro friction à l'ouverture, connexion demandée uniquement au moment pertinent.

---

## 2. Les tokens visuels — fidèles à tes captures d'écran

**`lib/core/design/app_colors.dart`**

```dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const vertPrimaire = Color(0xFF3CA35A);   // logo "AGRIDIGITALE", boutons, actifs
  static const vertFonce = Color(0xFF1F7A3D);
  static const fondClair = Color(0xFFFCF6F8);       // blanc légèrement rosé (vu sur tes captures)
  static const fondSombreAGDTV = Color(0xFF1C1E26);  // fond sombre de l'écran AGDTV
  static const grisTexte = Color(0xFF6B6B6B);
  static const grisIcone = Color(0xFF7C7C7C);
  static const grisLigne = Color(0xFFE7E7E7);
  static const grisPastille = Color(0xFFEDEDED);
  static const texteFort = Color(0xFF1A1A1A);
  static const erreur = Color(0xFFC62828);
}
```

**`lib/core/design/app_typography.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// PT Serif pour les grands titres de section (Weather, Settings, AGRIDIGITALE TV)
/// exactement comme sur ta maquette. Inter pour tout le reste (lisibilité, nav).
class AppTypography {
  AppTypography._();

  static TextTheme texte() => TextTheme(
    displaySmall: GoogleFonts.ptSerif(fontSize: 30, fontWeight: FontWeight.w600, color: AppColors.texteFort),
    titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.vertPrimaire),
    titleMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.texteFort),
    bodyLarge: GoogleFonts.inter(fontSize: 15, height: 1.5, color: AppColors.texteFort),
    bodyMedium: GoogleFonts.inter(fontSize: 13.5, height: 1.4, color: AppColors.grisTexte),
    labelSmall: GoogleFonts.inter(fontSize: 12, color: AppColors.grisTexte),
  );
}
```

**`lib/core/design/app_theme.dart`**

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get clair => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.fondClair,
    colorScheme: ColorScheme.light(primary: AppColors.vertPrimaire, error: AppColors.erreur),
    textTheme: AppTypography.texte(),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.fondClair, foregroundColor: AppColors.texteFort, elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    ),
  );
}
```

---

## 3. Écran d'accueil — carrousel, recherche, catégories, liste (fidèle à l'image 1)

D'abord, **un vrai problème de fond à régler côté backend** : tes catégories réelles issues du flux RSS (`Togo`, `Afrique`, `Monde`, `Agribusiness`, `Environnement`, `Dossiers`, etc.) ne correspondent pas aux onglets génériques que j'avais inventés (`News`, `Business`, `Agritech`). Il faut récupérer les vraies catégories depuis le backend plutôt que de les deviner — c'est très probablement pourquoi *« les catégories aussi c'est problème »*.

**Ajoute cette route côté backend** (`article.controller.js`) :
```js
exports.listerCategories = async (req, res, next) => {
  try {
    const categories = await Article.distinct('categorie');
    res.json(categories.filter(Boolean).sort());
  } catch (err) { next(err); }
};
```
```js
// article.routes.js
router.get('/categories', c.listerCategories); // avant la route /:id
```

**Côté Flutter, `services/article_service.dart`** — ajoute :
```dart
Future<List<String>> listerCategories() async {
  final rep = await _dio.get('/articles/categories');
  return List<String>.from(rep.data);
}
```

**`lib/screens/home/home_screen.dart`** — version corrigée et fidèle à la maquette

```dart
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
```

**`lib/widgets/banner_carousel.dart`** — le carrousel de bannières visible en haut de l'image 1

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});
  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _controleur = PageController(viewportFraction: 0.92);
  int _pageActuelle = 0;

  // À remplacer par un appel à ton endpoint /api/bannieres si tu en crées un côté admin.
  final List<String> _images = [
    // mets ici des URLs réelles de bannières, ou branche un service dédié
  ];

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) return const SizedBox.shrink(); // pas de bloc gris vide si aucune bannière
    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: _controleur,
        onPageChanged: (i) => setState(() => _pageActuelle = i),
        itemCount: _images.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(imageUrl: _images[i], fit: BoxFit.cover, width: double.infinity),
          ),
        ),
      ),
    );
  }
}
```
*Important : contrairement à mon ancienne version, ce widget **ne s'affiche pas du tout** s'il n'y a pas d'images — c'est ce qui évite le grand bloc gris vide que tu vois dans ta capture. Ne montre jamais un conteneur vide « en attendant » : montre-le seulement quand il a un contenu réel.*

---

## 4. Carte d'article — gestion d'image robuste (corrige « les photos ne s'affichent pas »)

```dart
// lib/widgets/article_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/article.dart';
import '../core/design/app_colors.dart';

class ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;
  const ArticleCard({super.key, required this.article, required this.onTap});

  bool get _aUneImageValide =>
      article.image != null && article.image!.trim().isNotEmpty && article.image!.startsWith('http');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _aUneImageValide
                  ? CachedNetworkImage(
                      imageUrl: article.image!,
                      width: 90, height: 90, fit: BoxFit.cover,
                      placeholder: (_, __) => Container(width: 90, height: 90, color: AppColors.grisPastille),
                      errorWidget: (_, __, ___) => _iconeParDefaut(), // si l'URL casse au chargement réel
                    )
                  : _iconeParDefaut(), // pas d'image du tout : jamais un carré blanc/cassé
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.categorie.toUpperCase(),
                    style: const TextStyle(color: AppColors.vertPrimaire, fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(article.titre, maxLines: 3, overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(DateFormat('dd MMM yyyy', 'fr_FR').format(article.datePublication),
                    style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconeParDefaut() => Container(
    width: 90, height: 90, color: AppColors.grisPastille,
    child: const Icon(Icons.eco, color: AppColors.vertPrimaire, size: 30),
  );
}
```
*La cause la plus fréquente d'images qui ne s'affichent pas : le champ `image` de l'article est `null` (le RSS n'a pas toujours d'image extraite) et l'ancien code ne vérifiait pas ce cas avant d'appeler `CachedNetworkImage`. Ici, `_aUneImageValide` filtre ça en amont — jamais d'erreur silencieuse, toujours une icône de repli propre.*

---

## 5. Recherche — corrigée avec anti-rebond (debounce)

Le bug le plus courant sur un champ de recherche connecté à une API : une requête est envoyée à **chaque lettre tapée**, ce qui sature le réseau et fait sembler l'app lente ou buguée. On corrige avec un `Timer` d'anti-rebond.

```dart
// lib/screens/home/search_screen.dart
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
```

---

## 6. AGDTV — thème sombre fidèle à l'image 2

```dart
// lib/screens/agdtv/agdtv_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/agdtv_service.dart';
import '../../models/video_agdtv.dart';
import '../../core/design/app_colors.dart';

class AgdtvScreen extends StatefulWidget {
  const AgdtvScreen({super.key});
  @override
  State<AgdtvScreen> createState() => _AgdtvScreenState();
}

class _AgdtvScreenState extends State<AgdtvScreen> {
  final _service = AgdtvService();
  late Future<List<VideoAGDTV>> _future;

  @override
  void initState() { super.initState(); _future = _service.lister(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondSombreAGDTV,
      body: SafeArea(
        child: FutureBuilder<List<VideoAGDTV>>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire));
            }
            final videos = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              children: [
                const Text('AGRIDIGITALE TV', textAlign: TextAlign.center, style: TextStyle(
                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text('The digital agricultural channel of the future', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 15)),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vertPrimaire,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => launchUrl(Uri.parse('https://www.youtube.com/@AGRIDIGITALETV')),
                    child: const Text('Ouvrir sur Youtube', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
                if (videos.isEmpty)
                  const Padding(padding: EdgeInsets.only(top: 40),
                    child: Center(child: Text('Aucune vidéo disponible pour le moment',
                      style: TextStyle(color: Colors.white54))))
                else
                  ...videos.map((v) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () => launchUrl(Uri.parse(v.urlYoutube), mode: LaunchMode.externalApplication),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(children: [
                          Image.network(v.vignette, width: double.infinity, height: 180, fit: BoxFit.cover),
                          Positioned(
                            left: 0, right: 0, bottom: 0,
                            child: Container(
                              color: Colors.black.withOpacity(0.55),
                              padding: const EdgeInsets.all(12),
                              child: Text(v.titre, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  )),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

---

## 7. Weather — bulletin + accordéon Archives (fidèle à l'image 3)

```dart
// lib/screens/weather/weather_screen.dart
import 'package:flutter/material.dart';
import '../../services/meteo_service.dart';
import '../../models/meteo.dart';
import '../../core/design/app_colors.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _service = MeteoService();
  late Future<Meteo> _future;
  bool _archivesOuvertes = false;

  @override
  void initState() { super.initState(); _future = _service.consulter(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Weather', style: Theme.of(context).textTheme.displaySmall)),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _service.consulter()),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FutureBuilder<Meteo>(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire)));
                }
                final m = snapshot.data!;
                return Text(m.description, style: Theme.of(context).textTheme.bodyLarge);
              },
            ),
            const SizedBox(height: 32),
            InkWell(
              onTap: () => setState(() => _archivesOuvertes = !_archivesOuvertes),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: const Color(0xFF9E9E9E), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.archive_outlined, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Archives', style: TextStyle(color: Colors.white, fontSize: 16))),
                  Icon(_archivesOuvertes ? Icons.expand_less : Icons.expand_more, color: Colors.white),
                ]),
              ),
            ),
            if (_archivesOuvertes)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Les bulletins précédents apparaîtront ici.',
                  style: TextStyle(color: AppColors.grisTexte)),
              ),
          ],
        ),
      ),
    );
  }
}
```

---

## 8. Settings — liste fidèle à l'image 5, avec entrée de connexion contextuelle

```dart
// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_gate.dart';
import '../../core/design/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _ligne(BuildContext context, IconData icone, String titre, {String? sousTitre, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          CircleAvatar(backgroundColor: AppColors.grisPastille, radius: 18,
            child: Icon(icone, color: AppColors.grisIcone, size: 18)),
          const SizedBox(width: 16),
          Expanded(child: Text(titre, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600))),
          if (sousTitre != null) Text(sousTitre, style: const TextStyle(color: AppColors.grisTexte)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: Text('settings', style: Theme.of(context).textTheme.displaySmall)),
      body: ListView(
        children: [
          if (!auth.connecte)
            _ligne(context, Icons.login, 'Se connecter / Créer un compte',
              onTap: () => exigerConnexion(context, motif: "accéder à ton profil")),
          if (auth.connecte)
            _ligne(context, Icons.logout, 'Déconnexion', onTap: () => auth.deconnecter()),
          const Divider(height: 1),
          _ligne(context, Icons.translate, 'Language', sousTitre: 'Français'),
          const Divider(height: 1),
          _ligne(context, Icons.share_outlined, 'Share Agridigitale'),
          const Divider(height: 1),
          _ligne(context, Icons.star_border, 'Rate Agridigitale'),
          const Divider(height: 1),
          _ligne(context, Icons.info_outline, 'About'),
          const Divider(height: 1),
          _ligne(context, Icons.notifications_none, 'Notification Management'),
          const Divider(height: 1),
          const SizedBox(height: 40),
          Container(
            width: double.infinity, color: const Color(0xFFF3F3F3),
            padding: const EdgeInsets.all(20),
            child: const Text('Copyright © 2026 Agridigitale', textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.vertPrimaire)),
          ),
        ],
      ),
    );
  }
}
```

---

## 9. Barre de navigation — icônes + libellé + point vert (fidèle à toutes tes captures)

```dart
// lib/screens/main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'weather/weather_screen.dart';
import 'agdtv/agdtv_screen.dart';
import 'request/request_screen.dart';
import 'settings/settings_screen.dart';
import '../core/design/app_colors.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _index = 0;
  final _icones = [Icons.home, Icons.cloud, Icons.tv, Icons.chat_bubble_outline, Icons.settings];
  final _labels = ['Home', 'Weather', 'AGDTV', 'Request', 'Settings'];
  final _ecrans = const [HomeScreen(), WeatherScreen(), AgdtvScreen(), RequestScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _ecrans),
      bottomNavigationBar: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_icones.length, (i) {
              final actif = i == _index;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _index = i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_icones[i], color: actif ? AppColors.vertPrimaire : Colors.black87, size: 24),
                      const SizedBox(height: 3),
                      if (actif)
                        Text(_labels[i], style: const TextStyle(
                          color: AppColors.vertPrimaire, fontWeight: FontWeight.w600, fontSize: 11)),
                      const SizedBox(height: 3),
                      Container(width: 5, height: 5, decoration: BoxDecoration(
                        color: actif ? AppColors.vertPrimaire : Colors.transparent, shape: BoxShape.circle)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
```

---

## 10. Ce qui rendait l'app lente — et comment on l'a corrigé ici

- **Trop d'animations perpétuelles** (`repeat()` sur des `AnimationController` qui tournaient même hors écran) consommaient du CPU en continu. Ici : plus aucune animation en boucle infinie, juste des transitions ponctuelles.
- **Widgets vides affichés « en attendant »** (carrousel gris, cartes grises) donnaient l'impression que l'app rame. Ici : un widget qui n'a rien à montrer **ne s'affiche pas du tout** (`SizedBox.shrink()`), jamais de bloc gris fantôme.
- **Recherche sans anti-rebond** envoyait une requête réseau à chaque frappe. Corrigé avec un `Timer` de 450 ms.
- **`AutomaticKeepAliveClientMixin`** sur `HomeScreen` évite de recharger tout le fil d'actualités à chaque fois que tu reviens sur l'onglet Home.

## 11. Checklist de vérification avant de continuer

1. Lance le backend, note l'IP/le port exact.
2. Mets à jour `_baseUrl` dans `api_client.dart` en conséquence (10.0.2.2 si émulateur).
3. Ajoute `android:usesCleartextTraffic="true"` si tu testes en HTTP local.
4. Lance l'app, regarde la console : tu dois voir les requêtes `LogInterceptor` avec un code 200.
5. Teste inscription → connexion → tu dois voir le token stocké et les futures requêtes avec `Authorization: Bearer ...` dans les logs.
6. Vérifie `/api/articles/categories` répond une vraie liste avant de tester les onglets.
7. Seulement après ces 6 étapes, juge le rendu visuel — pas avant, sinon tu ne sauras pas si un problème visuel vient d'un bug réseau sous-jacent.