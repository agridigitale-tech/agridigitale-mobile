# Documentation API AgriDigitale

Base URL : `https://agridigitale-production.up.railway.app/api`

---

##  Authentification

### POST `/auth/inscription`
Inscrire un nouvel utilisateur.

**Body :**
```json
{
  "nom": "Jean Dupont",
  "email": "jean@example.com",
  "motDePasse": "motdepasse123",
  "pays": "Togo",
  "codePays": "TG"
}
```

**Réponse (201) :**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "utilisateur": {
    "id": "665f1a2b3c4d5e6f7a8b9c0d",
    "nom": "Jean Dupont",
    "email": "jean@example.com",
    "role": "utilisateur"
  }
}
```

---

### POST `/auth/connexion`
Connecter un utilisateur existant.

**Body :**
```json
{
  "email": "jean@example.com",
  "motDePasse": "motdepasse123"
}
```

**Réponse (200) :**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "utilisateur": {
    "id": "665f1a2b3c4d5e6f7a8b9c0d",
    "nom": "Jean Dupont",
    "email": "jean@example.com",
    "role": "utilisateur"
  }
}
```

---

### GET `/auth/profil` 
Récupérer le profil de l'utilisateur connecté.

**Headers :** `Authorization: Bearer <token>`

**Réponse (200) :**
```json
{
  "_id": "665f1a2b3c4d5e6f7a8b9c0d",
  "nom": "Jean Dupont",
  "email": "jean@example.com",
  "role": "utilisateur",
  "photo": null,
  "preferencesRubriques": [],
  "theme": "clair",
  "langue": "fr",
  "pays": "Togo",
  "continent": "Afrique",
  "actif": true,
  "createdAt": "2024-06-01T10:00:00.000Z"
}
```

---

### PUT `/auth/profil` 
Modifier le profil de l'utilisateur connecté.

**Headers :** `Authorization: Bearer <token>`

**Body :**
```json
{
  "nom": "Jean Nouveau",
  "theme": "sombre",
  "langue": "en",
  "preferencesRubriques": ["Agriculture", "Économie"]
}
```

**Réponse (200) :** Objet utilisateur mis à jour

---

### POST `/auth/token-fcm` 🔒
Enregistrer le token Firebase pour les notifications push.

**Body :**
```json
{
  "token": "fcm_token_ici..."
}
```

**Réponse :** `204 No Content`

---

### POST `/auth/forgot-password`
Demander un lien de réinitialisation du mot de passe.

**Body :**
```json
{
  "email": "jean@example.com"
}
```

**Réponse (200) :**
```json
{
  "success": true
}
```

---

### POST `/auth/reset-password`
Réinitialiser le mot de passe avec le token.

**Body :**
```json
{
  "token": "token_recu_par_email",
  "nouveauMotDePasse": "nouveau123"
}
```

**Réponse (200) :**
```json
{
  "success": true,
  "message": "Mot de passe réinitialisé avec succès"
}
```

---

## 📰 Articles

### GET `/articles`
Lister tous les articles (avec pagination).

**Query params :**
- `page` (défaut: 1)
- `limite` (défaut: 20)
- `categorie` (optionnel)

**Réponse (200) :**
```json
{
  "articles": [...],
  "total": 150,
  "page": 1,
  "pages": 8
}
```

---

### GET `/articles/une`
Récupérer l'article à la une.

**Réponse (200) :** Objet article

---

### GET `/articles/recherche`
Rechercher des articles.

**Query params :**
- `q` : terme de recherche
- `page` (défaut: 1)
- `limite` (défaut: 20)

**Réponse (200) :**
```json
{
  "articles": [...],
  "total": 25,
  "page": 1,
  "pages": 2
}
```

---

### GET `/articles/categories`
Lister toutes les catégories disponibles.

**Réponse (200) :**
```json
{
  "categories": ["Agriculture", "Économie", "Technologie", "Élevage"]
}
```

---

### GET `/articles/:id`
Récupérer le détail d'un article.

