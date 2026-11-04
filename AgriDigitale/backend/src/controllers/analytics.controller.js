// Contrôleur de Télémétrie & Analytics Avancé
// Suivi individuel des utilisateurs, temps d'écran par menu (Home, Météo, TV, Jeux),
// détection en direct de l'écran actif, heures d'utilisation et classement des utilisateurs.
const mongoose = require('mongoose');
const Analytics = require('../models/Analytics');
const DeviceStatus = require('../models/DeviceStatus');

const LIBELLES_ECRANS = {
  home: 'Accueil',
  meteo: 'Météo',
  tv: 'WebTV (AGDTV)',
  jeux: 'Jeux / Quiz',
  favoris: 'Favoris',
  parametres: 'Paramètres',
  article: 'Lecture Article',
  autre: 'Autre',
};

const COULEURS_ECRANS = {
  home: '#10b981',       // Émeraude
  meteo: '#38bdf8',      // Ciel bleu
  tv: '#f43f5e',         // Rose / Rouge TV
  jeux: '#a855f7',       // Violet Quiz
  article: '#f59e0b',    // Ambre
  favoris: '#ec4899',    // Rose
  parametres: '#64748b', // Ardoise
  autre: '#94a3b8',
};

// Formate les secondes en texte lisible (ex: "1h 24m", "4m 12s", "35s")
function formaterDuree(secondes) {
  const s = Math.max(0, Math.round(Number(secondes) || 0));
  if (s < 60) return `${s}s`;
  const m = Math.floor(s / 60);
  const resteS = s % 60;
  if (m < 60) {
    return resteS > 0 ? `${m}m ${resteS}s` : `${m} min`;
  }
  const h = Math.floor(m / 60);
  const resteM = m % 60;
  return resteM > 0 ? `${h}h ${resteM}m` : `${h}h`;
}

// Calcule le temps relatif (ex: "À l'instant", "Il y a 5 min", "Il y a 2h", "Le 04/11 à 16:30")
function formaterTempsRelatif(date) {
  if (!date) return 'Jamais';
  const diffSec = Math.floor((Date.now() - new Date(date).getTime()) / 1000);
  if (diffSec < 60) return "À l'instant";
  const diffMin = Math.floor(diffSec / 60);
  if (diffMin < 60) return `Il y a ${diffMin} min`;
  const diffHeures = Math.floor(diffMin / 60);
  if (diffHeures < 24) return `Il y a ${diffHeures}h`;
  const d = new Date(date);
  return `${d.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit' })} à ${d.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}`;
}

// Détermine l'écran où l'utilisateur passe le plus de temps
function determinerTopEcran(tempsParEcran) {
  if (!tempsParEcran) {
    return { ecran: 'home', libelle: 'Accueil', secondes: 0, minutes: 0, pourcentage: 100 };
  }
  let maxSec = -1;
  let top = 'home';
  let total = 0;
  for (const [key, val] of Object.entries(tempsParEcran)) {
    const sec = Math.max(0, Number(val) || 0);
    total += sec;
    if (sec > maxSec) {
      maxSec = sec;
      top = key;
    }
  }
  return {
    ecran: top,
    libelle: LIBELLES_ECRANS[top] || top,
    secondes: Math.max(0, maxSec),
    minutes: Math.round(Math.max(0, maxSec) / 60),
    pourcentage: total > 0 ? Math.round((Math.max(0, maxSec) / total) * 100) : 100,
  };
}

// Détermine la première action la plus fréquente à l'ouverture
function determinerPremiereAction(premieresActions) {
  if (!premieresActions) {
    return { ecran: 'home', libelle: 'Accueil', occurrences: 0, pourcentage: 100 };
  }
  let maxCount = -1;
  let top = 'home';
  let total = 0;
  for (const [key, val] of Object.entries(premieresActions)) {
    const count = Math.max(0, Number(val) || 0);
    total += count;
    if (count > maxCount) {
      maxCount = count;
      top = key;
    }
  }
  return {
    ecran: top,
    libelle: LIBELLES_ECRANS[top] || top,
    occurrences: Math.max(0, maxCount),
    pourcentage: total > 0 ? Math.round((Math.max(0, maxCount) / total) * 100) : 100,
  };
}

// Synchronise la collection DeviceStatus en tâche de fond pour chaque lot d'événements
async function synchroniserDeviceStatus(events) {
  for (const e of events) {
    if (!e || !e.deviceId) continue;
    const deviceId = String(e.deviceId).trim();
    const dateEvt = e.date ? new Date(e.date) : new Date();

    const heure = (e.heureJour !== undefined && e.heureJour !== null)
      ? Number(e.heureJour)
      : dateEvt.getHours();
    const cleHeure = `heuresUtilisation.h${Math.min(23, Math.max(0, isNaN(heure) ? dateEvt.getHours() : heure))}`;

    let ecranCle = 'autre';
    if (e.ecran && ['home', 'meteo', 'tv', 'jeux', 'favoris', 'parametres', 'article'].includes(e.ecran)) {
      ecranCle = e.ecran;
    } else if (e.typeEvenement === 'article_lecture') {
      ecranCle = 'article';
    } else if (e.categorie === 'Accueil') {
      ecranCle = 'home';
    }

    let premierCle = 'home';
    if (e.premierEcran && ['home', 'meteo', 'tv', 'jeux', 'favoris', 'parametres', 'article'].includes(e.premierEcran)) {
      premierCle = e.premierEcran;
    }

    const setObj = {
      derniereActivite: dateEvt,
    };
    if (e.plateforme && e.plateforme !== 'inconnu') setObj.plateforme = e.plateforme;
    if (e.utilisateurId) setObj.utilisateurId = e.utilisateurId;
    if (e.nomUtilisateur) setObj.nomUtilisateur = e.nomUtilisateur;
    if (e.emailUtilisateur) setObj.emailUtilisateur = e.emailUtilisateur;
    if (e.ecran || e.typeEvenement === 'presence_ping' || e.typeEvenement === 'ecran_vue') {
      setObj.ecranActif = ecranCle;
    }

    const incObj = {
      [cleHeure]: 1,
    };

    const duree = Math.min(3600, Math.max(0, Number(e.dureeSecondes) || 0));
    if (duree > 0) {
      incObj.tempsTotalSecondes = duree;
      incObj[`tempsParEcran.${ecranCle}`] = duree;
    }

    if (e.typeEvenement === 'app_open') {
      incObj.nombreOuvertures = 1;
      incObj[`premieresActions.${premierCle}`] = 1;
    } else if (e.typeEvenement === 'premiere_action') {
      incObj[`premieresActions.${premierCle}`] = 1;
    }

    if (e.typeEvenement === 'article_lecture') {
      incObj.articlesLus = 1;
    }

    try {
      await DeviceStatus.updateOne(
        { deviceId },
        {
          $setOnInsert: { premiereActivite: dateEvt },
          $set: setObj,
          $inc: incObj,
        },
        { upsert: true }
      );
    } catch (err) {
      console.warn('[Analytics] Erreur mise à jour DeviceStatus:', err.message);
    }
  }
}

// Initialise DeviceStatus à partir d'Analytics existants si la collection est vide
async function bootstrapDeviceStatusSiVide() {
  try {
    const count = await DeviceStatus.countDocuments();
    if (count > 0) return;
    const tousEvents = await Analytics.find().sort({ date: 1 }).lean();
    if (tousEvents.length > 0) {
      console.log(`[Analytics] Amorçage de DeviceStatus avec ${tousEvents.length} événements historiques...`);
      await synchroniserDeviceStatus(tousEvents);
      console.log('[Analytics] Amorçage de DeviceStatus terminé avec succès.');
    }
  } catch (err) {
    console.warn('[Analytics] Erreur lors de l\'amorçage:', err.message);
  }
}

// POST /api/analytics/track
// Reçoit un événement ou une liste d'événements de télémétrie en arrière-plan
exports.track = async (req, res, next) => {
  try {
    const data = req.body;
    if (!data) return res.status(400).json({ message: 'Données manquantes' });

    const events = Array.isArray(data) ? data : [data];

    const docs = events
      .filter(e => e && e.deviceId && e.typeEvenement)
      .map(e => {
        const dateEvt = e.date ? new Date(e.date) : new Date();
        const heure = (e.heureJour !== undefined && e.heureJour !== null)
          ? Number(e.heureJour)
          : dateEvt.getHours();
        return {
          deviceId: String(e.deviceId).trim(),
          utilisateurId: req.utilisateurId || e.utilisateurId || null,
          nomUtilisateur: e.nomUtilisateur || null,
          emailUtilisateur: e.emailUtilisateur || null,
          typeEvenement: e.typeEvenement,
          ecran: e.ecran || null,
          premierEcran: e.premierEcran || null,
          articleId: e.articleId || null,
          titreArticle: e.titreArticle || null,
          categorie: e.categorie || 'Général',
          dureeSecondes: Math.max(0, Number(e.dureeSecondes || e.tempsPasseSecondes) || 0),
          pourcentageLecture: Number(e.pourcentageLecture || 0),
          plateforme: e.plateforme || 'inconnu',
          heureJour: isNaN(heure) ? dateEvt.getHours() : Math.min(23, Math.max(0, heure)),
          date: dateEvt,
        };
      });

    if (docs.length > 0) {
      await Analytics.insertMany(docs, { ordered: false });
      // Synchronisation asynchrone non-bloquante pour DeviceStatus
      synchroniserDeviceStatus(docs).catch(err =>
        console.warn('[Analytics] Sync background error:', err.message)
      );
    }

    res.status(202).json({ success: true, count: docs.length });
  } catch (err) {
    res.status(202).json({ success: false, error: err.message });
  }
};

