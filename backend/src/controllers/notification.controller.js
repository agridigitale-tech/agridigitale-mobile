// Permet de gérer l'envoi de notifications manuelles aux utilisateurs

exports.envoyerManuelle = async (req, res, next) => {
  try {
    const { titre, message, rubrique } = req.body;

    if (!titre || !message) {
      return res.status(400).json({ message: 'Le titre et le message sont obligatoires' });
    }

    // Logique d'envoi de notification (à implémenter selon votre système de notification)
    console.log(`Notification envoyée: ${titre} - ${message} (Rubrique: ${rubrique || 'générale'})`);

    res.json({
      success: true,
      message: 'Notification envoyée avec succès',
      notification: { titre, message, rubrique }
    });
  } catch (err) {
    next(err);
  }
};