//permet de vérifier si l'utilisateur est authentifié

const jwt = require('jsonwebtoken');

exports.proteger = (req, res, next) => {
    const authHeader = req.headers.authorization;
    if(!authHeader?.startsWith('Bearer ')) {
        return res.status(401).json({ message: 'Accès refusé : jeton manquant' });
    }
    try {
    const decoded = jwt.verify(authHeader.split(' ')[1], process.env.JWT_SECRET);
    req.utilisateurId = decoded.id;
    req.role = decoded.role;
    next();
  } catch {
    return res.status(401).json({ message: 'Jeton invalide ou expiré' });
  }
};