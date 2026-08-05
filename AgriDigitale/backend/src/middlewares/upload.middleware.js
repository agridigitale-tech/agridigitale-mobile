const multer = require('multer');
const path = require('path');

const EXTENSIONS_AUTORISEES = new Set(['.jpg', '.jpeg', '.png', '.gif', '.webp']);

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'public/uploads/');
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const suffixeUnique = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, suffixeUnique + ext);
  }
});

const filtreFichier = (req, file, cb) => {
  const ext = path.extname(file.originalname).toLowerCase();
  if (file.mimetype.startsWith('image/') && EXTENSIONS_AUTORISEES.has(ext)) {
    cb(null, true);
  } else {
    cb(new Error('Seuls les fichiers images (jpg, jpeg, png, gif, webp) sont autorisés !'), false);
  }
};

const upload = multer({
  storage,
  fileFilter: filtreFichier,
  limits: { fileSize: 5 * 1024 * 1024 },
});

module.exports = upload;