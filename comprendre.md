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
