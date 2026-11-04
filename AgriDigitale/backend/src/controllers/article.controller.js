const Article = require('../models/Article');
const Banniere = require('../models/Banniere');

// Cache mémoire pour la liste des catégories (évite un distinct() lourd sur toute la base à chaque ouverture d'app)
let categoriesCache = null;
let categoriesCacheTime = 0;
const CATEGORIES_CACHE_TTL = 10 * 60 * 1000; // 10 minutes

// Route agrégée haute performance pour l'accueil (1 seul appel HTTP au lieu de 4 ou 6)
exports.dashboardAccueil = async (req, res, next) => {
  try {
    const now = new Date();
    const troisMois = new Date();
    troisMois.setMonth(troisMois.getMonth() - 3);

    const [alaUne, articles, categories, bannieres] = await Promise.all([
      // 1. Article à la une
      Article.findOne({})
        .select('guid titre resume image lienSource source categorie datePublication legendeImage auteur')
        .sort({ datePublication: -1, dateRecuperation: -1 })
        .lean(),

      // 2. Les 20 premiers articles récents
      Article.find({ datePublication: { $gte: troisMois } })
        .select('guid titre resume image lienSource source categorie datePublication legendeImage auteur')
        .sort({ datePublication: -1 })
        .limit(20)
        .lean(),

      // 3. Catégories (avec cache mémoire 10 min)
      (async () => {
        const curTime = Date.now();
        if (categoriesCache && (curTime - categoriesCacheTime < CATEGORIES_CACHE_TTL)) {
          return categoriesCache;
        }
        const cats = await Article.distinct('categorie');
        categoriesCache = cats.filter(Boolean).sort();
        categoriesCacheTime = curTime;
        return categoriesCache;
      })(),

      // 4. Bannières actives sans le Base64 lourd
      Banniere.find({
        actif: true,
        dateDebut: { $lte: now },
        dateFin: { $gte: now },
      })
        .select('-donneesImage')
        .sort({ ordre: 1 })
        .limit(10)
        .lean(),
    ]);

    res.json({
      alaUne: alaUne || null,
      articles: articles || [],
      categories: categories || [],
      bannieres: bannieres || [],
    });
  } catch (err) {
    next(err);
  }
};

// Retourne le dernier article du flux RSS pour la section "À la une" de l'accueil
exports.articleUne = async (req, res, next) => {
  try {
    // Le dernier article publié dans le flux RSS :
    // tri par date de publication décroissante, puis par date de récupération
    // (tie-breaker pour les articles publiés au même instant).
    const article = await Article.findOne({})
      .select('guid titre resume image lienSource source categorie datePublication legendeImage auteur')
      .sort({ datePublication: -1, dateRecuperation: -1 })
      .lean();
    if (!article) return res.status(404).json({ message: 'Aucun article' });
    res.json(article);
  } catch (err) { next(err); }
};

exports.listerArticles = async (req, res, next) => {
  try {
    const { categorie, page = 1, limite = 10, ancien } = req.query;
    const filtre = {};

    // Filtre de catégorie insensible à la casse (supporte TOGO, Togo, AFRIQUE, MONDE...)
    if (categorie && categorie.trim().toUpperCase() !== 'HOME' && categorie.trim().toUpperCase() !== 'TOUT') {
      filtre.categorie = { $regex: new RegExp(`^${categorie.trim()}$`, 'i') };
    }
    
    // Par défaut, ne pas afficher les articles de +3 mois (conformité Google Play)
    if (ancien !== 'true') {
      const troisMois = new Date();
      troisMois.setMonth(troisMois.getMonth() - 3);
      filtre.datePublication = { $gte: troisMois };
    }

    const articles = await Article.find(filtre)
      .select('guid titre resume image lienSource source categorie datePublication legendeImage auteur')
      .sort({ datePublication: -1 })
      .skip((page - 1) * limite)
      .limit(Number(limite))
      .lean();
    res.json(articles);
  } catch (err) { next(err); }
};

exports.detailArticle = async (req, res, next) => {
  try {
    const article = await Article.findById(req.params.id).lean();
    if (!article) return res.status(404).json({ message: 'Article introuvable' });

    // Corrige les images du corps des articles déjà en base
    // ({{BASE_URL}}, chemins relatifs, domaine .com → .net, /ck/ → /storage/ck/)
    if (article.contenu) {
      const { normaliserImagesContenu } = require('../services/rss.service');
      article.contenu = normaliserImagesContenu(article.contenu);
    }

    // Réponse au client mobile
    res.json(article);

    // Si le contenu est incomplet, tenter le scrape en arrière-plan sans faire attendre l'utilisateur
    const contenuTexte = (article.contenu || '').replace(/<[^>]*>/g, '').trim();
    if (contenuTexte.length < 100 && article.lienSource) {
      setImmediate(async () => {
        try {
          const { scrapeContenuInertia } = require('../services/rss.service');
          const scrapeRes = await scrapeContenuInertia(article.lienSource);
          const nouveauContenu = scrapeRes ? (scrapeRes.contenu || '') : '';
          if (nouveauContenu && nouveauContenu.replace(/<[^>]*>/g, '').trim().length > contenuTexte.length) {
            const updates = { contenu: nouveauContenu };
            if (scrapeRes.legende) {
              updates.legendeImage = scrapeRes.legende;
            }
            await Article.updateOne({ _id: article._id }, { $set: updates });
          }
        } catch (_) { /* scrape silencieux en tâche de fond */ }
      });
    }
  } catch (err) { next(err); }
};

exports.rechercherArticles = async (req, res, next) => {
  try {
    const { motCle, categorie, dateDebut, dateFin, ancien } = req.query;
    const filtre = {};
    if (motCle) {
      // Échapper les caractères spéciaux regex pour éviter l'injection
      const motCleEchappe = motCle.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      filtre.$or = [
        { titre: { $regex: motCleEchappe, $options: 'i' } },
        { contenu: { $regex: motCleEchappe, $options: 'i' } },
      ];
    }
    if (categorie) filtre.categorie = categorie;
    if (dateDebut || dateFin) {
      filtre.datePublication = {};
      if (dateDebut) filtre.datePublication.$gte = new Date(dateDebut);
      if (dateFin) filtre.datePublication.$lte = new Date(dateFin);
    } else if (ancien !== 'true') {
      // Par défaut, articles de -3 mois uniquement
      const troisMois = new Date();
      troisMois.setMonth(troisMois.getMonth() - 3);
      filtre.datePublication = { ...filtre.datePublication, $gte: troisMois };
    }
    const articles = await Article.find(filtre)
      .select('guid titre resume image lienSource source categorie datePublication legendeImage auteur')
      .sort({ datePublication: -1 })
      .lean();
    res.json(articles);
  } catch (err) { next(err); }
};

exports.listerCategories = async (req, res, next) => {
  try {
    const now = Date.now();
    if (categoriesCache && (now - categoriesCacheTime < CATEGORIES_CACHE_TTL)) {
      return res.json(categoriesCache);
    }
    const categories = await Article.distinct('categorie');
    categoriesCache = categories.filter(Boolean).sort();
    categoriesCacheTime = now;
    res.json(categoriesCache);
  } catch (err) { next(err); }
};
