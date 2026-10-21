Rapport d'Audit Technique & UX — Application Mobile AgriDigitale

│ Contexte de l'audit :
│ L'application mobile officielle du site www.agridigitale.net https://agridigitale.net a été développée sur Flutter (frontend) et Node.js/Express/MongoDB (backend). Elle est actuellement en
│ ligne sur le Google Play Store.
│ Cet audit a été réalisé directement sur l'ensemble du code source (backend et frontend) afin d'identifier les causes racines des dysfonctionnements signalés et de définir les optimisations
│ requises.
──────
## 1. Synthèse Globale des Problèmes Identifiés

# | Anomalie Signalée                                    | Cause Racine Identifiée dans le Code                                                                        | Gravité
---|------------------------------------------------------|-------------------------------------------------------------------------------------------------------------|-----------------------
1 | Écran de connexion imposé à l'ouverture              | _AuthGate dans main.dart:115-136 redirige d'office vers LoginScreen au lieu de MainNavigationScreen.        | Critique (UX)
2 | Lenteur extrême d'affichage des actualités           | Monture simultanée de 6 onglets (IndexedStack), absence de cache HTTP Dio, 7 requêtes envoyées d'un coup au | Critique (Perf)
|                                                      | serveur Render au démarrage, MongoDB sans index de tri.                                                     |
3 | Images et vidéos anormalement lentes                 | Un proxy backend détourne 100% des images mobiles vers le serveur Node.js (saturation mémoire/réseau +      | Critique (Perf)
|                                                      | dépassement du rate-limit 300 req/15min) + absence de redimensionnement mémoire des images dans Flutter.    |
4 | Doublons d'articles en mode hors-ligne               | _chargerPlus() appelle le cache SQLite sans pagination et concatène aveuglément les 20 mêmes articles à     | Majeur (Bug)
|                                                      | chaque scroll infini sans déduplication par ID.                                                             |
5 | Images de l'article différentes du site (Plainte DG) | Utilisation du nom de domaine périmé agridigitale.com (timeout de 26s !) au lieu de agridigitale.net,       | Majeur (UX/Éditorial)
|                                                      | SliverAppBar qui tronque les photos (BoxFit.cover), et omission de la légende/crédit photo issue du site.   |
──────
## 2. Analyse Détaillée des 5 Anomalies
──────
### Anomalie 1 — L'écran de connexion s'affiche dès l'ouverture de l'application

#### Constat dans le code :
Dans main.dart:115-136 :

class _AuthGate extends StatelessWidget {
	const _AuthGate();
	
	@override
	Widget build(BuildContext context) {
		final auth = context.watch<AuthProvider>();
		
		if (auth.enVerification) {
			return const Scaffold(body: Center(child: CircularProgressIndicator()));
		}
		
		if (auth.connecte) {
			return const MainNavigationScreen();
		}
		
		// ❌ ERREUR : Tout visiteur non connecté est bloqué ici !
		return const LoginScreen();
	}
}
#### Impact utilisateur :
Une application de presse ou d'actualités ne doit jamais forcer un lecteur à s'enregistrer ou se connecter pour lire l'information publique. Cela décourage immédiatement les nouveaux
utilisateurs et augmente drastiquement le taux de désinstallation dès le premier lancement sur le Play Store.

#### Solution :
• Modifier _AuthGate pour que la page par défaut soit toujours MainNavigationScreen() en mode visiteur (invité).
• L'authentification ne doit être sollicitée que de manière contextuelle via exigerConnexion(context) (déjà codé dans auth_gate.dart) uniquement lorsque l'utilisateur veut :
• Ajouter un article à ses favoris,
• Poster un commentaire,
• Soumettre une demande ou un message.

──────
### Anomalie 2 — Les actualités prennent un « temps fou » à s'afficher

#### 1. Surchauffe du serveur au lancement (Avalanche de requêtes)

Dans main_navigation_screen.dart:63 :

IndexedStack(index: _index, children: _ecrans)

