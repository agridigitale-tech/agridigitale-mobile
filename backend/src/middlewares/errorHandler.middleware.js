//permet de gérer les erreurs dans l'application Express

module.exports = (err, req, res, next) => {
  console.error(err.stack);
  const statut = err.statusCode || err.status || 500;
  // Ne pas exposer les détails internes en production
  const message = statut < 500
    ? (err.message || 'Erreur de requête')
    : 'Erreur serveur interne';
  res.status(statut).json({ message });
};