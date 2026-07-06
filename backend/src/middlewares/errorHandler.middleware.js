//permet de gérer les erreurs dans l'application Express

module.exports = (err, req, res, next) => {
  console.error(err.stack);
  const statut = err.statusCode || 500;
  res.status(statut).json({ message: err.message || 'Erreur serveur interne' });
};