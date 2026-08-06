const bcrypt = require('bcryptjs');
const jwt    = require('jsonwebtoken');
const crypto = require('crypto');
const { google } = require('googleapis');
const Utilisateur = require('../models/Utilisateur');
const buildOtpHtml = require('../services/emailTemplate');

const genererToken = (id, role) =>
  jwt.sign({ id, role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN });

const _oauth2Client = new google.auth.OAuth2(
  process.env.GMAIL_CLIENT_ID,
  process.env.GMAIL_CLIENT_SECRET,
  'https://developers.google.com/oauthplayground'
);
_oauth2Client.setCredentials({ refresh_token: process.env.GMAIL_REFRESH_TOKEN });

// Encode un sujet avec des caractères spéciaux en RFC 2047
const _encoderSujet = (s) => `=?UTF-8?B?${Buffer.from(s).toString('base64')}?=`;

const _envoyerEmailGmail = async (to, subject, html) => {
  const gmail = google.gmail({ version: 'v1', auth: _oauth2Client });
  const htmlBase64 = Buffer.from(html, 'utf-8').toString('base64');
  const message = [
    `To: ${to}`,
    `From: AgriDigitale <${process.env.SMTP_USER}>`,
    `Subject: ${_encoderSujet(subject)}`,
    'MIME-Version: 1.0',
    'Content-Type: text/html; charset=utf-8',
    'Content-Transfer-Encoding: base64',
    '',
    htmlBase64,
  ].join('\r\n');
  const encoded = Buffer.from(message, 'utf-8').toString('base64url');
  await gmail.users.messages.send({ userId: 'me', requestBody: { raw: encoded } });
};

console.log('[Gmail API] Configuré pour', process.env.SMTP_USER);

// Map pays → continent
const _continentParPays = {
  AF:'Asie',DZ:'Afrique',AO:'Afrique',AR:'Amérique du Sud',AU:'Océanie',
  BD:'Asie',BE:'Europe',BF:'Afrique',BJ:'Afrique',BR:'Amérique du Sud',
  CA:'Amérique du Nord',CD:'Afrique',CF:'Afrique',CG:'Afrique',CH:'Europe',
  CI:'Afrique',CL:'Amérique du Sud',CM:'Afrique',CN:'Asie',CO:'Amérique du Sud',
  CV:'Afrique',DE:'Europe',DJ:'Afrique',DZ:'Afrique',EG:'Afrique',
  ES:'Europe',ET:'Afrique',FR:'Europe',GA:'Afrique',GB:'Europe',
  GH:'Afrique',GM:'Afrique',GN:'Afrique',GW:'Afrique',ID:'Asie',
  IN:'Asie',IT:'Europe',JP:'Asie',KE:'Afrique',KR:'Asie',
  LR:'Afrique',LY:'Afrique',MA:'Afrique',MG:'Afrique',ML:'Afrique',
  MR:'Afrique',MX:'Amérique du Nord',MZ:'Afrique',NE:'Afrique',NG:'Afrique',
  NL:'Europe',NZ:'Océanie',PE:'Amérique du Sud',PK:'Asie',PL:'Europe',
  PT:'Europe',RO:'Europe',RW:'Afrique',SE:'Europe',SL:'Afrique',
  SN:'Afrique',TD:'Afrique',TG:'Afrique',TN:'Afrique',TZ:'Afrique',
  UG:'Afrique',US:'Amérique du Nord',VE:'Amérique du Sud',VN:'Asie',
  ZA:'Afrique',ZM:'Afrique',ZW:'Afrique',
};

// ── 1. INSCRIPTION ───────────────────────────────────────────────────────────
exports.inscrire = async (req, res, next) => {
  try {
    const { nom, email, motDePasse, pays, codePays } = req.body;
    if (!nom || !email || !motDePasse)
      return res.status(400).json({ message: 'Tous les champs sont obligatoires' });
    if (motDePasse.length < 6)
      return res.status(400).json({ message: 'Le mot de passe doit contenir au moins 6 caractères' });

    const existe = await Utilisateur.findOne({ email });
    if (existe) return res.status(409).json({ message: 'Cet e-mail est déjà utilisé' });

    const continent = _continentParPays[codePays?.toUpperCase()] || 'Afrique';
    const hash = await bcrypt.hash(motDePasse, 10);
    const utilisateur = await new Utilisateur({
      nom, email, motDePasse: hash,
      pays: pays || '', continent,
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

// ── 4. MODIFIER LE PROFIL─
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

// ── 5. TOKEN FCM 
exports.enregistrerTokenFCM = async (req, res, next) => {
  try {
    await Utilisateur.findByIdAndUpdate(req.utilisateurId, { tokenFCM: req.body.token });
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ message: "Erreur lors de l'enregistrement du token FCM" });
  }
};

// ── 6. ENVOYER OTP RESET 
exports.envoyerOTP = async (req, res, next) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: 'E-mail obligatoire' });

    const utilisateur = await Utilisateur.findOne({ email })
      .select('+otpTentatives +otpFenetre');

    // Toujours répondre OK — ne jamais révéler si l'email existe
    res.status(200).json({ success: true });

    if (!utilisateur) return;

    // Limite : 3 tentatives par heure
    const maintenant = Date.now();
    const fenetreExpire = !utilisateur.otpFenetre || (maintenant - utilisateur.otpFenetre.getTime() > 60 * 60 * 1000);
    const tentatives = fenetreExpire ? 0 : (utilisateur.otpTentatives || 0);
    if (tentatives >= 3) {
      console.warn(`[OTP] Limite atteinte pour ${email}`);
      return;
    }

    const otp = String(Math.floor(100000 + Math.random() * 900000));
    const otpHash = crypto.createHash('sha256').update(otp).digest('hex');
    const expiry = new Date(Date.now() + 10 * 60 * 1000);

    await Utilisateur.findByIdAndUpdate(utilisateur._id, {
      resetToken: otpHash,
      resetTokenExpiry: expiry,
      otpTentatives: tentatives + 1,
      otpFenetre: fenetreExpire ? new Date() : utilisateur.otpFenetre,
    });

    try {
      await _envoyerEmailGmail(
        email,
        'AgriDigitale - Code de reinitialisation',
        buildOtpHtml(otp),
      );
      console.log(`[OTP] Code envoye a ${email} (tentative ${tentatives + 1}/3)`);
    } catch (err) {
      console.error('[OTP] Echec email:', err.message);
    }

  } catch (err) {
    console.error('Send OTP error:', err);
  }
};

// ── 7. VÉRIFIER OTP + RESET MOT DE PASSE
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

// ── 8. ANCIEN SYSTÈME — conservé pour compatibilité 
exports.motDePasseOublie = async (req, res) => res.status(200).json({ success: true });
exports.reinitialiserMotDePasse = async (req, res) => res.status(400).json({ message: 'Utilisez le nouveau système OTP' });
exports.redirectReset = (req, res) => res.status(404).send('Non disponible');
