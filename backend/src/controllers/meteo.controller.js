// permet de gérer les requêtes liées aux données météo, telles que la consultation des données météo les plus récentes et la publication manuelle de données météo en cas d'indisponibilité de l'API externe

const Meteo = require('../models/Meteo');

exports.consulterMeteo = async (req, res, next) => {
  try {
    const meteo = await Meteo.findOne().sort({ dateMiseAJour: -1 });
    if (!meteo) return res.status(404).json({ message: 'Aucune donnée météo disponible' });
    res.json(meteo);
  } catch (err) { next(err); }
};

// Cas de secours si l'admin veut publier manuellement avec une image locale chargée depuis son disque
exports.publierMeteoManuelle = async (req, res, next) => {
  try {
    const { zone, temperature, description } = req.body;

    // 1. Vérification de sécurité : s'assurer qu'un fichier a bien été joint à la requête
    if (!req.file) {
      return res.status(400).json({ message: 'Veuillez fournir un fichier image pour illustrer la météo' });
    }

    // 2. Construction dynamique de l'URL internet de l'image stockée localement
    // Produit un lien du type : http://localhost:5000/uploads/nom-unique-du-fichier.png
    const urlImageComplete = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;

    // 3. Insertion propre dans votre collection MongoDB Cloud
    const meteo = await Meteo.create({ 
      zone, 
      temperature, 
      description, 
      icone: urlImageComplete, // On injecte l'URL de l'image physique dans le champ icone attendu par votre modèle
      source: 'manuel' 
    });

    res.status(201).json(meteo);
  } catch (err) { next(err); }
};