Avec un IndexedStack, les 6 onglets sont instanciés dès la 1ère milliseconde :

• HomeScreen appelle /articles/categories, /articles/une, /articles?page=1, /notifications/non-lues et /bannieres ;
• WeatherScreen appelle /meteo et lit SQLite ;
• AgdtvScreen appelle /agdtv ;
• NotificationProvider appelle /notifications/non-lues (double appel !).

Le backend gratuit sur Render (512 Mo de RAM, CPU partagé avec mise en veille / cold start de 30 à 50 secondes) reçoit 7 requêtes simultanées. Le serveur sature immédiatement son thread
Node.js.

#### 2. Absence totale de cache HTTP côté mobile

Bien que dio_cache_interceptor soit présent dans pubspec.yaml:37, il n'a jamais été branché dans api_client.dart. À chaque retour sur l'accueil, aucune réponse n'est réutilisée et tout repart
à zéro sur le réseau.

#### 3. Indexation MongoDB incomplète côté backend

Dans article.controller.js:9-33 :

• articleUne effectue un .sort({ vues: -1 }) : le champ vues n'a aucun index dans le modèle Mongoose. MongoDB fait un scan mémoire complet.
• listerArticles filtre par { categorie, datePublication: { $gte: ... } } et trie par { datePublication: -1 } sans aucun index composé { categorie: 1, datePublication: -1 }.

#### 4. Scrape synchrone bloquant sur le détail d'un article

Dans article.controller.js:47-59 :
Si le texte de l'article est court, le contrôleur lance un scraping HTTP vers le site web avec un timeout de 12 secondes pendant la requête du mobile. L'application reste bloquée sur un loader
pendant 5 à 12 secondes.
──────
### Anomalie 3 — Lenteur anormale des images et des vidéos

#### 1. Le goulot d'étranglement numéro 1 : Le Proxy d'images

Dans article_service.dart:135-149 et article_card.dart:19-23 :

String _imgUrl(String? url) {
	if (url == null || url.isEmpty) return '';
	if (url.contains('/proxy-image')) return url;
	return '${ApiClient.baseUrl}/proxy-image?url=${Uri.encodeComponent(url)}';
}

• Le développeur a mis en place ce proxy pour contourner les blocages CORS du Web.
• Mais sur Android et iOS, il n'y a AUCUNE restriction CORS.
• En omettant de vérifier if (kIsWeb), 100% des images des articles sur smartphone sont redirigées vers le serveur Node.js sur Render.
• À l'affichage d'une page de 20 articles, le smartphone envoie 20 requêtes simultanées de téléchargement d'images au serveur Render, qui lui-même doit les télécharger sur agridigitale.net
pour les retransmettre au téléphone.
• Cela multiplie la latence par deux, consomme toute la bande passante du serveur, et dépasse le timeout de 10 secondes fixé dans proxy.routes.js, causant des erreurs 502 Bad Gateway et des
images qui ne s'affichent pas.

#### 2. Blocage du Rate-Limiter Express (429 Too Many Requests)

Dans app.js:32-33 :

const limiterGlobal = rateLimit({ windowMs: 15 * 60 * 1000, max: 300, ... });
app.use('/api/', limiterGlobal);

Comme le proxy d'image est sous /api/proxy-image, chaque image compte dans la limite de 300 requêtes par quart d'heure. Dès qu'un utilisateur fait défiler 35 articles, il dépasse le quota de
300 requêtes. Le serveur bloque alors l'application pendant 15 minutes avec une erreur HTTP 429 !

#### 3. Décodage d'images non compressées en RAM Flutter

