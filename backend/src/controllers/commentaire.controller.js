const Commentaire = require('../models/Commentaire');
const Utilisateur = require('../models/Utilisateur');

exports.listerCommentaires = async (req, res, next) => {
  try {
    const commentaires = await Commentaire.find({ article: req.params.articleId })
      .sort({ createdAt: -1 })
      .limit(50)
      .select('nomAuteur contenu createdAt');
    res.json(commentaires);
  } catch (err) { next(err); }
};

exports.ajouterCommentaire = async (req, res, next) => {
  try {
    const { contenu } = req.body;
    if (!contenu || contenu.trim().length < 2) {
      return res.status(400).json({ message: 'Le commentaire est trop court' });
    }
    const utilisateur = await Utilisateur.findById(req.utilisateurId).select('nom');
    if (!utilisateur) return res.status(404).json({ message: 'Utilisateur introuvable' });

    const commentaire = await Commentaire.create({
      article: req.params.articleId,
      auteur: req.utilisateurId,
      nomAuteur: utilisateur.nom,
      contenu: contenu.trim(),
    });
    res.status(201).json(commentaire);
  } catch (err) { next(err); }
};

exports.supprimerCommentaire = async (req, res, next) => {
  try {
    const c = await Commentaire.findById(req.params.id);
    if (!c) return res.status(404).json({ message: 'Commentaire introuvable' });
    if (c.auteur.toString() !== req.utilisateurId) {
      return res.status(403).json({ message: 'Non autorisé' });
    }
    await c.deleteOne();
    res.status(204).send();
  } catch (err) { next(err); }
};
