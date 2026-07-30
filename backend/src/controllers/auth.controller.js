// Permet de gérer l'authentification des utilisateurs et la génération de jetons JWT
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const Utilisateur = require('../models/Utilisateur');

const genererToken = (id, role) =>
  jwt.sign({ id, role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN });

// Transporteur email (Gmail SMTP)
const _transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

async function envoyerEmailReset(email, token) {
  const mailOptions = {
    from: process.env.SMTP_FROM || process.env.SMTP_USER,
    to: email,
    subject: 'AgriDigitale — Réinitialisation de votre mot de passe',
    html: `
      <div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;padding:24px;border:1px solid #e0e0e0;border-radius:8px">
        <h2 style="color:#2e7d32">🌱 AgriDigitale</h2>
        <p>Vous avez demandé la réinitialisation de votre mot de passe.</p>
        <p>Copiez ce token dans l'application :</p>
        <div style="background:#f5f5f5;padding:16px;border-radius:6px;font-size:14px;word-break:break-all;font-family:monospace">
          ${token}
        </div>
        <p style="color:#888;font-size:12px;margin-top:16px">Ce token expire dans <strong>15 minutes</strong>.<br>Si vous n'avez pas fait cette demande, ignorez cet email.</p>
      </div>
    `,
  };
  await _transporter.sendMail(mailOptions);
}

const genererToken = (id, role) =>
  jwt.sign({ id, role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN });

// 1. INSCRIPTION
exports.inscrire = async (req, res, next) => {
  try {
    const { nom, email, motDePasse, pays, continent } = req.body;
    if (!nom || !email || !motDePasse) {
      return res.status(400).json({ message: 'Tous les champs sont obligatoires' });
    }
    if (motDePasse.length < 6) {
      return res.status(400).json({ message: 'Le mot de passe doit contenir au moins 6 caractères' });
    }

    const existe = await Utilisateur.findOne({ email });
    if (existe) return res.status(409).json({ message: 'Cet e-mail est déjà utilisé' });

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(motDePasse, salt);

    const utilisateur = new Utilisateur({
      nom,
      email,
      motDePasse: hashedPassword,
      pays: pays || '',
      continent: continent || '',
    });
    await utilisateur.save();

    const token = genererToken(utilisateur._id, utilisateur.role);
    res.status(201).json({
      token,
      utilisateur: { id: utilisateur._id, nom: utilisateur.nom, email: utilisateur.email, role: utilisateur.role }
    });
  } catch (err) {
    console.error('Registration error:', err);
    res.status(500).json({ message: 'Erreur lors de l\'inscription' });
  }
};

// 2. CONNEXION (Ajouté pour corriger le bug des routes)
exports.connecter = async (req, res, next) => {
  try {
    const { email, motDePasse } = req.body;
    if (!email || !motDePasse) {
      return res.status(400).json({ message: 'L\'email et le mot de passe sont obligatoires' });
    }

    const utilisateur = await Utilisateur.findOne({ email }).select('+motDePasse');
    if (!utilisateur) return res.status(401).json({ message: 'E-mail ou mot de passe incorrect' });

    const valide = await bcrypt.compare(motDePasse, utilisateur.motDePasse);
    if (!valide) return res.status(401).json({ message: 'E-mail ou mot de passe incorrect' });

    const token = genererToken(utilisateur._id, utilisateur.role);
    res.json({
      token,
      utilisateur: { id: utilisateur._id, nom: utilisateur.nom, email: utilisateur.email, role: utilisateur.role }
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ message: 'Erreur lors de la connexion' });
  }
};

// 3. PROFIL (Ajouté pour corriger le bug des routes)
exports.profil = async (req, res, next) => {
  try {
    const utilisateur = await Utilisateur.findById(req.utilisateurId).select('-motDePasse');
    res.json(utilisateur);
  } catch (err) {
    console.error('Profile error:', err);
    res.status(500).json({ message: 'Erreur lors de la récupération du profil' });
  }
};

// 4. MODIFIER LE PROFIL
exports.modifierProfil = async (req, res, next) => {
  try {
    const { nom, photo, preferencesRubriques, theme, langue } = req.body;
    const champsAutorises = {};
    if (nom !== undefined) champsAutorises.nom = nom;
    if (photo !== undefined) champsAutorises.photo = photo;
    if (preferencesRubriques !== undefined) champsAutorises.preferencesRubriques = preferencesRubriques;
    if (theme !== undefined) champsAutorises.theme = theme;
    if (langue !== undefined) champsAutorises.langue = langue;

    const utilisateur = await Utilisateur.findByIdAndUpdate(
      req.utilisateurId,
      champsAutorises,
      { new: true, runValidators: true }
    ).select('-motDePasse');
    res.json(utilisateur);
  } catch (err) {
    console.error('Update profile error:', err);
    res.status(500).json({ message: 'Erreur lors de la mise à jour du profil' });
  }
};

// 5. ENREGISTRER TOKEN FCM
exports.enregistrerTokenFCM = async (req, res, next) => {
  try {
    await Utilisateur.findByIdAndUpdate(req.utilisateurId, { tokenFCM: req.body.token });
    res.status(204).send();
  } catch (err) {
    console.error('FCM token error:', err);
    res.status(500).json({ message: 'Erreur lors de l\'enregistrement du token FCM' });
  }
};

// 6. MOT DE PASSE OUBLIÉ
exports.motDePasseOublie = async (req, res, next) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: 'E-mail obligatoire' });
    const utilisateur = await Utilisateur.findOne({ email });
    // Toujours répondre 200 pour ne pas révéler si l'email existe
    if (!utilisateur) return res.json({ message: 'Si cet e-mail existe, un lien a été envoyé.' });

    const token = jwt.sign({ id: utilisateur._id }, process.env.JWT_SECRET, { expiresIn: '15m' });

    // Envoi email réel via nodemailer
    let emailEnvoye = false;
    try {
      await envoyerEmailReset(email, token);
      emailEnvoye = true;
    } catch (emailErr) {
      console.error('[RESET EMAIL] Erreur envoi email:', emailErr.message);
      // Fallback : log du token en console pour développement
      console.log(`[RESET PASSWORD FALLBACK] Token pour ${email}: ${token}`);
    }

    res.json({
      message: emailEnvoye
        ? 'Un email avec le token a été envoyé à votre adresse.'
        : 'Email non configuré — utilisez ce token directement.',
      // Token renvoyé dans la réponse si email non configuré (développement)
      ...(emailEnvoye ? {} : { token }),
    });
  } catch (err) {
    console.error('Forgot password error:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// 7. RÉINITIALISATION DU MOT DE PASSE
exports.reinitialiserMotDePasse = async (req, res, next) => {
  try {
    const { token, nouveauMotDePasse } = req.body;
    if (!token || !nouveauMotDePasse) {
      return res.status(400).json({ message: 'Token et nouveau mot de passe obligatoires' });
    }
    if (nouveauMotDePasse.length < 6) {
      return res.status(400).json({ message: 'Le mot de passe doit contenir au moins 6 caractères' });
    }
    let payload;
    try {
      payload = jwt.verify(token, process.env.JWT_SECRET);
    } catch {
      return res.status(400).json({ message: 'Token invalide ou expiré' });
    }
    const salt = await bcrypt.genSalt(10);
    const hash = await bcrypt.hash(nouveauMotDePasse, salt);
    await Utilisateur.findByIdAndUpdate(payload.id, { motDePasse: hash });
    res.json({ message: 'Mot de passe réinitialisé avec succès' });
  } catch (err) {
    console.error('Reset password error:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};
