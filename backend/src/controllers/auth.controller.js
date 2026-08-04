// Gère l'authentification des utilisateurs et la génération de jetons JWT
const bcrypt = require('bcryptjs');
const jwt    = require('jsonwebtoken');
const crypto = require('crypto');
const nodemailer = require('nodemailer');
const Utilisateur = require('../models/Utilisateur');

// ── Token JWT session ────────────────────────────────────────────────────────
const genererToken = (id, role) =>
  jwt.sign({ id, role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN });

// ── Token reset (opaque, stocké hashé en base) ──────────────────────────────
// Utilise crypto.randomBytes — pas de JWT pour le reset

// ── Transporteur SMTP Gmail ──────────────────────────────────────────────────
const _transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.SMTP_PORT || '465'),
  secure: parseInt(process.env.SMTP_PORT || '465') === 465, // SSL sur 465, STARTTLS sur 587
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
  tls: { rejectUnauthorized: false },
});

// Vérifier la connexion SMTP au démarrage
_transporter.verify()
  .then(() => console.log('[SMTP] Connexion Gmail OK'))
  .catch(err => console.error('[SMTP] Erreur connexion:', err.message));

async function envoyerEmailReset(destinataire, token) {
  const base = process.env.APP_URL || 'http://localhost:5000';
  const lien = `${base}/api/auth/reset-password/${encodeURIComponent(token)}`;
  await _transporter.sendMail({
    from: `AgriDigitale <${process.env.SMTP_USER}>`,
    to: destinataire,
    subject: '🌱 AgriDigitale — Réinitialisation de votre mot de passe',
    html: `
      <div style="font-family:Arial,sans-serif;max-width:500px;margin:auto;
                  padding:28px;border:1px solid #e0e0e0;border-radius:10px">
        <h2 style="color:#2e7d32;margin-top:0">🌱 AgriDigitale</h2>
        <p>Vous avez demandé la réinitialisation de votre mot de passe.</p>
        <p>Appuyez sur le bouton ci-dessous depuis votre téléphone pour ouvrir l'application :</p>
        <div style="text-align:center;margin:28px 0">
          <a href="${lien}"
             style="background:#2e7d32;color:#fff;padding:14px 32px;
                    border-radius:8px;text-decoration:none;font-size:16px;
                    font-weight:bold;display:inline-block">
            Réinitialiser mon mot de passe
          </a>
        </div>
        <p style="color:#888;font-size:12px">
          ⏱ Ce lien expire dans <strong>15 minutes</strong>.<br>
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

// ── 6. ENVOYER OTP RESET ────────────────────────────────────────────────────
exports.envoyerOTP = async (req, res, next) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: 'E-mail obligatoire' });

    const utilisateur = await Utilisateur.findOne({ email });

    // Toujours répondre OK — ne jamais révéler si l'email existe
    res.status(200).json({ success: true });

    if (!utilisateur) return; // email inexistant → on ne fait rien

    // Générer un code OTP à 6 chiffres
    const otp = String(Math.floor(100000 + Math.random() * 900000));
    const otpHash = crypto.createHash('sha256').update(otp).digest('hex');
    const expiry = new Date(Date.now() + 10 * 60 * 1000); // 10 min

    await Utilisateur.findByIdAndUpdate(utilisateur._id, {
      resetToken: otpHash,
      resetTokenExpiry: expiry,
    });

    // Envoi email en arrière-plan
    _transporter.sendMail({
      from: `AgriDigitale <${process.env.SMTP_USER}>`,
      to: email,
      subject: '🌱 AgriDigitale — Code de réinitialisation',
      html: `
        <div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;
                    padding:32px;border:1px solid #e0e0e0;border-radius:12px">
          <h2 style="color:#2e7d32;margin-top:0">🌱 AgriDigitale</h2>
          <p style="font-size:15px">Voici votre code de réinitialisation de mot de passe :</p>
          <div style="text-align:center;margin:28px 0">
            <span style="font-size:42px;font-weight:bold;letter-spacing:10px;
                         color:#2e7d32;background:#f1f8e9;padding:16px 28px;
                         border-radius:10px;display:inline-block">${otp}</span>
          </div>
          <p style="color:#555;font-size:14px">Ce code est valable <strong>10 minutes</strong>.</p>
          <p style="color:#999;font-size:12px">Si vous n'avez pas fait cette demande, ignorez cet email.</p>
        </div>
      `,
    })
    .then(() => console.log(`[OTP] Code envoyé à ${email}`))
    .catch(err => console.error('[OTP] Échec email:', err.message));

  } catch (err) {
    console.error('Send OTP error:', err);
  }
};

// ── 7. VÉRIFIER OTP + RESET MOT DE PASSE ────────────────────────────────────
exports.verifierOTPetReset = async (req, res, next) => {
  try {
    const { email, otp, nouveauMotDePasse } = req.body;
    if (!email || !otp || !nouveauMotDePasse)
      return res.status(400).json({ message: 'Email, code OTP et nouveau mot de passe obligatoires' });
    if (nouveauMotDePasse.length < 6)
      return res.status(400).json({ message: 'Le mot de passe doit contenir au moins 6 caractères' });

    const otpHash = crypto.createHash('sha256').update(String(otp)).digest('hex');
    const utilisateur = await Utilisateur.findOne({
      email,
      resetToken: otpHash,
      resetTokenExpiry: { $gt: new Date() },
    }).select('+resetToken +resetTokenExpiry');

    if (!utilisateur)
      return res.status(400).json({ message: 'Code invalide ou expiré' });

    const hash = await bcrypt.hash(nouveauMotDePasse, 10);
    await Utilisateur.findByIdAndUpdate(utilisateur._id, {
      motDePasse: hash,
      resetToken: null,
      resetTokenExpiry: null,
    });

    res.json({ success: true, message: 'Mot de passe réinitialisé avec succès' });
  } catch (err) {
    console.error('Verify OTP error:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// ── 8. MOT DE PASSE OUBLIÉ (ancien système — conservé) ───────────────────────
exports.motDePasseOublie = async (req, res, next) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: 'E-mail obligatoire' });

    // Répondre immédiatement — ne jamais révéler si l'email existe ou non
    res.status(200).json({ success: true });

    const utilisateur = await Utilisateur.findOne({ email }).select('+resetToken +resetTokenExpiry');
    if (!utilisateur) return;

    // Token opaque (non-JWT) stocké hashé en base — usage unique
    const tokenBrut = crypto.randomBytes(32).toString('hex');
    const tokenHash = crypto.createHash('sha256').update(tokenBrut).digest('hex');
    const expiry = new Date(Date.now() + 15 * 60 * 1000); // 15 min

    await Utilisateur.findByIdAndUpdate(utilisateur._id, {
      resetToken: tokenHash,
      resetTokenExpiry: expiry,
    });

    // Envoi email en arrière-plan
    envoyerEmailReset(email, tokenBrut)
      .then(() => console.log(`[RESET] Email envoyé à ${email}`))
      .catch(err => console.error('[RESET] Échec email:', err.message));

  } catch (err) {
    console.error('Forgot password error:', err);
  }
};

// ── 7. PAGE INTERMÉDIAIRE RESET (lien email → deep link app) ───────────────
exports.redirectReset = (req, res) => {
  const token = encodeURIComponent(req.params.token);
  const deepLink = `agridigitale://reset-password?token=${token}`;
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(`<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>AgriDigitale — Réinitialisation</title>
  <style>
    *{margin:0;padding:0;box-sizing:border-box}
    body{font-family:Arial,sans-serif;background:#f5f5f5;display:flex;
         align-items:center;justify-content:center;min-height:100vh;padding:20px}
    .card{background:#fff;border-radius:12px;padding:36px 28px;max-width:420px;
          width:100%;text-align:center;box-shadow:0 2px 16px rgba(0,0,0,.1)}
    h2{color:#2e7d32;margin-bottom:12px;font-size:22px}
    p{color:#555;font-size:14px;line-height:1.6;margin-bottom:20px}
    .btn{display:inline-block;background:#2e7d32;color:#fff;padding:14px 32px;
         border-radius:8px;text-decoration:none;font-size:16px;font-weight:bold;
         margin-bottom:16px}
    .note{color:#999;font-size:12px}
  </style>
</head>
<body>
  <div class="card">
    <h2>🌱 AgriDigitale</h2>
    <p>Appuyez sur le bouton ci-dessous pour ouvrir l'application et réinitialiser votre mot de passe.</p>
    <a class="btn" href="${deepLink}">Ouvrir l'application</a>
    <p class="note">Si le bouton ne fonctionne pas, assurez-vous que l'application AgriDigitale est installée sur votre téléphone.</p>
  </div>
  <script>
    // Tentative d'ouverture automatique du deep link
    setTimeout(function() { window.location.href = '${deepLink}'; }, 800);
  </script>
</body>
</html>`);
};

// ── 8. RÉINITIALISATION DU MOT DE PASSE ─────────────────────────────────────
exports.reinitialiserMotDePasse = async (req, res, next) => {
  try {
    const { token, nouveauMotDePasse } = req.body;
    if (!token || !nouveauMotDePasse)
      return res.status(400).json({ message: 'Token et nouveau mot de passe obligatoires' });
    if (nouveauMotDePasse.length < 6)
      return res.status(400).json({ message: 'Le mot de passe doit contenir au moins 6 caractères' });

    // Retrouver l'utilisateur via le hash du token
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
    const utilisateur = await Utilisateur.findOne({
      resetToken: tokenHash,
      resetTokenExpiry: { $gt: new Date() },
    }).select('+resetToken +resetTokenExpiry');

    if (!utilisateur)
      return res.status(400).json({ message: 'Token invalide ou expiré' });

    const hash = await bcrypt.hash(nouveauMotDePasse, 10);
    // Invalider le token après usage (usage unique)
    await Utilisateur.findByIdAndUpdate(utilisateur._id, {
      motDePasse: hash,
      resetToken: null,
      resetTokenExpiry: null,
    });
    res.json({ success: true, message: 'Mot de passe réinitialisé avec succès' });
  } catch (err) {
    console.error('Reset password error:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};
