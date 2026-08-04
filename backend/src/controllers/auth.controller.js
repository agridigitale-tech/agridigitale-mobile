const bcrypt = require('bcryptjs');
const jwt    = require('jsonwebtoken');
const crypto = require('crypto');
const { Resend } = require('resend');
const Utilisateur = require('../models/Utilisateur');

const genererToken = (id, role) =>
  jwt.sign({ id, role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN });

const resend = new Resend(process.env.RESEND_API_KEY);
console.log('[Resend] Client initialisé');

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

// ── 6. ENVOYER OTP RESET ─────────────────────────────────────────────────────
exports.envoyerOTP = async (req, res, next) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: 'E-mail obligatoire' });

    const utilisateur = await Utilisateur.findOne({ email });

    // Toujours répondre OK — ne jamais révéler si l'email existe
    res.status(200).json({ success: true });

    if (!utilisateur) return;

    const otp = String(Math.floor(100000 + Math.random() * 900000));
    const otpHash = crypto.createHash('sha256').update(otp).digest('hex');
    const expiry = new Date(Date.now() + 10 * 60 * 1000); // 10 min

    await Utilisateur.findByIdAndUpdate(utilisateur._id, {
      resetToken: otpHash,
      resetTokenExpiry: expiry,
    });

    try {
      const result = await resend.emails.send({
        from: 'AgriDigitale <onboarding@resend.dev>',
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
      });
      console.log(`[OTP] Resend réponse:`, JSON.stringify(result));
    } catch (err) {
      console.error('[OTP] Échec email:', err.message, JSON.stringify(err));
    }

  } catch (err) {
    console.error('Send OTP error:', err);
  }
};

// ── 7. VÉRIFIER OTP + RESET MOT DE PASSE ─────────────────────────────────────
exports.verifierOTPetReset = async (req, res, next) => {
  try {
    const { email, otp, nouveauMotDePasse } = req.body;
    if (!email || !otp || !nouveauMotDePasse)
      return res.status(400).json({ message: 'Email, code OTP et nouveau mot de passe obligatoires' });
    if (nouveauMotDePasse.length < 6)
      return res.status(400).json({ message: 'Le mot de passe doit contenir au moins 6 caractères' });

    const otpHash = crypto.createHash('sha256').update(String(otp)).digest('hex');

    // Récupérer l'utilisateur avec les champs select:false explicitement
    const utilisateur = await Utilisateur.findOne({ email })
      .select('+resetToken +resetTokenExpiry');

    if (
      !utilisateur ||
      utilisateur.resetToken !== otpHash ||
      !utilisateur.resetTokenExpiry ||
      utilisateur.resetTokenExpiry < new Date()
    ) return res.status(400).json({ message: 'Code invalide ou expiré' });

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

// ── 8. ANCIEN SYSTÈME — conservé pour compatibilité ──────────────────────────
exports.motDePasseOublie = async (req, res) => res.status(200).json({ success: true });
exports.reinitialiserMotDePasse = async (req, res) => res.status(400).json({ message: 'Utilisez le nouveau système OTP' });
exports.redirectReset = (req, res) => res.status(404).send('Non disponible');