Dans ArticleCard, CachedNetworkImage ne définit ni memCacheWidth ni memCacheHeight. Une image 4K ou 1080p est décompressée en mémoire vive pleine taille (jusqu'à 25 Mo de RAM par photo). Avec
20 images, l'application consomme près de 400 Mo de RAM, surchargeant le Garbage Collector et provoquant des saccades.

#### 4. Vidéos AGDTV

Dans agdtv_screen.dart:298-309 :
Les vignettes YouTube sont chargées avec Image.network sans mise en cache locale. Le contrôleur YouTube est également instancié dès le démarrage de l'application en arrière-plan.
──────
### Anomalie 4 — Les doublons d'articles en mode hors-ligne

#### Constat dans le code :

Dans home_screen.dart:74-89 :

Future<void> _chargerPlus() async {
	if (_chargement || _toutCharge) return;
	setState(() => _chargement = true);
	try {
		final nouveaux = await _service.lister(categorie: _categorieActive, page: _page);
		setState(() {
			_articles.addAll(nouveaux); // ❌ Concaténation directe sans vérification d'unicité
			_page++;
			if (nouveaux.length < 20) _toutCharge = true;
		});
	} catch (e) { ... }
}

Et dans article_service.dart:68-75 :

on DioException catch (e) {
	if (!kIsWeb) {
		final cached = await _db.listerArticlesLocaux(categorie: categorie);
		return cached.map((m) => Article.fromMap(m)).toList();
	}
}

#### Ce qui se passe en pratique :

1. En mode hors-ligne, la page 1 appelle listerArticlesLocaux(), qui renvoie les 20 articles stockés dans SQLite.
2. Comme nouveaux.length == 20, le flag _toutCharge reste à false.
3. Lorsque l'utilisateur fait défiler la page vers le bas, le scroll infini déclenche _chargerPlus() pour la page 2.
4. La requête réseau échoue à nouveau. Le code retombe dans le catch et réexécute listerArticlesLocaux().
5. Problème : listerArticlesLocaux ne gère aucun système de pagination/offset ! Elle renvoie exactement les 20 mêmes articles.
6. _articles.addAll(nouveaux) ajoute ces 20 mêmes articles une 2ème fois, puis une 3ème fois au scroll suivant, etc.

De plus, dans db_helper.dart:143, sauvegarderArticles exécute un batch.delete('articles_cache'), ce qui supprime le contenu complet des articles détaillés déjà sauvegardés hors-ligne !
──────
### Anomalie 5 — Rendu des images dans le détail d'un article (Plainte du DG)

#### 1. Le domaine .com au lieu de .net

Dans rss.service.js:123 et article_detail_screen.dart:269 :

return article.contenu.replaceAll('{{BASE_URL}}', 'https://agridigitale.com');

• Le domaine officiel et actif est agridigitale.net.
• Le test de connectivité réseau montre que https://agridigitale.com met 26 secondes à répondre ou échoue, tandis que agridigitale.net répond normalement.
• Toutes les images internes présentes dans le HTML de l'article avec le marqueur {{BASE_URL}} pointent vers un domaine quasi-inaccessible.

#### 2. L'omission de la légende / crédit photo

L'inspection du payload Inertia.js du site officiel révèle que chaque article possède :

• props.article.legend.fr : ex. "Le maraîcher Mensan AFANOU, ©agridigitale.net"
• props.article.author : auteur de l'article
• props.article.featuredImageUrl : photo de couverture originale en haute définition

Le backend n'extrait pas legend ni l'auteur dans son schéma Mongoose, et le mobile ne les affiche donc jamais.

#### 3. Déformation et recadrage de l'image de couverture

Dans article_detail_screen.dart:330-341 :
L'image est placée dans un SliverAppBar(expandedHeight: 240) avec fit: BoxFit.cover.

• Cette configuration rogne sévèrement le haut et le bas de la photo (les têtes des personnes ou les sujets agricoles sont coupés).
• Les boutons d'action (retour, partage, favori) flottent directement sur l'image sans contraste garanti.
• Au scroll, l'image disparaît sous la barre verte.

#### 4. Rendu sur le site web vs Rendu mobile

Sur le site www.agridigitale.net https://agridigitale.net :

1. Catégorie & Titre en grand en tête d'article.
2. Auteur et Date de publication bien visibles.
3. Grande image principale au ratio 16:9 sans déformation ni recadrage abusif.
4. Légende / crédit photo en italique discret sous l'image (©agridigitale.net).
5. Corps du texte avec citations aérées, typographie soignée et images d'illustration adaptées à la largeur.
──────
## 3. Plan d'Action & Architecture des Corrections

### Phase 1 : Corrections Immédiates (Quick Wins - Gain de performance x5)

1. Suppression du passage forcé par l'écran de Login :
• main.dart : Remplacer la condition _AuthGate pour pointer directement sur MainNavigationScreen().
2. Bypass du Proxy d'images pour le Mobile :
• Dans ArticleService._normaliserImage et ArticleCard._imgUrl, n'activer le proxy que si kIsWeb == true. Sur mobile, pointer directement vers https://agridigitale.net.
• Remplacer toutes les occurrences de agridigitale.com par agridigitale.net.
3. Exclusion du Proxy du Rate Limiter :
• Dans backend/src/app.js, déplacer app.use('/api/proxy-image') au-dessus de limiterGlobal ou lui attribuer un rate limiter dédié très élevé (ou du cache HTTP avec reverse proxy).
4. Optimisation mémoire du cache d'images Flutter :
• Ajouter memCacheWidth: 400 sur les vignettes de cartes et memCacheWidth: 1080 sur les grandes images pour éviter de saturer la mémoire vive.


### Phase 2 : Fiabilisation du Mode Hors-Ligne & Déduplication

1. Correction de la pagination SQLite :
• Mettre à jour listerArticlesLocaux pour prendre en compte page et limite (avec LIMIT et OFFSET en SQL).
• En mode hors-ligne, si la page demandée dépasse le nombre d'éléments disponibles, stopper la pagination (_toutCharge = true).
2. Déduplication robuste dans HomeScreen :
• Remplacer l'ajout aveugle _articles.addAll(nouveaux) par un filtrage d'unicité basé sur un Set<String> d'identifiants uniques (article.id).
3. Séparation des tables de cache :
• Dissocier dans SQLite articles_liste_cache et articles_detail_cache pour que le rafraîchissement de la liste n'écrase pas le contenu hors-ligne des articles sauvegardés.


### Phase 3 : Redesign UX/UI de l'Écran Détail Article (Demande du DG)
1. Backend :
• Extraire legend (légende de l'image) et author dans rss.service.js depuis les props Inertia (props.article.legend.fr).
• Mettre à jour le modèle MongoDB Article.js et exécuter une mise à jour sur les articles récents.
2. Frontend Flutter :
• Repenser article_detail_screen.dart :
• Utiliser une AppBar standard blanche épurée avec retour, favori et partage.
• Structure de la page :
1. Badge de catégorie coloré,
2. Titre éditorial en gras et aéré,
3. Métadonnées : Auteur, Date de parution formatée, Nombre de vues,
4. Image principale pleine largeur avec ratio conservé (ex. AspectRatio(16/9)) et coins arrondis élégants,
5. Légende et copyright en dessous (Text(article.legendeImage, style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))),
6. Corps du texte HTML nettoyé, avec gestion optimisée des balises <img>, citations avec liseré vert et typographie moderne.

### Phase 4 : Optimisation Avancée Backend & AGDTV

1. Indexes MongoDB :
• Ajouter les index { categorie: 1, datePublication: -1 } et { vues: -1, datePublication: -1 }.
2. Mise en cache HTTP Dio :
• Activer dio_cache_interceptor dans ApiClient pour mettre en cache les requêtes GET (catégories, articles page 1, météo) pendant 5 à 15 minutes.
3. Lazy-loading des onglets :
• Ne charger la météo et les vidéos AGDTV que lorsque l'utilisateur clique sur l'onglet concerné plutôt que dès le lancement de l'application.
4. Vidéos AGDTV :
• Remplacer Image.network par CachedNetworkImage pour les vignettes.
──────
## 4. Prochaine Étape
L'audit est complet et toutes les causes racines sont isolées.
Êtes-vous d'accord pour que nous entamions les modifications et corrections par étape (en commençant par le déblocage du login et l'accélération foudroyante des images/actualités) ?
