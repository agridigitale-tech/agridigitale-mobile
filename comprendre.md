Étape 1 : Les Modèles (src/models/)Ce que c'est : Les moules ou les fiches techniques des ingrédients.
Vous avez créé les modèles (Utilisateur.js, Article.js, etc.).
Cela sert à dire à votre application : "Un utilisateur aura obligatoirement un nom, un email et un mot de passe. Un article aura un titre et un lien."
À ce stade : Tout cela n'est que du texte sur votre ordinateur, rien n'est encore connecté ni vivant.

Étape 2 : Le fichier d'environnement 
(.env)Ce que c'est : Votre coffre-fort secret.On y a stocké l'adresse de votre base de données en ligne (MongoDB Atlas) avec votre mot de passe secret (MONGO_URI), le numéro du port (5000), etc.
Node.js lit ce fichier pour savoir où se connecter sur Internet sans afficher vos mots de passe secrets aux yeux de tout le monde.

Étape 3 : La connexion à la base (src/config/db.js)Ce que c'est : Le câble réseau.Ce fichier contient une fonction (connectDB) qui prend l'adresse secrète du fichier .env et tente d'ouvrir un tunnel de communication entre votre ordinateur et les serveurs de MongoDB Atlas sur Internet.

Étape 4 : L'infrastructure Express (src/app.js)Ce que c'est : Les murs et la sécurité du restaurant.
C'est ici qu'on configure Express. 
On lui ajoute des vigiles de sécurité (helmet), un système pour autoriser l'application mobile à entrer (cors), et un carnet pour noter les visites (morgan).
On a écrit une seule route de test tout en bas : si quelqu'un va sur l'adresse principale, on lui répond "Bienvenue sur l'API AgriDigitale !".Enfin, on exporte toute cette configuration pour que le fichier principal (server.js) puisse l'utiliser.

