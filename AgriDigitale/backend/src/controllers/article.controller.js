const Article = require('../models/Article');

// Retourne l'article le plus lu pour la section "À la une" de l'accueil
exports.articleUne = async (req, res, next) => {
  try {
    // Uniquement les articles des 3 derniers mois pour la section "à la une"
    const troisMois = new Date();
    troisMois.setMonth(troisMois.getMonth() - 3);
    const article = await Article.findOne({ datePublication: { $gte: troisMois } })
      .select('guid titre resume image lienSource source categorie datePublication vues')
      .sort({ vues: -1 });
    if (!article) return res.status(404).json({ message: 'Aucun article' });
    res.json(article);
  } catch (err) { next(err); }
};

exports.listerArticles = async (req, res, next) => {
  try {
    const { categorie, page = 1, limite = 10, ancien } = req.query;
    const filtre = categorie ? { categorie } : {};
    
    // Par défaut, ne pas afficher les articles de +3 mois (conformité Google Play)
    if (ancien !== 'true') {
      const troisMois = new Date();
      troisMois.setMonth(troisMois.getMonth() - 3);
      filtre.datePublication = { $gte: troisMois };
    }

    const articles = await Article.find(filtre)
      .select('guid titre resume image lienSource source categorie datePublication vues')
      .sort({ datePublication: -1 })
      .skip((page - 1) * limite)
      .limit(Number(limite));
    res.json(articles);
  } catch (err) { next(err); }
};

exports.detailArticle = async (req, res, next) => {
  try {
    const article = await Article.findByIdAndUpdate(
      req.params.id,
      { $inc: { vues: 1 } },
      { new: true }
    );
    if (!article) return res.status(404).json({ message: 'Article introuvable' });

    // Si le contenu est vide ou trop court, tenter un scrape à la volée
    const contenuTexte = (article.contenu || '').replace(/<[^>]*>/g, '').trim();
    if (contenuTexte.length < 100 && article.lienSource) {
      try {
        const { scrapeContenuInertia } = require('../services/rss.service');
        const nouveauContenu = await scrapeContenuInertia(article.lienSource);
        if (nouveauContenu && nouveauContenu.replace(/<[^>]*>/g, '').trim().length > contenuTexte.length) {
          article.contenu = nouveauContenu;
          // Sauvegarder en base pour les prochaines fois
          await Article.updateOne({ _id: article._id }, { $set: { contenu: nouveauContenu } });
        }
      } catch (_) { /* scrape optionnel, on continue sans */ }
    }

    res.json(article);
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
      .select('guid titre resume image lienSource source categorie datePublication vues')
      .sort({ datePublication: -1 });
    res.json(articles);
  } catch (err) { next(err); }
};

exports.listerCategories = async (req, res, next) => {
  try {
    const categories = await Article.distinct('categorie');
    res.json(categories.filter(Boolean).sort());
  } catch (err) { next(err); }
};
