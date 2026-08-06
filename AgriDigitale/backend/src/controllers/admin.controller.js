const Article = require('../models/Article');
const Utilisateur = require('../models/Utilisateur');
const Demande = require('../models/Demande');

exports.statistiques = async (req, res, next) => {
  try {
    const [totalArticles, totalUtilisateurs, demandesEnAttente, articlesParCategorie, parPays, parContinent] = await Promise.all([
      Article.countDocuments(),
      Utilisateur.countDocuments(),
      Demande.countDocuments({ statut: 'EN_ATTENTE' }),
      Article.aggregate([{ $group: { _id: '$categorie', total: { $sum: 1 } } }]),
      Utilisateur.aggregate([{ $group: { _id: '$pays', total: { $sum: 1 } } }, { $sort: { total: -1 } }]),
      Utilisateur.aggregate([{ $group: { _id: '$continent', total: { $sum: 1 } } }, { $sort: { total: -1 } }]),
    ]);
    const articlesPlusLus = await Article.find().sort({ vues: -1 }).limit(5);
    res.json({ totalArticles, totalUtilisateurs, demandesEnAttente, articlesParCategorie, articlesPlusLus, parPays, parContinent });
  } catch (err) { next(err); }
};

exports.listerUtilisateurs = async (req, res, next) => {
  try {
    const utilisateurs = await Utilisateur.find().select('-tokenFCM -motDePasse');
    res.json(utilisateurs);
  } catch (err) { next(err); }
};

exports.desactiverUtilisateur = async (req, res, next) => {
  try {
    const utilisateur = await Utilisateur.findByIdAndUpdate(
      req.params.id,
      { actif: false },
      { new: true }
    );
    if (!utilisateur) return res.status(404).json({ message: 'Utilisateur introuvable' });
    // Retourner 200 + JSON au lieu de 204 pour éviter les erreurs côté client
    res.json({ success: true, message: 'Compte désactivé avec succès' });
  } catch (err) { next(err); }
};