**Réponse (200) :**
```json
{
  "_id": "665f1a2b3c4d5e6f7a8b9c0d",
  "guid": "unique-id",
  "titre": "Titre de l'article",
  "contenu": "Contenu HTML...",
  "resume": "Résumé...",
  "image": "https://...",
  "lienSource": "https://...",
  "categorie": "Agriculture",
  "datePublication": "2024-06-01T10:00:00.000Z",
  "vues": 125,
  "dateRecuperation": "2024-06-01T12:00:00.000Z"
}
```

---

## 💬 Commentaires

### GET `/articles/:articleId/commentaires`
Lister les commentaires d'un article.

**Réponse (200) :**
```json
{
  "commentaires": [
    {
      "_id": "...",
      "contenu": "Super article !",
      "nomAuteur": "Jean",
      "auteur": "665f1a2b...",
      "createdAt": "2024-06-01T10:00:00.000Z"
    }
  ]
}
```

---

### POST `/articles/:articleId/commentaires` 🔒
Ajouter un commentaire.

**Body :**
```json
{
  "contenu": "Super article !"
}
```

**Réponse (201) :** Objet commentaire créé

---

### DELETE `/articles/:articleId/commentaires/:id` 🔒
Supprimer un commentaire (auteur uniquement).

**Réponse (200) :**
```json
{
  "message": "Commentaire supprimé"
}
```

---

## ⭐ Favoris

### POST `/favoris` 🔒
Ajouter un article en favori.

**Body :**
```json
{
  "articleId": "665f1a2b3c4d5e6f7a8b9c0d"
}
```

**Réponse (201) :**
```json
{
  "message": "Article ajouté aux favoris"
}
```

---

### GET `/favoris` 🔒
Lister les favoris de l'utilisateur.

**Réponse (200) :**
```json
{
  "favoris": [
    {
      "_id": "...",
      "article": { ... },
      "createdAt": "2024-06-01T10:00:00.000Z"
    }
  ]
}
```

---

### DELETE `/favoris/:articleId` 🔒
Retirer un article des favoris.

**Réponse (200) :**
```json
{
  "message": "Article retiré des favoris"
}
```

---

## 🌤️ Météo

### GET `/meteo`
Consulter la météo actuelle.

**Réponse (200) :**
```json
{
  "zone": "Lomé",
  "temperature": 28,
  "description": "Ensoleillé",
  "icone": "01d",
  "humidite": 65,
  "vitesseVent": 12,
  "dateMiseAJour": "2024-06-01T10:00:00.000Z"
}
```

---

### GET `/meteo/archives`
Récupérer les archives météo.

**Réponse (200) :** Tableau d'objets météo

---

### GET `/meteo/ville/:ville`
Rechercher la météo d'une ville.

**Exemple :** `GET /meteo/ville/Paris`

**Réponse (200) :** Objet météo

---

### POST `/meteo` 🔒👑
Publier une météo manuelle (admin uniquement).

**Body :** `multipart/form-data`
- `zone` : nom de la zone
- `temperature` : température
- `description` : description
- `photoMeteo` : image (optionnel)

**Réponse (201) :** Objet météo créé

---

## 📺 AGDTV (Vidéos)

### GET `/agdtv`
Lister les vidéos de la chaîne YouTube AgriDigitale TV.

**Réponse (200) :**
```json
{
  "videos": [
    {
      "_id": "...",
      "idYoutube": "dQw4w9WgXcQ",
      "titre": "Titre de la vidéo",
      "vignette": "https://i.ytimg.com/...",
      "datePublication": "2024-06-01T10:00:00.000Z"
    }
  ]
}
```

---

## 📩 Demandes (Contact/Support)

### POST `/demandes` 🔒
Envoyer une demande (contact, support, etc.).

**Rate limit :** 3 demandes par heure

**Body :**
```json
{
  "nomComplet": "Jean Dupont",
  "profession": "Agriculteur",
  "email": "jean@example.com",
  "telephone": "+228 90 12 34 56",
  "message": "Je souhaite..."
}
```

**Réponse (201) :**
```json
{
  "message": "Demande envoyée avec succès"
}
```

---

### GET `/demandes` 🔒👑
Lister toutes les demandes (admin uniquement).

