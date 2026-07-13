// permet de gérer les demandes des utilisateurs dans l'application mobile AgriDigitale  
const Demande = require('../models/Demande');

exports.envoyerDemande = async (req, res) => {
  try {
    const { nomComplet, profession, email, telephone, message } = req.body;
    
    if (!nomComplet || !profession || !email || !telephone || !message) {
      return res.status(400).json({ message: 'Tous les champs (nomComplet, profession, email, telephone, message) sont obligatoires' });
    }

    const regexTelephone = /^\+?[0-9]{8,15}$/;
    if (!regexTelephone.test(telephone)) {
      return res.status(400).json({ message: 'Le format du numéro de téléphone est invalide. Exemple attendu: +22890000000' });
    }

    const nouvelleDemande = await Demande.create({
      nomComplet,
      profession,
      email,
      telephone,
      message,
      utilisateur: req.utilisateurId 
    });
    
    return res.status(201).json({ 
      message: 'Votre demande a été envoyée avec succès', 
      demande: nouvelleDemande 
    });
  } catch (err) { 
    return res.status(500).json({ message: 'Erreur lors de l\'envoi', error: err.message }); 
  }
};

exports.listerDemandes = async (req, res) => {
  try {
    const demandes = await Demande.find().sort({ createdAt: -1 });
    return res.json(demandes);
  } catch (err) { 
    return res.status(500).json({ error: err.message }); 
  }
};

exports.traiterDemande = async (req, res) => {
  try {
    const demandeModifiee = await Demande.findByIdAndUpdate(
      req.params.id, 
      { statut: 'TRAITE' }, 
      { new: true, runValidators: true }
    );

    if (!demandeModifiee) {
      return res.status(404).json({ message: 'Demande introuvable' });
    }

    return res.json({ message: 'Demande marquée comme traitée', demande: demandeModifiee });
  } catch (err) { 
    return res.status(500).json({ error: err.message }); 
  }
};
