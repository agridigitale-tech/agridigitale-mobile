//permet de gérer les demandes des utilisateurs (contact, support, etc.)

const Demande = require('../models/Demande');

exports.envoyerDemande = async (req, res, next) => {
  try {
    const { nom, message } = req.body;
    if (!nom || !message) {
      return res.status(400).json({ message: 'Le nom et le message sont obligatoires' });
    }
    const demande = await Demande.create(req.body);
    res.status(201).json({ message: 'Demande envoyée avec succès', demande });
  } catch (err) { next(err); }
};

// réservé à l'admin
exports.listerDemandes = async (req, res, next) => {
  try {
    const demandes = await Demande.find().sort({ dateEnvoi: -1 });
    res.json(demandes);
  } catch (err) { next(err); }
};

exports.traiterDemande = async (req, res, next) => {
  try {
    const demande = await Demande.findByIdAndUpdate(req.params.id, { statut: 'Traitée' }, { new: true });
    res.json(demande);
  } catch (err) { next(err); }
};