**Réponse (200) :**
```json
{
  "demandes": [...]
}
```

---

### PUT `/demandes/:id/traiter` 🔒👑
Traiter une demande (admin uniquement).

**Body :**
```json
{
  "statut": "TRAITE"
}
```

**Statuts possibles :** `EN_ATTENTE`, `TRAITE`, `REJETE`

**Réponse (200) :** Objet demande mis à jour

---

## 🔔 Notifications

### GET `/notifications` 🔒
Lister les notifications de l'utilisateur.

**Réponse (200) :**
```json
{
  "notifications": [
    {
      "_id": "...",
      "titre": "Nouvel article",
      "message": "Un nouvel article a été publié",
      "lu": false,
      "dateEnvoi": "2024-06-01T10:00:00.000Z",
      "article": "665f1a2b..."
    }
  ]
}
```

---

### GET `/notifications/non-lues` 🔒
Compter les notifications non lues.

**Réponse (200) :**
```json
{
  "nonLues": 5
}
```

---

### POST `/notifications/marquer-lues` 🔒
Marquer toutes les notifications comme lues.

**Réponse (200) :**
```json
{
  "message": "Notifications marquées comme lues"
}
```

---

### POST `/notifications/manuelle` 🔒👑
Envoyer une notification à tous les utilisateurs (admin).

**Body :**
```json
{
  "titre": "Maintenance",
  "message": "Le serveur sera en maintenance demain"
}
```

**Réponse (201) :**
```json
{
  "message": "Notification envoyée à X utilisateurs"
}
```

---

## 🖼️ Bannières

### GET `/bannieres`
Lister les bannières actives (publiques).

**Réponse (200) :**
```json
{
  "bannieres": [
    {
      "_id": "...",
      "image": "https://...",
      "titre": "Promo été",
      "description": "...",
      "lien": "https://...",
      "type": "promo",
      "dateDebut": "...",
      "dateFin": "..."
    }
  ]
}
```

---

### GET `/bannieres/admin` 🔒👑
Lister toutes les bannières (admin).

**Réponse (200) :** Tableau de toutes les bannières

---

### POST `/bannieres` 🔒👑
Créer une bannière (admin).

**Body :** `multipart/form-data`
- `image` : fichier image (requis)
- `titre` : titre (optionnel)
- `description` : description (optionnel)
- `lien` : lien externe (optionnel)
- `type` : `pub`, `promo`, ou `banniere`
- `dateDebut` : date de début
- `dateFin` : date de fin

**Réponse (201) :** Objet bannière créé

---

### PUT `/bannieres/:id` 🔒👑
Modifier une bannière (admin).

**Réponse (200) :** Objet bannière mis à jour

---

### DELETE `/bannieres/:id` 🔒👑
Supprimer une bannière (admin).

**Réponse (200) :**
```json
{
  "message": "Bannière supprimée"
}
```

---

## 👑 Administration

### GET `/admin/statistiques` 🔒👑
Récupérer les statistiques globales.

**Réponse (200) :**
```json
{
  "utilisateurs": 1250,
  "articles": 3500,
  "favoris": 890,
  "demandes": 45,
  "commentaires": 670,
  "notifications": 2300
}
```

---

### GET `/admin/utilisateurs` 🔒👑
Lister tous les utilisateurs.

**Réponse (200) :**
```json
{
  "utilisateurs": [...]
}
```

---

### PUT `/admin/utilisateurs/:id/desactiver` 🔒👑
Désactiver un compte utilisateur.

**Réponse (200) :**
```json
{
  "message": "Utilisateur désactivé"
}
```

---

### PUT `/admin/utilisateurs/:id/promouvoir` 
Promouvoir un utilisateur en administrateur.

**Réponse (200) :**
```json
{
  "message": "Utilisateur promu administrateur"
}
```

---

### PUT `/admin/utilisateurs/:id/retrograder` 
Rétrograder un administrateur en utilisateur.

**Réponse (200) :**
```json
{
  "message": "Administrateur rétrogradé"
}
```

---

##  Proxy Image

