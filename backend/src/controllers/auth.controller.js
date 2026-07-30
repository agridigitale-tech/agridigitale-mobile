// Gère l'authentification des utilisateurs et la génération de jetons JWT
const bcrypt = require('bcryptjs');
const jwt    = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const Utilisateur = require('../models/Utilisateur');

// ── Token JWT session ────────────────────────────────────────────────────────
const genererToken = (id, role) =>
  jwt.sign({ id, role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN });

// ── Transporteur SMTP Gmail ──────────────────────────────────────────────────
const _transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.SMTP_PORT || '465'),
  secure: true, // SSL sur port 465
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

async function envoyerEmailReset(destinataire, token) {
  await _transporter.sendMail({
    from: `AgriDigitale <${process.env.SMTP_USER}>`,
    to: destinataire,
    subject: '🌱 AgriDigitale — Réinitialisation de votre mot de passe',
    html: `
      <div style="font-family:Arial,sans-serif;max-width:500px;margin:auto;
                  padding:28px;border:1px solid #e0e0e0;border-radius:10px">
        <h2 style="color:#2e7d32;margin-top:0">🌱 AgriDigitale</h2>
        <p>Vous avez demandé la réinitialisation de votre mot de passe.</p>
        <p><strong>Copiez ce token dans l'application :</strong></p>
        <div style="background:#f1f8e9;padding:16px;border-radius:6px;
                    font-size:13px;word-break:break-all;font-family:monospace;
                    border:1px solid #c5e1a5;color:#1b5e20">
          ${token}
        </div>
        <p style="color:#888;font-size:12px;margin-top:20px">
          ⏱ Ce token expire dans <strong>15 minutes</strong>.<br>
          Si vous n'avez pas fait cette demande, ignorez cet email.
        </p>
      </div>
    `,
  });
}

// ── 1. INSCRIPTION ───────────────────────────────────────────────────────────
exports.inscrire = async (req, res, next) => {
  try {
    const { nom, email, motDePasse, pays, continent } = req.body;
    if (!nom || !email || !motDePasse)
      return res.status(400).json({ message: 'Tous les champs sont obligatoires' });
    if (motDePasse.length < 6)
      return res.status(400).json({ message: 'Le mot de passe doit contenir au moins 6 caractères' });

    const existe = await Utilisateur.findOne({ email });
    if (existe) return res.status(409).json({ message: 'Cet e-mail est déjà utilisé' });

    const hash = await bcrypt.hash(motDePasse, 10);
    const utilisateur = await new Utilisateur({
      nom, email, motDePasse: hash,
      pays: pays || '', continent: continent || '',
    }).save();

    const token = genererToken(utilisateur._id, utilisateur.role);
    res.status(201).json({
      token,
      utilisateur: { id: utilisateur._id, nom: utilisateur.nom, email: utilisateur.email, role: utilisateur.role },
    });
  } catch (err) {
    console.error('Inscription error:', err);
    res.status(500).json({ message: "Erreur lors de l'inscription" });
  }
};

// ── 2. CONNEXION ─────────────────────────────────────────────────────────────
exports.connecter = async (req, res, next) => {
  try {
    const { email, motDePasse } = req.body;
    if (!email || !motDePasse)
      return res.status(400).json({ message: "L'email et le mot de passe sont obligatoires" });

    const utilisateur = await Utilisateur.findOne({ email }).select('+motDePasse');
    if (!utilisateur) return res.status(401).json({ message: 'E-mail ou mot de passe incorrect' });

    const valide = await bcrypt.compare(motDePasse, utilisateur.motDePasse);
    if (!valide) return res.status(401).json({ message: 'E-mail ou mot de passe incorrect' });

    const token = genererToken(utilisateur._id, utilisateur.role);
    res.json({
      token,
      utilisateur: { id: utilisateur._id, nom: utilisateur.nom, email: utilisateur.email, role: utilisateur.role },
    });
  } catch (err) {
    console.error('Connexion error:', err);
    res.status(500).json({ message: 'Erreur lors de la connexion' });
  }
};