// GET /api/analytics/stats
// Calcule les statistiques globales d'audience, de temps d'écran par menu et d'heures de pointe
exports.getStats = async (req, res, next) => {
  try {
    await bootstrapDeviceStatusSiVide();

    const { periode = '30j' } = req.query;
    const now = new Date();
    let dateDebut = new Date();

    if (periode === '24h') {
      dateDebut.setHours(dateDebut.getHours() - 24);
    } else if (periode === '7j') {
      dateDebut.setDate(dateDebut.getDate() - 7);
    } else if (periode === '30j') {
      dateDebut.setDate(dateDebut.getDate() - 30);
    } else if (periode === 'tout') {
      dateDebut = new Date(0);
    }

    const matchFiltre = { date: { $gte: dateDebut } };
    const deuxMinutesAgo = new Date(Date.now() - 2 * 60 * 1000);

    const [
      totalAppareilsDistincts,
      appareilsEnLigne,
      kpisTemps,
      topArticles,
      evolutionJours,
      tousDeviceStatus,
    ] = await Promise.all([
      // Total appareils distincts
      DeviceStatus.countDocuments(),

      // Appareils actifs en ligne (< 2 minutes)
      DeviceStatus.find({ derniereActivite: { $gte: deuxMinutesAgo } }).lean(),

      // Temps total & ouvertures globales depuis Analytics
      Analytics.aggregate([
        { $match: matchFiltre },
        {
          $group: {
            _id: null,
            tempsTotalSecondes: { $sum: '$dureeSecondes' },
            totalOuvertures: {
              $sum: { $cond: [{ $eq: ['$typeEvenement', 'app_open'] }, 1, 0] },
            },
            totalLecturesArticles: {
              $sum: { $cond: [{ $eq: ['$typeEvenement', 'article_lecture'] }, 1, 0] },
            },
            totalSessions: {
              $sum: { $cond: [{ $eq: ['$typeEvenement', 'session'] }, 1, 0] },
            },
          },
        },
      ]),

      // Top Articles les plus captivants
      Analytics.aggregate([
        {
          $match: {
            ...matchFiltre,
            typeEvenement: 'article_lecture',
            articleId: { $ne: null },
          },
        },
        {
          $group: {
            _id: '$articleId',
            titre: { $first: '$titreArticle' },
            categorie: { $first: '$categorie' },
            tempsTotalSecondes: { $sum: '$dureeSecondes' },
            lectures: { $sum: 1 },
            tempsMoyenSecondes: { $avg: '$dureeSecondes' },
          },
        },
        { $sort: { tempsTotalSecondes: -1 } },
        { $limit: 10 },
      ]),

      // Évolution du temps passé par jour (14 jours)
      Analytics.aggregate([
        {
          $match: {
            date: { $gte: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000) },
          },
        },
        {
          $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$date' } },
            tempsTotalSecondes: { $sum: '$dureeSecondes' },
            utilisateursActifs: { $addToSet: '$deviceId' },
          },
        },
        { $sort: { _id: 1 } },
      ]),

      // Tous les DeviceStatus pour calcul agrégé des menus et des heures
      DeviceStatus.find().lean(),
    ]);

    // Calcul de la répartition du temps par Menu (Home, Météo, TV, Jeux, Articles, Autres)
    const tempsMenus = {
      home: 0,
      meteo: 0,
      tv: 0,
      jeux: 0,
      article: 0,
      autre: 0,
    };

    const premieresActionsCumul = {
      home: 0,
      meteo: 0,
      tv: 0,
      jeux: 0,
      autre: 0,
    };

    const distributionHeuresGlobale = new Array(24).fill(0);
    const detailEcransEnLigne = {
      home: 0,
      meteo: 0,
      tv: 0,
      jeux: 0,
      autre: 0,
    };

    appareilsEnLigne.forEach(app => {
      const ecran = app.ecranActif || 'home';
      if (detailEcransEnLigne[ecran] !== undefined) {
        detailEcransEnLigne[ecran]++;
      } else {
        detailEcransEnLigne.autre++;
      }
    });

    tousDeviceStatus.forEach(app => {
      if (app.tempsParEcran) {
        tempsMenus.home += (app.tempsParEcran.home || 0);
        tempsMenus.meteo += (app.tempsParEcran.meteo || 0);
        tempsMenus.tv += (app.tempsParEcran.tv || 0);
        tempsMenus.jeux += (app.tempsParEcran.jeux || 0);
        tempsMenus.article += (app.tempsParEcran.article || 0);
        tempsMenus.autre += (app.tempsParEcran.favoris || 0) + (app.tempsParEcran.parametres || 0) + (app.tempsParEcran.autre || 0);
      }
      if (app.premieresActions) {
        premieresActionsCumul.home += (app.premieresActions.home || 0);
        premieresActionsCumul.meteo += (app.premieresActions.meteo || 0);
        premieresActionsCumul.tv += (app.premieresActions.tv || 0);
        premieresActionsCumul.jeux += (app.premieresActions.jeux || 0);
        premieresActionsCumul.autre += (app.premieresActions.favoris || 0) + (app.premieresActions.parametres || 0);
      }
      if (app.heuresUtilisation) {
        for (let h = 0; h < 24; h++) {
          distributionHeuresGlobale[h] += (app.heuresUtilisation[`h${h}`] || 0);
        }
      }
    });

    const totalSecondesMenus = Object.values(tempsMenus).reduce((a, b) => a + b, 0);
    const listeTempsParMenu = Object.entries(tempsMenus).map(([cle, sec]) => ({
      ecran: cle,
      libelle: LIBELLES_ECRANS[cle] || cle,
      couleur: COULEURS_ECRANS[cle] || '#94a3b8',
      secondes: sec,
      minutes: Math.round(sec / 60),
      formatte: formaterDuree(sec),
      pourcentage: totalSecondesMenus > 0 ? Math.round((sec / totalSecondesMenus) * 100) : 0,
    }));

    // Trouver l'heure de pointe
    let heurePicIndex = 0;
    let maxHeureCount = 0;
    distributionHeuresGlobale.forEach((count, h) => {
      if (count > maxHeureCount) {
        maxHeureCount = count;
        heurePicIndex = h;
      }
    });

    const kpi = kpisTemps[0] || {
      tempsTotalSecondes: 0,
      totalOuvertures: 0,
      totalLecturesArticles: 0,
      totalSessions: 0,
    };

    const tempsTotalTousDevices = tousDeviceStatus.reduce((acc, d) => acc + (d.tempsTotalSecondes || 0), 0);
    const tempsTotalSec = Math.max(kpi.tempsTotalSecondes || 0, tempsTotalTousDevices);

    res.json({
      kpis: {
        totalAppareils: Math.max(totalAppareilsDistincts, tousDeviceStatus.length),
        enLigneActuellement: appareilsEnLigne.length,
        detailEcransEnLigne,
        tempsTotalSecondes: tempsTotalSec,
        tempsTotalHeures: (tempsTotalSec / 3600).toFixed(1),
        tempsTotalFormatte: formaterDuree(tempsTotalSec),
        totalOuvertures: Math.max(kpi.totalOuvertures || 0, tousDeviceStatus.reduce((a, b) => a + (b.nombreOuvertures || 0), 0)),
        totalLecturesArticles: kpi.totalLecturesArticles,
        heurePic: `${heurePicIndex}h00 - ${heurePicIndex + 1}h00`,
      },
      tempsParMenu: listeTempsParMenu,
      heuresDistribution: distributionHeuresGlobale,
      premieresActions: Object.entries(premieresActionsCumul).map(([cle, count]) => ({
        ecran: cle,
        libelle: LIBELLES_ECRANS[cle] || cle,
        couleur: COULEURS_ECRANS[cle] || '#94a3b8',
        occurrences: count,
      })),
      topArticles: topArticles.map(a => ({
        id: a._id,
        titre: a.titre || 'Article sans titre',
        categorie: a.categorie || 'Général',
        tempsTotalMinutes: (a.tempsTotalSecondes / 60).toFixed(1),
        tempsMoyenSecondes: Math.round(a.tempsMoyenSecondes || 0),
        lectures: a.lectures,
      })),
      evolutionJours: evolutionJours.map(j => ({
        jour: j._id,
        tempsMinutes: Math.round(j.tempsTotalSecondes / 60),
        appareilsActifs: (j.utilisateursActifs || []).length,
      })),
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/analytics/users
// Renvoie la liste paginée ou triée des utilisateurs pour le classement et la recherche
exports.getUsers = async (req, res, next) => {
  try {
    await bootstrapDeviceStatusSiVide();

    const { tri = 'temps_desc', q = '', limite = 50 } = req.query;
    const deuxMinutesAgo = new Date(Date.now() - 2 * 60 * 1000);

    const filtre = {};
    if (q && q.trim()) {
      const reg = new RegExp(q.trim(), 'i');
      filtre.$or = [
        { deviceId: reg },
        { nomUtilisateur: reg },
        { emailUtilisateur: reg },
        { ecranActif: reg },
      ];
    }

    if (tri === 'en_ligne') {
      filtre.derniereActivite = { $gte: deuxMinutesAgo };
    }

    let sortOption = { tempsTotalSecondes: -1 };
    if (tri === 'temps_asc') {
      sortOption = { tempsTotalSecondes: 1 };
    } else if (tri === 'en_ligne' || tri === 'recent') {
      sortOption = { derniereActivite: -1 };
    }

    const devices = await DeviceStatus.find(filtre)
      .sort(sortOption)
      .limit(Number(limite) || 50)
      .lean();

    const resultats = devices.map((d, index) => {
      const estEnLigne = d.derniereActivite && new Date(d.derniereActivite) >= deuxMinutesAgo;
      const topEcran = determinerTopEcran(d.tempsParEcran);
      const premierEcran = determinerPremiereAction(d.premieresActions);

      return {
        rang: index + 1,
        deviceId: d.deviceId,
        deviceIdCourt: 'Appareil #' + String(d.deviceId).slice(-6).toUpperCase(),
        nomUtilisateur: d.nomUtilisateur || null,
        emailUtilisateur: d.emailUtilisateur || null,
        plateforme: d.plateforme || 'inconnu',
        estEnLigne,
        ecranActif: d.ecranActif || 'home',
        ecranActifLibelle: LIBELLES_ECRANS[d.ecranActif] || d.ecranActif || 'Accueil',
        tempsTotalSecondes: d.tempsTotalSecondes || 0,
        tempsTotalFormatte: formaterDuree(d.tempsTotalSecondes),
        tempsTotalMinutes: Math.round((d.tempsTotalSecondes || 0) / 60),
        nombreOuvertures: d.nombreOuvertures || 0,
        articlesLus: d.articlesLus || 0,
        derniereActivite: d.derniereActivite,
        derniereActiviteFormatte: formaterTempsRelatif(d.derniereActivite),
        premiereActivite: d.premiereActivite,
        topEcran,
        premierEcran,
      };
    });

    res.json({
      total: resultats.length,
      users: resultats,
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/analytics/user/:deviceId
// Retourne la fiche analytique ultra-complète d'un utilisateur spécifique
exports.getUserDetail = async (req, res, next) => {
  try {
    await bootstrapDeviceStatusSiVide();

    const { deviceId } = req.params;
    if (!deviceId) return res.status(400).json({ message: 'deviceId obligatoire' });

    let device = await DeviceStatus.findOne({ deviceId }).lean();

    // S'il n'existe pas encore dans DeviceStatus, vérifie s'il existe dans Analytics
    if (!device) {
      const events = await Analytics.find({ deviceId }).lean();
      if (events.length > 0) {
        await synchroniserDeviceStatus(events);
        device = await DeviceStatus.findOne({ deviceId }).lean();
      }
    }

    if (!device) {
      return res.status(404).json({ message: 'Aucun enregistrement pour cet appareil' });
    }

    const deuxMinutesAgo = new Date(Date.now() - 2 * 60 * 1000);
    const estEnLigne = device.derniereActivite && new Date(device.derniereActivite) >= deuxMinutesAgo;

    // Derniers 30 événements récents de cet utilisateur
    const eventsRecents = await Analytics.find({ deviceId })
      .sort({ date: -1 })
      .limit(30)
      .lean();

    // Temps passé par écran détaillé
    const tempsParEcran = device.tempsParEcran || {};
    const menus = ['home', 'meteo', 'tv', 'jeux', 'article', 'autre'];
    const totalSec = device.tempsTotalSecondes || 1;

    const tempsMenusDetails = menus.map(cle => {
      let sec = 0;
      if (cle === 'autre') {
        sec = (tempsParEcran.favoris || 0) + (tempsParEcran.parametres || 0) + (tempsParEcran.autre || 0);
      } else {
        sec = tempsParEcran[cle] || 0;
      }
      return {
        ecran: cle,
        libelle: LIBELLES_ECRANS[cle] || cle,
        couleur: COULEURS_ECRANS[cle] || '#94a3b8',
        secondes: sec,
        minutes: Math.round(sec / 60),
        formatte: formaterDuree(sec),
        pourcentage: totalSec > 0 ? Math.round((sec / totalSec) * 100) : 0,
      };
    });

    // Heures d'utilisation (0h à 23h) pour cet utilisateur précis
    const heures = new Array(24).fill(0);
    if (device.heuresUtilisation) {
      for (let h = 0; h < 24; h++) {
        heures[h] = device.heuresUtilisation[`h${h}`] || 0;
      }
    }

    // Trouver l'heure de pic de cet utilisateur
    let maxHCount = 0;
    let picH = 0;
    heures.forEach((count, h) => {
      if (count > maxHCount) {
        maxHCount = count;
        picH = h;
      }
    });

    const topEcran = determinerTopEcran(device.tempsParEcran);
    const premierEcran = determinerPremiereAction(device.premieresActions);

    res.json({
      appareil: {
        deviceId: device.deviceId,
        deviceIdCourt: 'Appareil #' + String(device.deviceId).slice(-6).toUpperCase(),
        nomUtilisateur: device.nomUtilisateur || 'Visiteur non identifié',
        emailUtilisateur: device.emailUtilisateur || null,
        plateforme: device.plateforme || 'inconnu',
        estEnLigne,
        ecranActif: device.ecranActif || 'home',
        ecranActifLibelle: LIBELLES_ECRANS[device.ecranActif] || device.ecranActif || 'Accueil',
        premiereActivite: device.premiereActivite,
        premiereActiviteFormatte: formaterTempsRelatif(device.premiereActivite),
        derniereActivite: device.derniereActivite,
        derniereActiviteFormatte: formaterTempsRelatif(device.derniereActivite),
      },
      kpis: {
        tempsTotalSecondes: device.tempsTotalSecondes || 0,
        tempsTotalFormatte: formaterDuree(device.tempsTotalSecondes),
        tempsTotalMinutes: Math.round((device.tempsTotalSecondes || 0) / 60),
        nombreOuvertures: device.nombreOuvertures || 0,
        articlesLus: device.articlesLus || 0,
        heurePic: `${picH}h00 - ${picH + 1}h00`,
        topEcran,
        premierEcran,
      },
      tempsParMenu: tempsMenusDetails,
      heuresDistribution: heures,
      evenementsRecents: eventsRecents.map(e => ({
        id: e._id,
        typeEvenement: e.typeEvenement,
        ecran: e.ecran,
        ecranLibelle: LIBELLES_ECRANS[e.ecran] || e.ecran || '-',
        titreArticle: e.titreArticle || null,
        categorie: e.categorie || null,
        dureeSecondes: e.dureeSecondes,
        dureeFormattee: formaterDuree(e.dureeSecondes),
        date: e.date,
        dateRelatif: formaterTempsRelatif(e.date),
      })),
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/analytics/dashboard
// Page web interactive avec graphiques lucides Tailwind CSS + Chart.js
exports.rendrePageWebDashboard = (req, res) => {
  res.send(`<!DOCTYPE html>
<html lang="fr" class="dark">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AgriDigitale Analytics - Surveillance en Direct & Profilage Utilisateur</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
  <script>
    tailwind.config = {
      darkMode: 'class',
      theme: {
        extend: {
          colors: {
            brand: {
              50: '#ecfdf5',
              500: '#10b981',
              600: '#059669',
              700: '#047857',
              900: '#064e3b',
            }
          }
        }
      }
    }
  </script>
  <style>
    body { background-color: #0b1120; color: #f8fafc; font-family: system-ui, -apple-system, sans-serif; }
    .card { background-color: #1e293b; border: 1px solid #334155; border-radius: 1rem; }
    .glass { background: rgba(30, 41, 59, 0.7); backdrop-filter: blur(12px); border: 1px solid rgba(51, 65, 85, 0.6); }
    .glow-pulse { animation: pulseGlow 2s infinite; }
    @keyframes pulseGlow {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.5; transform: scale(1.08); }
    }
    .custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
    .custom-scroll::-webkit-scrollbar-track { background: #0f172a; }
    .custom-scroll::-webkit-scrollbar-thumb { background: #334155; border-radius: 3px; }
    .custom-scroll::-webkit-scrollbar-thumb:hover { background: #475569; }
  </style>
</head>
<body class="p-3 md:p-8 min-h-screen custom-scroll">
  <div class="max-w-7xl mx-auto space-y-6">

    <!-- En-tête Principal -->
    <header class="flex flex-col lg:flex-row lg:items-center justify-between gap-4 glass p-5 md:p-6 rounded-2xl border-emerald-500/30 shadow-xl">
      <div class="flex items-center gap-4">
        <div class="w-12 h-12 rounded-xl bg-gradient-to-tr from-emerald-600 to-teal-400 flex items-center justify-center text-2xl shadow-lg shadow-emerald-500/20">
          🌾
        </div>
        <div>
          <div class="flex items-center gap-2">
            <h1 class="text-xl md:text-2xl font-black text-white tracking-tight">AgriDigitale Analytics</h1>
            <span class="bg-emerald-500/20 text-emerald-400 text-xs px-2.5 py-0.5 rounded-full font-bold border border-emerald-500/30 flex items-center gap-1.5">
              <span class="w-2 h-2 rounded-full bg-emerald-400 glow-pulse"></span> TEMPS RÉEL
            </span>
          </div>
          <p class="text-slate-400 text-xs md:text-sm mt-0.5">Suivi en direct du temps d'écran par menu (Home, Météo, TV, Jeux) & profilage individuel</p>
        </div>
      </div>

      <!-- Contrôles et Actualisation -->
      <div class="flex flex-wrap items-center gap-2">
        <div class="flex items-center bg-slate-900/80 border border-slate-700 rounded-xl px-3 py-1.5 text-xs">
          <span class="text-slate-400 mr-2 flex items-center gap-1"><i class="fa-solid fa-rotate text-emerald-400"></i> Auto :</span>
          <select id="selectAutoRefresh" onchange="changerAutoRefresh()" class="bg-transparent text-emerald-400 font-semibold focus:outline-none cursor-pointer">
            <option value="0" class="bg-slate-900 text-white">Désactivé</option>
            <option value="10" selected class="bg-slate-900 text-white">10 sec</option>
            <option value="30" class="bg-slate-900 text-white">30 sec</option>
            <option value="60" class="bg-slate-900 text-white">1 min</option>
          </select>
        </div>

        <select id="selectPeriode" onchange="chargerTout()" class="bg-slate-900/80 border border-slate-700 rounded-xl px-3 py-2 text-xs md:text-sm text-slate-200 focus:outline-none focus:border-emerald-500">
          <option value="24h">Dernières 24 heures</option>
          <option value="7j">7 derniers jours</option>
          <option value="30j" selected>30 derniers jours</option>
          <option value="tout">Tout l'historique</option>
        </select>

        <button onclick="chargerTout()" class="bg-emerald-600 hover:bg-emerald-500 text-white px-3.5 py-2 rounded-xl text-xs md:text-sm font-semibold flex items-center gap-1.5 shadow-lg shadow-emerald-600/20 transition active:scale-95">
          <i class="fa-solid fa-arrows-rotate" id="iconeRefresh"></i> Actualiser
        </button>
      </div>
    </header>

    <!-- Barre de Navigation des 3 Onglets Principaux -->
    <nav class="flex border-b border-slate-800 space-x-2 md:space-x-4 overflow-x-auto pb-1">
      <button onclick="changerOngletVue('globale')" id="tabBtnGlobale" class="tab-btn px-4 py-3 rounded-xl font-bold text-sm flex items-center gap-2 border-b-2 border-emerald-500 text-emerald-400 bg-emerald-950/20 transition">
        <i class="fa-solid fa-chart-pie"></i> 1. Vue Globale & Menus
      </button>
      <button onclick="changerOngletVue('classement')" id="tabBtnClassement" class="tab-btn px-4 py-3 rounded-xl font-bold text-sm flex items-center gap-2 border-b-2 border-transparent text-slate-400 hover:text-slate-200 transition">
        <i class="fa-solid fa-trophy"></i> 2. Classement des Utilisateurs
      </button>
      <button onclick="changerOngletVue('inspecteur')" id="tabBtnInspecteur" class="tab-btn px-4 py-3 rounded-xl font-bold text-sm flex items-center gap-2 border-b-2 border-transparent text-slate-400 hover:text-slate-200 transition">
        <i class="fa-solid fa-user-astronaut"></i> 3. Inspecteur Utilisateur Spécifique
        <span id="badgeInspecteurId" class="hidden text-[10px] bg-indigo-500 text-white px-2 py-0.5 rounded-full font-mono"></span>
      </button>
    </nav>

    <!-- ========================================== -->
    <!-- ONGLET 1 : VUE GLOBALE & MENUS             -->
    <!-- ========================================== -->
    <main id="sectionVueGlobale" class="space-y-6">
      <!-- 4 KPIs Globaux -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <!-- Appareils Uniques -->
        <div class="card p-5 relative overflow-hidden">
          <div class="flex items-center justify-between text-slate-400">
            <span class="text-xs uppercase tracking-wider font-semibold">Appareils Uniques</span>
            <i class="fa-solid fa-mobile-screen-button text-emerald-400 text-lg"></i>
          </div>
          <div class="text-3xl font-black mt-2 text-white" id="kpiTotalAppareils">-</div>
          <div class="text-xs text-slate-400 mt-1 flex items-center gap-1.5">
            <i class="fa-solid fa-fingerprint text-emerald-400"></i> Téléphones installés
          </div>
          <div class="absolute -right-6 -bottom-6 w-20 h-20 bg-emerald-500/5 rounded-full pointer-events-none"></div>
        </div>

        <!-- En Direct Maintenant -->
        <div class="card p-5 relative overflow-hidden border-emerald-500/40 bg-gradient-to-br from-slate-900 to-emerald-950/20">
          <div class="flex items-center justify-between text-slate-400">
            <span class="text-xs uppercase tracking-wider font-bold text-emerald-400 flex items-center gap-1.5">
              <span class="w-2 h-2 rounded-full bg-emerald-400 glow-pulse"></span> En Direct
            </span>
            <i class="fa-solid fa-signal text-emerald-400 text-lg"></i>
          </div>
          <div class="text-3xl font-black mt-2 text-emerald-300 flex items-baseline gap-2">
            <span id="kpiEnLigne">-</span>
            <span class="text-xs font-normal text-slate-400">actifs (&lt; 2 min)</span>
          </div>
          <div class="text-[11px] text-slate-300 mt-1 truncate" id="kpiDetailEnLigne">
            Chargement...
          </div>
        </div>

        <!-- Temps d'Écran Cumulé -->
        <div class="card p-5 relative overflow-hidden">
          <div class="flex items-center justify-between text-slate-400">
            <span class="text-xs uppercase tracking-wider font-semibold">Temps d'Écran Total</span>
            <i class="fa-solid fa-clock text-amber-400 text-lg"></i>
          </div>
          <div class="text-3xl font-black mt-2 text-amber-300" id="kpiTempsTotal">-</div>
          <div class="text-xs text-slate-400 mt-1 flex items-center gap-1.5">
            <i class="fa-solid fa-hourglass-half text-amber-400"></i> Heures cumulées sur l'app
          </div>
        </div>

        <!-- Ouvertures de l'App & Pic -->
        <div class="card p-5 relative overflow-hidden">
          <div class="flex items-center justify-between text-slate-400">
            <span class="text-xs uppercase tracking-wider font-semibold">Lancements de l'App</span>
            <i class="fa-solid fa-bolt text-sky-400 text-lg"></i>
          </div>
          <div class="text-3xl font-black mt-2 text-sky-300" id="kpiTotalOuvertures">-</div>
          <div class="text-xs text-slate-400 mt-1 flex items-center gap-1.5">
            <i class="fa-solid fa-fire text-orange-400"></i> Heure de pic : <span id="kpiHeurePic" class="font-bold text-slate-200">-</span>
          </div>
        </div>
      </div>

      <!-- Graphiques Lucides : Menus & Heures de la Journée -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Temps Passé par Menu (Home, Météo, TV, Jeux) -->
        <div class="card p-5 flex flex-col justify-between">
          <div>
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-base font-bold text-white flex items-center gap-2">
                <i class="fa-solid fa-cubes text-emerald-400"></i> Répartition du Temps par Menu
              </h2>
              <span class="text-xs text-slate-400 bg-slate-800 px-2.5 py-1 rounded-md">Accueil vs Météo vs TV vs Jeux</span>
            </div>
            <div class="h-60 relative flex items-center justify-center">
              <canvas id="chartTempsMenus"></canvas>
            </div>
          </div>
          <!-- Barres de pourcentages et libellés sous le camembert -->
          <div class="grid grid-cols-2 sm:grid-cols-4 gap-2 mt-4 pt-4 border-t border-slate-800 text-xs" id="grilleDetailsMenus">
            <!-- Rempli en JS -->
          </div>
        </div>

        <!-- Heures d'Ouverture et d'Utilisation (0h à 23h) -->
        <div class="card p-5 flex flex-col justify-between">
          <div>
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-base font-bold text-white flex items-center gap-2">
                <i class="fa-solid fa-clock-rotate-left text-sky-400"></i> À Quelles Heures l'App est Utilisée ? (0h - 23h)
              </h2>
              <span class="text-xs text-slate-400 bg-slate-800 px-2.5 py-1 rounded-md">Heures d'affluence</span>
            </div>
            <div class="h-60">
              <canvas id="chartHeuresGlobal"></canvas>
            </div>
          </div>
          <div class="text-xs text-slate-400 mt-3 flex items-center justify-between">
            <span><i class="fa-solid fa-circle-info text-sky-400 mr-1"></i> Répartition des ouvertures & activités sur 24h</span>
            <span class="font-semibold text-emerald-400" id="textePicHeure">Pic d'activité détecté</span>
          </div>
        </div>
      </div>

      <!-- Graphiques : Première Action à l'ouverture & Évolution 14 jours -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Première Action à l'Ouverture -->
        <div class="card p-5">
          <h2 class="text-base font-bold text-white mb-2 flex items-center gap-2">
            <i class="fa-solid fa-compass text-amber-400"></i> 1ère Action à l'Ouverture
          </h2>
          <p class="text-xs text-slate-400 mb-4">Sur quel écran l'utilisateur commence dès qu'il lance l'application</p>
          <div class="h-56">
            <canvas id="chartPremiereAction"></canvas>
          </div>
        </div>

        <!-- Évolution de l'Engagement (14 jours) -->
        <div class="card p-5 lg:col-span-2">
          <h2 class="text-base font-bold text-white mb-2 flex items-center gap-2">
            <i class="fa-solid fa-chart-line text-emerald-400"></i> Évolution du Temps Passé & Appareils Actifs
          </h2>
          <p class="text-xs text-slate-400 mb-4">Tendance d'utilisation quotidienne cumulée sur les deux dernières semaines</p>
          <div class="h-56">
            <canvas id="chartEvolutionEngagement"></canvas>
          </div>
        </div>
      </div>
    </main>

    <!-- ========================================== -->
    <!-- ONGLET 2 : CLASSEMENT DES UTILISATEURS     -->
    <!-- ========================================== -->
    <main id="sectionVueClassement" class="hidden space-y-6">
      <div class="card p-5 md:p-6 space-y-4">
        <!-- En-tête Classement avec Filtres -->
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h2 class="text-lg font-bold text-white flex items-center gap-2">
              <i class="fa-solid fa-trophy text-amber-400"></i> Classement d'Activité & Temps Passé
            </h2>
            <p class="text-xs text-slate-400 mt-1">Identifiez qui passe le plus de temps et qui passe le moins de temps sur l'application</p>
          </div>

          <!-- Filtres de tri -->
          <div class="flex flex-wrap items-center gap-2">
            <button onclick="changerTriClassement('temps_desc')" id="btnTriTempsDesc" class="btn-tri px-3 py-1.5 rounded-lg text-xs font-semibold bg-emerald-600 text-white transition">
              <i class="fa-solid fa-arrow-down-wide-short"></i> Plus de temps (Max)
            </button>
            <button onclick="changerTriClassement('temps_asc')" id="btnTriTempsAsc" class="btn-tri px-3 py-1.5 rounded-lg text-xs font-semibold bg-slate-800 hover:bg-slate-700 text-slate-300 transition">
              <i class="fa-solid fa-arrow-up-short-wide"></i> Moins de temps (Min)
            </button>
            <button onclick="changerTriClassement('en_ligne')" id="btnTriEnLigne" class="btn-tri px-3 py-1.5 rounded-lg text-xs font-semibold bg-slate-800 hover:bg-slate-700 text-slate-300 transition">
              <span class="w-2 h-2 rounded-full bg-emerald-400 inline-block mr-1 glow-pulse"></span> En ligne maintenant
            </button>
          </div>
        </div>

        <!-- Recherche rapide -->
        <div class="relative">
          <i class="fa-solid fa-magnifying-glass absolute left-3.5 top-3 text-slate-400 text-xs"></i>
          <input type="text" id="inputRechercheClassement" oninput="filtrerClassementLocalement()" placeholder="Rechercher par ID appareil, nom utilisateur, email ou écran actif..." class="w-full bg-slate-900 border border-slate-700 rounded-xl pl-9 pr-4 py-2 text-xs md:text-sm text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500">
        </div>

        <!-- Table du Classement -->
        <div class="overflow-x-auto">
          <table class="w-full text-left text-sm">
            <thead class="text-xs uppercase text-slate-400 border-b border-slate-700">
              <tr>
                <th class="py-3 px-3">Rang</th>
                <th class="py-3 px-3">Utilisateur / Appareil</th>
                <th class="py-3 px-3">Statut en Direct</th>
                <th class="py-3 px-3 text-right">Temps Cumulé</th>
                <th class="py-3 px-3 text-center">Ouvertures</th>
                <th class="py-3 px-3">Sur quoi il passe le + de temps</th>
                <th class="py-3 px-3">1ère action</th>
                <th class="py-3 px-3 text-right">Action</th>
              </tr>
            </thead>
            <tbody id="tbodyClassement" class="divide-y divide-slate-800">
              <tr><td colspan="8" class="py-8 text-center text-slate-500">Chargement du classement...</td></tr>
            </tbody>
          </table>
        </div>
      </div>
    </main>

    <!-- ========================================== -->
    <!-- ONGLET 3 : INSPECTEUR UTILISATEUR          -->
    <!-- ========================================== -->
    <main id="sectionVueInspecteur" class="hidden space-y-6">
      <!-- Sélecteur d'appareil -->
      <div class="card p-5 flex flex-col md:flex-row md:items-center justify-between gap-4 border-indigo-500/30 bg-gradient-to-r from-slate-900 via-indigo-950/20 to-slate-900">
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 rounded-xl bg-indigo-600/30 border border-indigo-500/40 flex items-center justify-center text-indigo-400">
            <i class="fa-solid fa-user-gear text-lg"></i>
          </div>
          <div>
            <h2 class="text-base font-bold text-white">Inspecteur d'Utilisateur Spécifique</h2>
            <p class="text-xs text-slate-400">Analysez en profondeur le comportement, l'écran actuel et les habitudes d'un utilisateur</p>
          </div>
        </div>

        <div class="flex items-center gap-2">
          <select id="selectUtilisateurInspecte" onchange="surSelectionUtilisateur(this.value)" class="bg-slate-900 border border-indigo-500/40 rounded-xl px-4 py-2 text-xs md:text-sm text-indigo-300 font-mono focus:outline-none focus:border-indigo-400 max-w-xs truncate">
            <option value="">-- Choisir un utilisateur --</option>
          </select>
          <button onclick="rafraichirUtilisateurInspecte()" class="bg-indigo-600 hover:bg-indigo-500 text-white px-3.5 py-2 rounded-xl text-xs md:text-sm font-semibold flex items-center gap-1.5 transition">
            <i class="fa-solid fa-arrows-rotate"></i> Actualiser Fiche
          </button>
        </div>
      </div>

      <!-- Fiche Utilisateur (Affichée quand un utilisateur est sélectionné) -->
      <div id="conteneurFicheUtilisateur" class="space-y-6">
        <!-- Bandeau de Statut & Identité -->
        <div id="bandeauStatutPresence" class="card p-5 md:p-6 transition-all duration-300">
          <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div class="flex items-center gap-4">
              <div id="badgePastilleEnLigne" class="w-12 h-12 rounded-2xl flex items-center justify-center text-xl shadow-lg">
                <!-- Icône dynamique -->
              </div>
              <div>
                <div class="flex items-center gap-2">
                  <h3 id="nomUtilisateurInspecte" class="text-lg md:text-xl font-black text-white">Appareil</h3>
                  <span id="badgeEnLigneInspecte" class="text-xs px-2.5 py-0.5 rounded-full font-bold border">Statut</span>
                </div>
                <div class="text-xs text-slate-400 mt-1 flex flex-wrap items-center gap-3">
                  <span class="font-mono text-indigo-300" id="idDeviceComplet">-</span>
                  <span id="badgePlateforme" class="bg-slate-800 px-2 py-0.5 rounded text-[11px]">-</span>
                  <span id="derniereVueTexte"><i class="fa-regular fa-clock mr-1"></i> -</span>
                </div>
              </div>
            </div>

            <!-- Grand Indicateur Écran Actif -->
            <div class="bg-slate-900/90 border border-slate-700/80 rounded-2xl p-4 flex items-center gap-3 self-start md:self-auto">
              <div class="text-2xl" id="iconeEcranActuel">🏠</div>
              <div>
                <div class="text-[10px] uppercase font-bold tracking-wider text-slate-400">Écran en cours / Dernier écran</div>
                <div class="text-base font-extrabold text-white" id="libelleEcranActuel">Accueil</div>
              </div>
            </div>
          </div>
        </div>

        <!-- 4 KPIs Spécifiques à cet Utilisateur -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div class="card p-4">
            <div class="text-xs uppercase font-semibold text-slate-400 flex items-center justify-between">
              <span>Temps d'Écran Cumulé</span>
              <i class="fa-solid fa-stopwatch text-amber-400"></i>
            </div>
            <div class="text-2xl font-black text-amber-300 mt-2" id="kpiIndivTempsTotal">-</div>
            <div class="text-xs text-slate-400 mt-1" id="kpiIndivTempsDetail">-</div>
          </div>

          <div class="card p-4">
            <div class="text-xs uppercase font-semibold text-slate-400 flex items-center justify-between">
              <span>Ouvertures de l'App</span>
              <i class="fa-solid fa-door-open text-sky-400"></i>
            </div>
            <div class="text-2xl font-black text-sky-300 mt-2" id="kpiIndivOuvertures">-</div>
            <div class="text-xs text-slate-400 mt-1">Sessions distinctes lancées</div>
          </div>

          <div class="card p-4">
            <div class="text-xs uppercase font-semibold text-slate-400 flex items-center justify-between">
              <span>Menu Favori (Max Temps)</span>
              <i class="fa-solid fa-star text-purple-400"></i>
            </div>
            <div class="text-2xl font-black text-purple-300 mt-2" id="kpiIndivMenuFavori">-</div>
            <div class="text-xs text-slate-400 mt-1" id="kpiIndivMenuFavoriDetail">-</div>
          </div>

          <div class="card p-4">
            <div class="text-xs uppercase font-semibold text-slate-400 flex items-center justify-between">
              <span>1ère Action Favorite</span>
              <i class="fa-solid fa-bullseye text-emerald-400"></i>
            </div>
            <div class="text-2xl font-black text-emerald-300 mt-2" id="kpiIndivPremierEcran">-</div>
            <div class="text-xs text-slate-400 mt-1" id="kpiIndivPremierEcranDetail">-</div>
          </div>
        </div>

        <!-- Graphiques de l'Utilisateur : Temps par Menu & Heures d'activité -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <!-- Temps Passé par Menu pour cet Utilisateur -->
          <div class="card p-5">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-base font-bold text-white flex items-center gap-2">
                <i class="fa-solid fa-chart-column text-emerald-400"></i> Temps Passé par Menu (Cet Utilisateur)
              </h3>
              <span class="text-xs text-slate-400">Home vs Météo vs TV vs Jeux</span>
            </div>
            <div class="h-64">
              <canvas id="chartIndivMenus"></canvas>
            </div>
            <!-- Tableau récapitulatif des menus pour cet utilisateur -->
            <div class="mt-4 pt-3 border-t border-slate-800 space-y-2 text-xs" id="listeIndivMenusDetail">
              <!-- Rempli en JS -->
            </div>
          </div>

          <!-- Heures d'Ouverture & Utilisation pour cet Utilisateur (0h à 23h) -->
          <div class="card p-5">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-base font-bold text-white flex items-center gap-2">
                <i class="fa-solid fa-clock text-sky-400"></i> Heures d'Ouverture & d'Utilisation (0h - 23h)
              </h3>
              <span class="text-xs text-slate-400 font-semibold" id="picHeureIndiv">Pic : -</span>
            </div>
            <div class="h-64">
              <canvas id="chartIndivHeures"></canvas>
            </div>
            <p class="text-xs text-slate-400 mt-4 pt-3 border-t border-slate-800 flex items-center gap-1.5">
              <i class="fa-solid fa-lightbulb text-amber-400"></i> Permet de savoir à quel moment de la journée cet utilisateur utilise le plus l'application.
            </p>
          </div>
        </div>

        <!-- Journal / Timeline des Dernières Activités de cet Utilisateur -->
        <div class="card p-5">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-base font-bold text-white flex items-center gap-2">
              <i class="fa-solid fa-timeline text-indigo-400"></i> Historique Chronologique Récent (30 dernières actions)
            </h3>
            <span class="text-xs text-slate-400">Mises à jour en direct</span>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left text-xs md:text-sm">
              <thead class="text-xs uppercase text-slate-400 border-b border-slate-700">
                <tr>
                  <th class="py-2.5 px-3">Date & Heure</th>
                  <th class="py-2.5 px-3">Type d'Événement</th>
                  <th class="py-2.5 px-3">Écran / Menu</th>
                  <th class="py-2.5 px-3">Détail / Article</th>
                  <th class="py-2.5 px-3 text-right">Durée</th>
                </tr>
              </thead>
              <tbody id="tbodyHistoriqueIndiv" class="divide-y divide-slate-800 font-mono text-xs">
                <tr><td colspan="5" class="py-4 text-center text-slate-500 font-sans">Chargement de l'historique...</td></tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Message si aucun utilisateur sélectionné -->
      <div id="messageAucunUtilisateur" class="hidden card p-12 text-center text-slate-400 space-y-3">
        <div class="w-16 h-16 rounded-full bg-slate-800 mx-auto flex items-center justify-center text-2xl text-slate-500">
          <i class="fa-solid fa-user-slash"></i>
        </div>
        <h3 class="text-base font-bold text-slate-200">Aucun utilisateur sélectionné</h3>
        <p class="text-xs max-w-md mx-auto">Veuillez sélectionner un utilisateur dans le menu déroulant ci-dessus ou cliquer sur "Inspecter" depuis le classement.</p>
      </div>
    </main>

  </div>

  <!-- SCRIPT DU TABLEAU DE BORD -->
  <script>
    // Variables globales des instances Chart.js pour destruction propre lors du refresh
    let chartTempsMenusInst = null;
    let chartHeuresGlobalInst = null;
    let chartPremiereActionInst = null;
    let chartEvolutionInst = null;
    let chartIndivMenusInst = null;
    let chartIndivHeuresInst = null;

    let autoRefreshTimer = null;
    let tousLesUtilisateursEnCache = [];
    let deviceIdActuellementInspecte = null;

    const ICONES_ECRANS = {
      home: '🏠',
      meteo: '⛅',
      tv: '📺',
      jeux: '🎮',
      article: '📑',
      favoris: '🔖',
      parametres: '⚙️',
      autre: '📱'
    };

    // Gestion du basculement entre les 3 onglets principaux
    function changerOngletVue(vue) {
      document.getElementById('sectionVueGlobale').classList.add('hidden');
      document.getElementById('sectionVueClassement').classList.add('hidden');
      document.getElementById('sectionVueInspecteur').classList.add('hidden');

      ['tabBtnGlobale', 'tabBtnClassement', 'tabBtnInspecteur'].forEach(id => {
        const btn = document.getElementById(id);
        btn.classList.remove('border-emerald-500', 'text-emerald-400', 'bg-emerald-950/20');
        btn.classList.add('border-transparent', 'text-slate-400');
      });

      if (vue === 'globale') {
        document.getElementById('sectionVueGlobale').classList.remove('hidden');
        const b = document.getElementById('tabBtnGlobale');
        b.classList.add('border-emerald-500', 'text-emerald-400', 'bg-emerald-950/20');
        b.classList.remove('border-transparent', 'text-slate-400');
      } else if (vue === 'classement') {
        document.getElementById('sectionVueClassement').classList.remove('hidden');
        const b = document.getElementById('tabBtnClassement');
        b.classList.add('border-emerald-500', 'text-emerald-400', 'bg-emerald-950/20');
        b.classList.remove('border-transparent', 'text-slate-400');
        chargerClassement();
      } else if (vue === 'inspecteur') {
        document.getElementById('sectionVueInspecteur').classList.remove('hidden');
        const b = document.getElementById('tabBtnInspecteur');
        b.classList.add('border-emerald-500', 'text-emerald-400', 'bg-emerald-950/20');
        b.classList.remove('border-transparent', 'text-slate-400');
        if (deviceIdActuellementInspecte) {
          chargerFicheUtilisateur(deviceIdActuellementInspecte);
        } else if (tousLesUtilisateursEnCache.length > 0) {
          surSelectionUtilisateur(tousLesUtilisateursEnCache[0].deviceId);
        } else {
          document.getElementById('conteneurFicheUtilisateur').classList.add('hidden');
          document.getElementById('messageAucunUtilisateur').classList.remove('hidden');
        }
      }
    }

    // Ouvre directement l'inspecteur pour un deviceId donné
    function inspecterUtilisateur(deviceId) {
      deviceIdActuellementInspecte = deviceId;
      document.getElementById('selectUtilisateurInspecte').value = deviceId;
      const badge = document.getElementById('badgeInspecteurId');
      badge.innerText = '#' + String(deviceId).slice(-6).toUpperCase();
      badge.classList.remove('hidden');
      changerOngletVue('inspecteur');
      chargerFicheUtilisateur(deviceId);
    }

    // Gestion du timer de rafraîchissement automatique
    function changerAutoRefresh() {
      if (autoRefreshTimer) clearInterval(autoRefreshTimer);
      const delai = parseInt(document.getElementById('selectAutoRefresh').value, 10);
      if (delai > 0) {
        autoRefreshTimer = setInterval(() => {
          chargerToutSilencieusement();
        }, delai * 1000);
      }
    }

    // Charge toutes les données (avec rotation de l'icône)
    async function chargerTout() {
      const icone = document.getElementById('iconeRefresh');
      icone.classList.add('fa-spin');
      try {
        await Promise.all([
          chargerStatsGlobales(),
          chargerListeUtilisateurs(),
        ]);
        if (deviceIdActuellementInspecte) {
          await chargerFicheUtilisateur(deviceIdActuellementInspecte);
        }
      } finally {
        icone.classList.remove('fa-spin');
      }
    }

    async function chargerToutSilencieusement() {
      try {
        await Promise.all([
          chargerStatsGlobales(),
          chargerListeUtilisateurs(),
        ]);
        if (deviceIdActuellementInspecte) {
          await chargerFicheUtilisateur(deviceIdActuellementInspecte);
        }
      } catch (err) {
        console.warn('Erreur refresh silencieux:', err);
      }
    }

    // 1. CHARGEMENT DES STATS GLOBALES
    async function chargerStatsGlobales() {
      const periode = document.getElementById('selectPeriode').value;
      const res = await fetch('/api/analytics/stats?periode=' + periode);
      const data = await res.json();

      // KPIs
      document.getElementById('kpiTotalAppareils').innerText = data.kpis.totalAppareils.toLocaleString();
      document.getElementById('kpiEnLigne').innerText = data.kpis.enLigneActuellement.toLocaleString();
      document.getElementById('kpiTempsTotal').innerText = data.kpis.tempsTotalHeures + 'h';
      document.getElementById('kpiTotalOuvertures').innerText = data.kpis.totalOuvertures.toLocaleString();
      document.getElementById('kpiHeurePic').innerText = data.kpis.heurePic;

      // Détail en direct
      const det = data.kpis.detailEnLigne || {};
      const texteEnLigne = [];
      if (det.home > 0) texteEnLigne.push(\`\${det.home} sur Accueil 🏠\`);
      if (det.meteo > 0) texteEnLigne.push(\`\${det.meteo} sur Météo ⛅\`);
      if (det.tv > 0) texteEnLigne.push(\`\${det.tv} sur TV 📺\`);
      if (det.jeux > 0) texteEnLigne.push(\`\${det.jeux} sur Jeux 🎮\`);
      if (det.autre > 0) texteEnLigne.push(\`\${det.autre} sur Autres\`);
      document.getElementById('kpiDetailEnLigne').innerHTML = texteEnLigne.length > 0
        ? '<span class="text-emerald-400 font-semibold">' + texteEnLigne.join(' • ') + '</span>'
        : 'Aucun utilisateur en direct actuellement';

      document.getElementById('textePicHeure').innerText = 'Heure de pointe : ' + data.kpis.heurePic;

      // ─── Graphique Temps par Menu (Camembert/Donut) ───
      const ctxMenus = document.getElementById('chartTempsMenus').getContext('2d');
      if (chartTempsMenusInst) chartTempsMenusInst.destroy();
      chartTempsMenusInst = new Chart(ctxMenus, {
        type: 'doughnut',
        data: {
          labels: data.tempsParMenu.map(m => m.libelle),
          datasets: [{
            data: data.tempsParMenu.map(m => m.minutes),
            backgroundColor: data.tempsParMenu.map(m => m.couleur),
            borderWidth: 0,
            hoverOffset: 6
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: { position: 'right', labels: { color: '#cbd5e1', boxWidth: 12, font: { size: 11 } } },
            tooltip: {
              callbacks: {
                label: function(ctx) {
                  const m = data.tempsParMenu[ctx.dataIndex];
                  return \` \${m.libelle} : \${m.minutes} min (\${m.pourcentage}%)\`;
                }
              }
            }
          }
        }
      });

      // Grille sous le camembert
      const grilleMenus = document.getElementById('grilleDetailsMenus');
      grilleMenus.innerHTML = data.tempsParMenu.slice(0, 4).map(m => \`
        <div class="bg-slate-900/60 p-2.5 rounded-lg border border-slate-800">
          <div class="flex items-center gap-1.5 text-slate-400 font-medium">
            <span class="w-2.5 h-2.5 rounded-full" style="background-color: \${m.couleur}"></span>
            <span class="truncate">\${m.libelle}</span>
          </div>
          <div class="text-base font-bold text-white mt-1">\${m.formatte}</div>
          <div class="text-[10px] text-slate-400">\${m.pourcentage}% du temps</div>
        </div>
      \`).join('');

      // ─── Graphique Heures Globales (0h - 23h) ───
      const ctxHeures = document.getElementById('chartHeuresGlobal').getContext('2d');
      if (chartHeuresGlobalInst) chartHeuresGlobalInst.destroy();
      chartHeuresGlobalInst = new Chart(ctxHeures, {
        type: 'bar',
        data: {
          labels: Array.from({ length: 24 }, (_, i) => i + 'h'),
          datasets: [{
            label: 'Activités & Ouvertures',
            data: data.heuresDistribution,
            backgroundColor: data.heuresDistribution.map((_, h) => h === parseInt(data.kpis.heurePic, 10) ? '#10b981' : 'rgba(56, 189, 248, 0.4)'),
            borderColor: '#38bdf8',
            borderWidth: 1,
            borderRadius: 4,
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          scales: {
            x: { grid: { display: false }, ticks: { color: '#94a3b8', font: { size: 10 } } },
            y: { grid: { color: '#1e293b' }, ticks: { color: '#94a3b8', font: { size: 10 }, precision: 0 } }
          },
          plugins: {
            legend: { display: false },
            tooltip: {
              callbacks: {
                title: (items) => \`À \${items[0].label}00\`,
                label: (ctx) => \` \${ctx.raw} ouvertures / actions\`
              }
            }
          }
        }
      });

      // ─── Graphique Première Action ───
      const ctxPrem = document.getElementById('chartPremiereAction').getContext('2d');
      if (chartPremiereActionInst) chartPremiereActionInst.destroy();
      chartPremiereActionInst = new Chart(ctxPrem, {
        type: 'polarArea',
        data: {
          labels: data.premieresActions.map(p => p.libelle),
          datasets: [{
            data: data.premieresActions.map(p => p.occurrences),
            backgroundColor: data.premieresActions.map(p => p.couleur + '99'),
            borderWidth: 0,
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          scales: { r: { grid: { color: '#334155' }, ticks: { display: false } } },
          plugins: {
            legend: { position: 'bottom', labels: { color: '#cbd5e1', boxWidth: 10, font: { size: 10 } } }
          }
        }
      });

      // ─── Graphique Évolution 14 jours ───
      const ctxEvol = document.getElementById('chartEvolutionEngagement').getContext('2d');
      if (chartEvolutionInst) chartEvolutionInst.destroy();
      chartEvolutionInst = new Chart(ctxEvol, {
        type: 'line',
        data: {
          labels: data.evolutionJours.map(j => j.jour.slice(5)),
          datasets: [
            {
              label: 'Minutes d\\'écran cumulées',
              data: data.evolutionJours.map(j => j.tempsMinutes),
              borderColor: '#10b981',
              backgroundColor: 'rgba(16, 185, 129, 0.1)',
              tension: 0.35,
              fill: true,
            },
            {
              label: 'Appareils actifs',
              data: data.evolutionJours.map(j => j.appareilsActifs),
              borderColor: '#38bdf8',
              borderDash: [3, 3],
              tension: 0.35,
              yAxisID: 'y1',
            }
          ]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          scales: {
            x: { grid: { color: '#1e293b' }, ticks: { color: '#94a3b8', font: { size: 10 } } },
            y: { grid: { color: '#1e293b' }, ticks: { color: '#94a3b8', font: { size: 10 } } },
            y1: { position: 'right', grid: { drawOnChartArea: false }, ticks: { color: '#38bdf8', font: { size: 10 } } }
          },
          plugins: { legend: { labels: { color: '#cbd5e1', boxWidth: 12 } } }
        }
      });
    }

    // 2. CHARGEMENT DE LA LISTE DES UTILISATEURS (Pour selecteur & classement)
    async function chargerListeUtilisateurs() {
      const res = await fetch('/api/analytics/users?limite=100');
      const data = await res.json();
      tousLesUtilisateursEnCache = data.users || [];

      // Mettre à jour le sélecteur déroulant de l'inspecteur
      const select = document.getElementById('selectUtilisateurInspecte');
      const valActuelle = select.value;
      select.innerHTML = '<option value="">-- Choisir un utilisateur --</option>' +
        tousLesUtilisateursEnCache.map(u => {
          const statut = u.estEnLigne ? '🟢 [EN DIRECT]' : '⚪';
          const nom = u.nomUtilisateur ? \`\${u.nomUtilisateur} (\${u.deviceIdCourt})\` : u.deviceIdCourt;
          return \`<option value="\${u.deviceId}">\${statut} \${nom} - \${u.tempsTotalFormatte}</option>\`;
        }).join('');

      if (valActuelle) select.value = valActuelle;

      // Si classement est affiché, le rafraîchir
      if (!document.getElementById('sectionVueClassement').classList.contains('hidden')) {
        afficherTableClassement(tousLesUtilisateursEnCache);
      }
    }

    // 3. CHARGEMENT ET AFFICHAGE DU CLASSEMENT
    let triClassementActuel = 'temps_desc';

    async function changerTriClassement(tri) {
      triClassementActuel = tri;
      ['btnTriTempsDesc', 'btnTriTempsAsc', 'btnTriEnLigne'].forEach(id => {
        const btn = document.getElementById(id);
        btn.classList.remove('bg-emerald-600', 'text-white');
        btn.classList.add('bg-slate-800', 'text-slate-300');
      });

      if (tri === 'temps_desc') {
        const b = document.getElementById('btnTriTempsDesc');
        b.classList.add('bg-emerald-600', 'text-white');
        b.classList.remove('bg-slate-800', 'text-slate-300');
      } else if (tri === 'temps_asc') {
        const b = document.getElementById('btnTriTempsAsc');
        b.classList.add('bg-emerald-600', 'text-white');
        b.classList.remove('bg-slate-800', 'text-slate-300');
      } else if (tri === 'en_ligne') {
        const b = document.getElementById('btnTriEnLigne');
        b.classList.add('bg-emerald-600', 'text-white');
        b.classList.remove('bg-slate-800', 'text-slate-300');
      }

      await chargerClassement();
    }

    async function chargerClassement() {
      const q = document.getElementById('inputRechercheClassement').value.trim();
      const res = await fetch(\`/api/analytics/users?tri=\${triClassementActuel}&q=\${encodeURIComponent(q)}&limite=100\`);
      const data = await res.json();
      afficherTableClassement(data.users || []);
    }

    function filtrerClassementLocalement() {
      chargerClassement();
    }

    function afficherTableClassement(users) {
      const tbody = document.getElementById('tbodyClassement');
      if (users.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" class="py-8 text-center text-slate-500">Aucun appareil trouvé avec ces critères</td></tr>';
        return;
      }

      tbody.innerHTML = users.map((u, i) => {
        const estTop3 = u.rang <= 3;
        const medaille = u.rang === 1 ? '🥇' : (u.rang === 2 ? '🥈' : (u.rang === 3 ? '🥉' : '#' + u.rang));

        const badgeStatut = u.estEnLigne
          ? \`<span class="bg-emerald-950/80 text-emerald-400 border border-emerald-500/40 px-2.5 py-1 rounded-full text-xs font-bold flex items-center gap-1.5 w-max">
               <span class="w-2 h-2 rounded-full bg-emerald-400 glow-pulse"></span> Sur \${u.ecranActifLibelle}
             </span>\`
          : \`<span class="text-slate-400 text-xs flex items-center gap-1">
               <span class="w-2 h-2 rounded-full bg-slate-600"></span> \${u.derniereActiviteFormatte}
             </span>\`;

        return \`
          <tr class="hover:bg-slate-800/60 transition cursor-pointer" onclick="inspecterUtilisateur('\${u.deviceId}')">
            <td class="py-3 px-3 font-bold \${estTop3 ? 'text-amber-400 text-base' : 'text-slate-400'}">\${medaille}</td>
            <td class="py-3 px-3">
              <div class="font-bold text-slate-200">\${u.nomUtilisateur || u.deviceIdCourt}</div>
              <div class="text-[11px] font-mono text-slate-400">\${u.deviceId}</div>
              \${u.emailUtilisateur ? \`<div class="text-[11px] text-sky-400">\${u.emailUtilisateur}</div>\` : ''}
            </td>
            <td class="py-3 px-3">\${badgeStatut}</td>
            <td class="py-3 px-3 text-right font-black text-amber-300 text-sm">\${u.tempsTotalFormatte}</td>
            <td class="py-3 px-3 text-center font-semibold text-slate-300">\${u.nombreOuvertures}</td>
            <td class="py-3 px-3">
              <span class="bg-slate-800 text-purple-300 px-2.5 py-1 rounded-lg text-xs font-medium border border-purple-500/30">
                \${ICONES_ECRANS[u.topEcran.ecran] || '📱'} \${u.topEcran.libelle} (\${u.topEcran.pourcentage}%)
              </span>
            </td>
            <td class="py-3 px-3 text-xs text-slate-300">
              \${ICONES_ECRANS[u.premierEcran.ecran] || '🚪'} \${u.premierEcran.libelle}
            </td>
            <td class="py-3 px-3 text-right">
              <button onclick="event.stopPropagation(); inspecterUtilisateur('\${u.deviceId}')" class="bg-indigo-600/80 hover:bg-indigo-600 text-white px-3 py-1 rounded-lg text-xs font-semibold flex items-center gap-1 ml-auto shadow transition">
                <i class="fa-solid fa-magnifying-glass"></i> Inspecter
              </button>
            </td>
          </tr>
        \`;
      }).join('');
    }

    // 4. CHARGEMENT DE LA FICHE DÉTAILLÉE D'UN UTILISATEUR
    function surSelectionUtilisateur(deviceId) {
      if (!deviceId) return;
      deviceIdActuellementInspecte = deviceId;
      document.getElementById('selectUtilisateurInspecte').value = deviceId;
      const badge = document.getElementById('badgeInspecteurId');
      badge.innerText = '#' + String(deviceId).slice(-6).toUpperCase();
      badge.classList.remove('hidden');
      chargerFicheUtilisateur(deviceId);
    }

    function rafraichirUtilisateurInspecte() {
      if (deviceIdActuellementInspecte) {
        chargerFicheUtilisateur(deviceIdActuellementInspecte);
      }
    }

    async function chargerFicheUtilisateur(deviceId) {
      document.getElementById('conteneurFicheUtilisateur').classList.remove('hidden');
      document.getElementById('messageAucunUtilisateur').classList.add('hidden');

      const res = await fetch('/api/analytics/user/' + deviceId);
      if (!res.ok) {
        alert('Impossible de charger les données de cet utilisateur');
        return;
      }
      const data = await res.json();
      const app = data.appareil;
      const kpi = data.kpis;

      // Bandeau de présence
      const bandeau = document.getElementById('bandeauStatutPresence');
      const pastille = document.getElementById('badgePastilleEnLigne');
      const badgeEnLigne = document.getElementById('badgeEnLigneInspecte');

      document.getElementById('nomUtilisateurInspecte').innerText = app.nomUtilisateur !== 'Visiteur non identifié'
        ? \`\${app.nomUtilisateur} (\${app.deviceIdCourt})\`
        : app.deviceIdCourt;
      document.getElementById('idDeviceComplet').innerText = app.deviceId;
      document.getElementById('badgePlateforme').innerText = (app.plateforme || 'android').toUpperCase();
      document.getElementById('derniereVueTexte').innerHTML = \`<i class="fa-regular fa-clock mr-1"></i> Dernière vue : \${app.derniereActiviteFormatte}\`;

      document.getElementById('iconeEcranActuel').innerText = ICONES_ECRANS[app.ecranActif] || '📱';
      document.getElementById('libelleEcranActuel').innerText = app.ecranActifLibelle;

      if (app.estEnLigne) {
        bandeau.className = 'card p-5 md:p-6 border-emerald-500/60 bg-gradient-to-r from-slate-900 via-emerald-950/30 to-slate-900 shadow-xl shadow-emerald-500/10';
        pastille.className = 'w-12 h-12 rounded-2xl bg-emerald-500/20 border border-emerald-500/40 text-emerald-400 flex items-center justify-center text-xl glow-pulse';
        pastille.innerHTML = '<i class="fa-solid fa-signal"></i>';
        badgeEnLigne.className = 'text-xs px-2.5 py-0.5 rounded-full font-bold bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 flex items-center gap-1.5';
        badgeEnLigne.innerHTML = '<span class="w-2 h-2 rounded-full bg-emerald-400 glow-pulse"></span> EN DIRECT SUR L\\'ÉCRAN';
      } else {
        bandeau.className = 'card p-5 md:p-6 border-slate-700 bg-slate-900/60';
        pastille.className = 'w-12 h-12 rounded-2xl bg-slate-800 text-slate-400 flex items-center justify-center text-xl';
        pastille.innerHTML = '<i class="fa-solid fa-moon"></i>';
        badgeEnLigne.className = 'text-xs px-2.5 py-0.5 rounded-full font-semibold bg-slate-800 text-slate-400 border border-slate-700';
        badgeEnLigne.innerHTML = '⚪ Hors ligne';
      }

      // KPIs Individuels
      document.getElementById('kpiIndivTempsTotal').innerText = kpi.tempsTotalFormatte;
      document.getElementById('kpiIndivTempsDetail').innerText = \`Soit env. \${kpi.tempsTotalMinutes} minutes au total\`;
      document.getElementById('kpiIndivOuvertures').innerText = kpi.nombreOuvertures + ' fois';
      document.getElementById('kpiIndivMenuFavori').innerText = kpi.topEcran.libelle;
      document.getElementById('kpiIndivMenuFavoriDetail').innerText = \`\${kpi.topEcran.minutes} min passées (\${kpi.topEcran.pourcentage}% du total)\`;
      document.getElementById('kpiIndivPremierEcran').innerText = kpi.premierEcran.libelle;
      document.getElementById('kpiIndivPremierEcranDetail').innerText = \`Ouvert en 1er dans \${kpi.premierEcran.pourcentage}% des cas\`;

      document.getElementById('picHeureIndiv').innerText = 'Heure de pic : ' + kpi.heurePic;

      // ─── Graphique Temps par Menu pour cet Utilisateur ───
      const ctxIndivMenus = document.getElementById('chartIndivMenus').getContext('2d');
      if (chartIndivMenusInst) chartIndivMenusInst.destroy();
      chartIndivMenusInst = new Chart(ctxIndivMenus, {
        type: 'bar',
        data: {
          labels: data.tempsParMenu.map(m => m.libelle),
          datasets: [{
            label: 'Minutes passées',
            data: data.tempsParMenu.map(m => m.minutes),
            backgroundColor: data.tempsParMenu.map(m => m.couleur),
            borderRadius: 6,
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          indexAxis: 'y',
          scales: {
            x: { grid: { color: '#334155' }, ticks: { color: '#94a3b8' } },
            y: { grid: { display: false }, ticks: { color: '#cbd5e1', font: { weight: 'bold' } } }
          },
          plugins: {
            legend: { display: false },
            tooltip: {
              callbacks: {
                label: (ctx) => {
                  const m = data.tempsParMenu[ctx.dataIndex];
                  return \` \${m.formatte} (\${m.pourcentage}% du temps de cet utilisateur)\`;
                }
              }
            }
          }
        }
      });

      // Liste récapitulatif sous le graphique
      const divListeMenus = document.getElementById('listeIndivMenusDetail');
      divListeMenus.innerHTML = data.tempsParMenu.map(m => \`
        <div class="flex items-center justify-between py-1">
          <div class="flex items-center gap-2">
            <span class="w-3 h-3 rounded-full" style="background-color: \${m.couleur}"></span>
            <span class="font-medium text-slate-200">\${m.libelle}</span>
          </div>
          <div class="flex items-center gap-3">
            <span class="font-bold text-white">\${m.formatte}</span>
            <span class="text-slate-400 w-12 text-right">\${m.pourcentage}%</span>
          </div>
        </div>
      \`).join('');

      // ─── Graphique Heures Utilisateur (0h - 23h) ───
      const ctxIndivH = document.getElementById('chartIndivHeures').getContext('2d');
      if (chartIndivHeuresInst) chartIndivHeuresInst.destroy();
      chartIndivHeuresInst = new Chart(ctxIndivH, {
        type: 'bar',
        data: {
          labels: Array.from({ length: 24 }, (_, i) => i + 'h'),
          datasets: [{
            label: 'Activités / Heure',
            data: data.heuresDistribution,
            backgroundColor: 'rgba(56, 189, 248, 0.4)',
            borderColor: '#38bdf8',
            borderWidth: 1,
            borderRadius: 4,
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          scales: {
            x: { grid: { display: false }, ticks: { color: '#94a3b8', font: { size: 10 } } },
            y: { grid: { color: '#1e293b' }, ticks: { color: '#94a3b8', font: { size: 10 }, precision: 0 } }
          },
          plugins: { legend: { display: false } }
        }
      });

      // ─── Timeline / Journal Récent ───
      const tbodyHist = document.getElementById('tbodyHistoriqueIndiv');
      if (data.evenementsRecents.length === 0) {
        tbodyHist.innerHTML = '<tr><td colspan="5" class="py-4 text-center text-slate-500 font-sans">Aucun événement enregistré récemment</td></tr>';
      } else {
        tbodyHist.innerHTML = data.evenementsRecents.map(e => \`
          <tr class="hover:bg-slate-800/40">
            <td class="py-2 px-3 text-slate-400 whitespace-nowrap">\${e.dateRelatif}</td>
            <td class="py-2 px-3 font-semibold text-indigo-300">\${e.typeEvenement}</td>
            <td class="py-2 px-3 text-slate-200">\${e.ecranLibelle}</td>
            <td class="py-2 px-3 text-slate-400 truncate max-w-xs">\${e.titreArticle || '-'}</td>
            <td class="py-2 px-3 text-right font-bold text-amber-300">\${e.dureeFormattee}</td>
          </tr>
        \`).join('');
      }
    }

    // Gestion du paramètre URL deviceId à l'ouverture de la page
    document.addEventListener('DOMContentLoaded', async () => {
      changerAutoRefresh();
      await chargerTout();

      const params = new URLSearchParams(window.location.search);
      const urlDeviceId = params.get('deviceId');
      if (urlDeviceId) {
        inspecterUtilisateur(urlDeviceId);
      }
    });
  </script>
</body>
</html>`);
};
