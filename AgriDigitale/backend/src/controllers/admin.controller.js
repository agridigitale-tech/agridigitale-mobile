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
      Utilisateur.aggregate([
        { $addFields: { paysNormalise: { $toLower: { $ifNull: ['$pays', ''] } } } },
        { $addFields: { paysNormalise: { $cond: [{ $eq: ['$paysNormalise', ''] }, 'Non renseigné', '$paysNormalise'] } } },
        { $group: { _id: '$paysNormalise', total: { $sum: 1 } } },
        { $sort: { total: -1 } },
      ]),
      Utilisateur.aggregate([
        { $addFields: { continentNormalise: { $toLower: { $ifNull: ['$continent', ''] } } } },
        { $addFields: { continentNormalise: { $cond: [{ $eq: ['$continentNormalise', ''] }, 'Non renseigné', '$continentNormalise'] } } },
        { $group: { _id: '$continentNormalise', total: { $sum: 1 } } },
        { $sort: { total: -1 } },
      ]),
    ]);
    const articlesPlusLus = await Article.find().sort({ datePublication: -1 }).limit(5);
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

// Promouvoir un utilisateur en administrateur
exports.promouvoirAdmin = async (req, res, next) => {
  try {
    const utilisateur = await Utilisateur.findById(req.params.id);
    if (!utilisateur) return res.status(404).json({ message: 'Utilisateur introuvable' });
    if (utilisateur.role === 'administrateur') {
      return res.status(400).json({ message: 'Cet utilisateur est déjà administrateur' });
    }
    utilisateur.role = 'administrateur';
    await utilisateur.save();
    res.json({ success: true, message: `${utilisateur.nom} est désormais administrateur` });
  } catch (err) { next(err); }
};

// Rétrograder un administrateur en utilisateur simple
exports.retrograderAdmin = async (req, res, next) => {
  try {
    if (req.params.id === req.utilisateurId) {
      return res.status(400).json({ message: 'Vous ne pouvez pas vous rétrograder vous-même' });
    }
    const utilisateur = await Utilisateur.findById(req.params.id);
    if (!utilisateur) return res.status(404).json({ message: 'Utilisateur introuvable' });
    if (utilisateur.role !== 'administrateur') {
      return res.status(400).json({ message: 'Cet utilisateur n\'est pas administrateur' });
    }
    utilisateur.role = 'utilisateur';
    await utilisateur.save();
    res.json({ success: true, message: `${utilisateur.nom} a été rétrogradé en utilisateur` });
  } catch (err) { next(err); }
};