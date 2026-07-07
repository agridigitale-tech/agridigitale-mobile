//permet de vérifier si l'utilisateur est un administrateur

exports.estAdmin = (req, res, next) => {
  if (req.role === 'administrateur') {
    next();
  } else {
    return res.status(403).json({ message: 'Accès refusé : droits d\'administrateur requis' });
  }
};