Étape 5 : Le chef d'orchestre (server.js)Ce que c'est : Le directeur qui allume les lumières et ouvre le restaurant.
C'est le fichier racine. Quand vous tapez npm run dev, Node.js ouvre uniquement ce fichier.server.js fait l'enchaînement suivant :Il appelle db.js pour dire : "Connecte-toi à MongoDB !" (C'est là que la console affiche MongoDB connecté).
Il démarre les tâches automatiques en arrière-plan (comme la fonction vide du flux RSS).
Il appelle app.js et lui dit : "Maintenant, ouvre les portes sur le port 5000 et attends les clients." 
(C'est là que la console affiche 🚀 Serveur démarré sur le port 5000).

il faut obligatoirement ces deux clés distinctes pour faire fonctionner le module de synchronisation YouTube (AGDTV). La première sert de mot de passe pour interroger Google, tandis que la seconde cible la chaîne YouTube d'AgriDigitale

app.js
app.use(helmet());     // Active les vigiles de sécurité sur les en-têtes HTTP
app.use(cors());       // Donne l'autorisation officielle à l'application mobile d'accéder à l'API
app.use(morgan('dev')); // Écrit en temps réel dans votre console les pages visitées (ex: GET /api/articles 200)
app.use(express.json()); // Permet au serveur de comprendre le format JSON quand le téléphone envoie des données

server.js
demarrerScheduler() ➔ Lance le robot RSS immédiatement, puis le configure pour s'exécuter toutes les 15 minutes.cron.schedule('0 * * * *', mettreAJourMeteo) ➔ Planifie la mise à jour de la météo de Lomé au début de chaque heure (ex: 13h00, 14h00, etc.).cron.schedule('0 */3 * * *', synchroniserVideos) ➔ Planifie la récupération des vidéos YouTube AgriDigitale toutes les 3 heures.mettreAJourMeteo() et synchroniserVideos() ➔ Force une exécution immédiate de la météo et de YouTube dès que vous allumez le serveur, sans attendre le premier déclenchement de l'horloge.

npm install express-rate-limit
npm install firebase-admin
npm install multer

flutter pub upgrade --major-versions
flutter pub upgrade firebase_core firebase_messaging


1. Le Cœur du Système et la Gestion d'Étatprovider : 
C'est le cerveau organisationnel. Il surveille et partage les données de l'application en temps réel (comme l'état de connexion de l'utilisateur ou le mode sombre) avec tous les écrans, et force l'interface à se mettre à jour dès qu'un changement survient.flutter_phoenix : Permet à l'application de se redémarrer elle-même proprement depuis le code (Hot Restart In-App). C'est parfait pour réinitialiser complètement l'état de l'application après une action majeure (comme l'activation des notifications ou un changement de langue complet).

2. Le Réseau et la Communication (Liaison Backend)dio : 
C'est le moteur de tes requêtes internet. Plus puissant et flexible que le module http de base, il s'occupe d'envoyer et de recevoir les données entre ton téléphone et ton serveur Node.js (inscription, connexion, météo, demandes...).dio_cache_interceptor : C'est un économiseur de forfait mobile. Il intercepte les requêtes réseau de dio pour mettre en cache les réponses textuelles du backend. Si l'agriculteur recharge la même page 2 minutes plus tard, l'application charge les données instantanément sans consommer sa connexion internet.

3. La Sécurité et la Mémoire (Stockage)flutter_secure_storage : 
Le coffre-fort chiffré. Il sert à stocker de manière hautement sécurisée le Token JWT d’authentification. Les données y sont cryptées par le processeur du smartphone, empêchant le vol d'identité.shared_preferences : La mémoire des réglages simples. Il sert à sauvegarder les petites préférences non sensibles de l'utilisateur, comme son choix de thème (clair/sombre) ou sa langue, pour que l'application s'en souvienne au prochain démarrage.

4. Le Mode Hors-Ligne (Gestion des Champs)connectivity_plus : 
Le détecteur de réseau. Il vérifie constamment si le smartphone est connecté à Internet (Wi-Fi, 4G) ou s'il est totalement déconnecté (hors-ligne au milieu d'une plantation).sqflite & path & path_provider : La base de données locale (SQLite). Quand connectivity_plus détecte que l'agriculteur n'a plus internet, ces paquets prennent le relais pour stocker ou lire les articles favoris directement dans la mémoire physique du smartphone.

5. Les Notifications et les Alertesfirebase_core & firebase_messaging : 
Les bâtisseurs d'alertes. Ils connectent ton application Flutter aux serveurs de Google Firebase pour s'occuper de la réception des notifications push (alertes météo ou nouveaux articles) même quand l'application est fermée.app_settings : Le passe-partout système. C'est le composant que tu cherchais pour rediriger directement l'agriculteur de l'application vers la page des paramètres natifs de son propre smartphone afin qu'il active manuellement l'autorisation des notifications si elle a été bloquée.

6. Le Multimédia et l'Interface Visuelleyoutube_player_flutter : 
Le lecteur vidéo physique d'AGDTV. Il intègre le vrai lecteur YouTube à l'intérieur de tes écrans pour lire directement les flux vidéos sans quitter AgriDigitale.cached_network_image : Le chargeur d'images intelligent. Il télécharge les photos des articles RSS et de la météo, puis les enregistre en cache. L'image s'affiche instantanément la fois suivante, même sans réseau.image_picker : L'accès à l'appareil photo. C'est le module indispensable pour permettre à l'administrateur de prendre une photo avec son téléphone ou d'ouvrir sa galerie locale afin de charger une image.google_fonts : Le catalogue de polices de caractères. Il permet d'appliquer de superbes typographies modernes pour rendre l'application lisible et professionnelle.cupertino_icons : Fournit les icônes officielles au style Apple/iOS.

7. Les Fonctionnalités Utiles au Quotidienintl & flutter_localizations : 
Les traducteurs. Ils s'assurent que les dates, les heures et les calendriers s'affichent proprement dans le format officiel en français (ex: "mercredi 22 juillet" au lieu du format américain).url_launcher : Le déclencheur externe. Il permet à l'application mobile d'ouvrir le navigateur du téléphone si l'agriculteur veut consulter le site source d'un article RSS.share_plus : Le bouton de partage. Il permet à l'agriculteur de cliquer sur un article pour l'envoyer directement à ses collègues via WhatsApp, SMS ou par e-mail.