### GET `/proxy-image?url=<encoded_url>`
Proxy les images pour éviter les problèmes CORS.

**Query params :**
- `url` : URL encodée de l'image (uniquement agridigitale.com ou agridigitale.net)

**Réponse :** Flux d'image avec cache 24h

---

##  Légende

- 🔒 = Nécessite un token d'authentification
- 👑 = Réservé aux administrateurs

---

##  Rate Limiting

| Endpoint | Limite |
|----------|--------|
| `/api/*` (global) | 300 requêtes / 15 min |
| `/api/auth/*` | 50 requêtes / 15 min |
| `/api/demandes` | 3 requêtes / heure |

---

## 🗄️ Modèles de Données

### Utilisateur
| Champ | Type | Description |
|-------|------|-------------|
| nom | String | Nom complet |
| email | String | Email unique |
| motDePasse | String | Hash bcrypt (select: false) |
| photo | String | URL photo de profil |
| role | String | `utilisateur` ou `administrateur` |
| preferencesRubriques | [String] | Rubriques préférées |
| tokenFCM | String | Token Firebase Cloud Messaging |
| theme | String | `clair` ou `sombre` |
| langue | String | `fr` ou `en` |
| pays | String | Pays de l'utilisateur |
| continent | String | Continent |
| actif | Boolean | Compte actif |

### Article
| Champ | Type | Description |
|-------|------|-------------|
| guid | String | ID unique du flux RSS |
| titre | String | Titre de l'article |
| contenu | String | Contenu HTML |
| resume | String | Résumé |
| image | String | URL de l'image |
| lienSource | String | Lien vers l'article source |
| categorie | String | Catégorie |
| datePublication | Date | Date de publication |
| vues | Number | Nombre de vues |

### Demande
| Champ | Type | Description |
|-------|------|-------------|
| nomComplet | String | Nom complet |
| profession | String | Profession |
| email | String | Email |
| telephone | String | Téléphone |
| message | String | Message |
| statut | String | `EN_ATTENTE`, `TRAITE`, `REJETE` |
| utilisateur | ObjectId | Référence vers Utilisateur |

### Notification
| Champ | Type | Description |
|-------|------|-------------|
| titre | String | Titre |
| message | String | Contenu |
| lu | Boolean | Notification lue |
| article | ObjectId | Article lié (optionnel) |
| destinataire | ObjectId | Utilisateur destinataire |

### Bannière
| Champ | Type | Description |
|-------|------|-------------|
| image | String | URL de l'image |
| titre | String | Titre |
| description | String | Description |
| lien | String | Lien externe |
| ordre | Number | Ordre d'affichage |
| actif | Boolean | Active |
| type | String | `pub`, `promo`, `banniere` |
| dateDebut | Date | Date de début |
| dateFin | Date | Date de fin |

### Commentaire
| Champ | Type | Description |
|-------|------|-------------|
| article | ObjectId | Article commenté |
| auteur | ObjectId | Auteur du commentaire |
| nomAuteur | String | Nom affiché |
| contenu | String | Texte (max 1000 car.) |

### Favori
| Champ | Type | Description |
|-------|------|-------------|
| utilisateur | ObjectId | Utilisateur |
| article | ObjectId | Article favori |

### Meteo
| Champ | Type | Description |
|-------|------|-------------|
| zone | String | Nom de la zone |
| temperature | Number | Température en °C |
| description | String | Description |
| icone | String | Code icône OpenWeather |
| humidite | Number | Pourcentage humidité |
| vitesseVent | Number | Vitesse du vent |
| source | String | `api` ou `manuel` |

### VideoAGDTV
| Champ | Type | Description |
|-------|------|-------------|
| idYoutube | String | ID de la vidéo YouTube |
| titre | String | Titre |
| vignette | String | URL miniature |
| datePublication | Date | Date de publication |

### FeedRSS
| Champ | Type | Description |
|-------|------|-------------|
| url | String | URL du flux RSS |
| titre | String | Titre du flux |
| langage | String | Langue (défaut: fr) |
| intervalleRefresh | Number | Intervalle en minutes |