// ── 3. PROFIL ────────────────────────────────────────────────────────────────
exports.profil = async (req, res, next) => {
  try {
    const utilisateur = await Utilisateur.findById(req.utilisateurId).select('-motDePasse');
    res.json(utilisateur);
  } catch (err) {
    res.status(500).json({ message: 'Erreur lors de la récupération du profil' });
  }
};

// ── 4. MODIFIER LE PROFIL ────────────────────────────────────────────────────
exports.modifierProfil = async (req, res, next) => {
  try {
    const { nom, photo, preferencesRubriques, theme, langue } = req.body;
    const champs = {};
    if (nom !== undefined) champs.nom = nom;
    if (photo !== undefined) champs.photo = photo;
    if (preferencesRubriques !== undefined) champs.preferencesRubriques = preferencesRubriques;
    if (theme !== undefined) champs.theme = theme;
    if (langue !== undefined) champs.langue = langue;

    const utilisateur = await Utilisateur.findByIdAndUpdate(
      req.utilisateurId, champs, { new: true, runValidators: true }
    ).select('-motDePasse');
    res.json(utilisateur);
  } catch (err) {
    res.status(500).json({ message: 'Erreur lors de la mise à jour du profil' });
  }
};

// ── 5. TOKEN FCM ─────────────────────────────────────────────────────────────
exports.enregistrerTokenFCM = async (req, res, next) => {
  try {
    await Utilisateur.findByIdAndUpdate(req.utilisateurId, { tokenFCM: req.body.token });
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ message: "Erreur lors de l'enregistrement du token FCM" });
  }
};

// ── 6. MOT DE PASSE OUBLIÉ ───────────────────────────────────────────────────
exports.motDePasseOublie = async (req, res, next) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: 'E-mail obligatoire' });

    const utilisateur = await Utilisateur.findOne({ email });
    // Si email inconnu : générer quand même un faux token pour ne pas révéler l'existence
    // mais retourner success:true sans token réel
    if (!utilisateur) {
      return res.status(200).json({
        success: true,
        token: '',
        message: 'Si cet e-mail existe, un token a été envoyé.',
      });
    }

    // Générer token reset 15 min
    const resetToken = jwt.sign({ id: utilisateur._id }, process.env.JWT_SECRET, { expiresIn: '15m' });

    // Envoyer l'email
    let emailEnvoye = false;
    try {
      await envoyerEmailReset(email, resetToken);
      emailEnvoye = true;
      console.log(`[RESET] Email envoyé à ${email}`);
    } catch (emailErr) {
      console.error('[RESET] Échec envoi email:', emailErr.message);
    }

    // Toujours renvoyer le token dans la réponse (double sécurité garantie)
    return res.status(200).json({
      success: true,
      token: resetToken,
      message: emailEnvoye
        ? `Token envoyé par email à ${email} et disponible dans cette réponse.`
        : 'Email non envoyé (SMTP non configuré) — utilisez le token de cette réponse.',
    });
  } catch (err) {
    console.error('Forgot password error:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ── 7. RÉINITIALISATION DU MOT DE PASSE ─────────────────────────────────────
exports.reinitialiserMotDePasse = async (req, res, next) => {
  try {
    const { token, nouveauMotDePasse } = req.body;
    if (!token || !nouveauMotDePasse)
      return res.status(400).json({ message: 'Token et nouveau mot de passe obligatoires' });
    if (nouveauMotDePasse.length < 6)
      return res.status(400).json({ message: 'Le mot de passe doit contenir au moins 6 caractères' });

    let payload;
    try {
      payload = jwt.verify(token, process.env.JWT_SECRET);
    } catch {
      return res.status(400).json({ message: 'Token invalide ou expiré' });
    }

    const hash = await bcrypt.hash(nouveauMotDePasse, 10);
    await Utilisateur.findByIdAndUpdate(payload.id, { motDePasse: hash });
    res.json({ success: true, message: 'Mot de passe réinitialisé avec succès' });
  } catch (err) {
    console.error('Reset password error:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};
