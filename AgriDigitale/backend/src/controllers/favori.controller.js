// permet de gérer les favoris des utilisateurs, y compris l'ajout, la suppression et la liste des articles favoris

const Favori = require('../models/Favori');

exports.ajouterFavori = async (req, res, next) => {
  try {
    const { articleId, libelle } = req.body;

    if (!articleId) {
      return res.status(400).json({ message: 'articleId est obligatoire' });
    }

    const favori = await Favori.create({ 
      utilisateur: req.utilisateurId, 
      article: articleId,
      ...(libelle && { libelle })
    });

    return res.status(201).json(favori);
  } catch (err) {
    if (err.code === 11000) return res.status(409).json({ message: 'Déjà en favoris' });
    next(err);
  }
};

exports.retirerFavori = async (req, res, next) => {
  try {
    await Favori.deleteOne({ utilisateur: req.utilisateurId, article: req.params.articleId });
    res.status(204).send();
  } catch (err) { next(err); }
};

exports.listerFavoris = async (req, res, next) => {
  try {
    const favoris = await Favori.find({ utilisateur: req.utilisateurId })
      .populate('article')
      .sort({ createdAt: -1 });
    res.json(favoris.map(f => f.article));
  } catch (err) { next(err); }
};
