const multer = require('multer');
const path = require('path');

// 1. Définir où et comment enregistrer le fichier sur le disque local
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'public/uploads/'); // Les photos iront dans ce dossier
  },
  filename: (req, file, cb) => {
    // Génère un nom unique pour éviter les doublons (ex: 17182938472-photo.jpg)
    const suffixeUnique = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, suffixeUnique + path.extname(file.originalname));
  }
});

// 2. Filtrer les fichiers pour n'accepter que les images
const filtreFichier = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Seuls les fichiers d\'images sont autorisés !'), false);
  }
};

// 3. Exporter le middleware avec une limite de taille de 5 Mo
const upload = multer({
  storage: storage,
  fileFilter: filtreFichier,
  limits: { fileSize: 5 * 1024 * 1024 } 
});

module.exports = upload;
