//permet de lister les articles, de récupérer le détail d'un article et de rechercher des articles par mot-clé, catégorie ou date de publication

const Article = require('../models/Article');

exports.listerArticles = async (req, res, next) => {
  try {
    const { categorie, page = 1, limite = 10 } = req.query;
    const filtre = categorie ? { categorie } : {};
    const articles = await Article.find(filtre)
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
    res.json(article);
  } catch (err) { next(err); }
};

exports.rechercherArticles = async (req, res, next) => {
  try {
    const { motCle, categorie, dateDebut, dateFin } = req.query;
    const filtre = {};
    if (motCle) {
      filtre.$or = [
        { titre: { $regex: motCle, $options: 'i' } },
        { contenu: { $regex: motCle, $options: 'i' } },
      ];
    }
    if (categorie) filtre.categorie = categorie;
    if (dateDebut || dateFin) {
      filtre.datePublication = {};
      if (dateDebut) filtre.datePublication.$gte = new Date(dateDebut);
      if (dateFin) filtre.datePublication.$lte = new Date(dateFin);
    }
    const articles = await Article.find(filtre).sort({ datePublication: -1 });
    res.json(articles);
  } catch (err) { next(err); }
};