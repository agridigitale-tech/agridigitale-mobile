// Contrôleur de Télémétrie & Analytics (Calcul du temps d'écran & profilage intelligent)
const Analytics = require('../models/Analytics');

// POST /api/analytics/track
// Reçoit un événement ou une liste d'événements de télémétrie en arrière-plan
exports.track = async (req, res, next) => {
  try {
    const data = req.body;
    if (!data) return res.status(400).json({ message: 'Données manquantes' });

    // Permet l'envoi d'un événement unique ou d'un tableau d'événements groupés
    const events = Array.isArray(data) ? data : [data];

    const docs = events
      .filter(e => e && e.deviceId && e.typeEvenement)
      .map(e => ({
        deviceId: String(e.deviceId).trim(),
        utilisateurId: req.utilisateurId || e.utilisateurId || null,
        typeEvenement: e.typeEvenement,
        articleId: e.articleId || null,
        titreArticle: e.titreArticle || null,
        categorie: e.categorie || 'Général',
        dureeSecondes: Math.max(0, Number(e.dureeSecondes || e.tempsPasseSecondes) || 0),
        pourcentageLecture: Number(e.pourcentageLecture || 0),
        plateforme: e.plateforme || 'inconnu',
        date: e.date ? new Date(e.date) : new Date(),
      }));

    if (docs.length > 0) {
      await Analytics.insertMany(docs, { ordered: false });
    }

    // Réponse immédiate et légère
    res.status(202).json({ success: true, count: docs.length });
  } catch (err) {
    // La télémétrie ne doit jamais faire planter l'application
    res.status(202).json({ success: false, error: err.message });
  }
};

// GET /api/analytics/stats
// Calcule les statistiques d'audience, de temps passé et de profilage des appareils
exports.getStats = async (req, res, next) => {
  try {
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
      dateDebut = new Date(0); // Depuis le début
    }

    const matchFiltre = { date: { $gte: dateDebut } };

    // 1. Calculs agrégés en parallèle ultra-optimisés
    const [
      totalAppareilsDistincts,
      kpisTemps,
      tempsParCategorie,
      topArticles,
      topAppareils,
      evolutionJours,
    ] = await Promise.all([
      // Appareils actifs uniques
      Analytics.distinct('deviceId', matchFiltre),

      // Temps total et nombre d'événements
      Analytics.aggregate([
        { $match: matchFiltre },
        {
          $group: {
            _id: null,
            tempsTotalSecondes: { $sum: '$dureeSecondes' },
            totalLecturesArticles: {
              $sum: { $cond: [{ $eq: ['$typeEvenement', 'article_lecture'] }, 1, 0] },
            },
            totalSessions: {
              $sum: { $cond: [{ $eq: ['$typeEvenement', 'session'] }, 1, 0] },
            },
          },
        },
      ]),

      // Répartition du temps par catégorie (pour camembert)
      Analytics.aggregate([
        { $match: { ...matchFiltre, categorie: { $ne: null } } },
        {
          $group: {
            _id: '$categorie',
            tempsSecondes: { $sum: '$dureeSecondes' },
            lectures: { $sum: 1 },
          },
        },
        { $sort: { tempsSecondes: -1 } },
        { $limit: 10 },
      ]),

      // Articles les plus captivants (temps moyen et total passé)
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
        { $limit: 15 },
      ]),

      // Profils fantômes des appareils (Top appareils et goûts identifiés)
      Analytics.aggregate([
        { $match: matchFiltre },
        {
          $group: {
            _id: '$deviceId',
            tempsTotalSecondes: { $sum: '$dureeSecondes' },
            articlesLus: {
              $sum: { $cond: [{ $eq: ['$typeEvenement', 'article_lecture'] }, 1, 0] },
            },
            derniereActivite: { $max: '$date' },
            categories: { $push: '$categorie' },
          },
        },
        { $sort: { tempsTotalSecondes: -1 } },
        { $limit: 20 },
      ]),

      // Évolution du temps passé par jour (sur 14 jours)
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
    ]);

    // Extraction des goûts dominants par appareil (algorithme style TikTok)
    const profilsFormates = topAppareils.map((app) => {
      const counts = {};
      (app.categories || []).forEach((c) => {
        if (c && c !== 'Général') counts[c] = (counts[c] || 0) + 1;
      });
      const topCat = Object.entries(counts).sort((a, b) => b[1] - a[1])[0];

      return {
        deviceId: app._id,
        deviceIdCourt: 'Appareil #' + String(app._id).slice(-6).toUpperCase(),
        tempsTotalSecondes: app.tempsTotalSecondes,
        tempsTotalMinutes: Math.round(app.tempsTotalSecondes / 60),
        articlesLus: app.articlesLus,
        derniereActivite: app.derniereActivite,
        centreInteretPrincipal: topCat ? topCat[0] : 'Divers',
      };
    });

    const kpi = kpisTemps[0] || {
      tempsTotalSecondes: 0,
      totalLecturesArticles: 0,
      totalSessions: 0,
    };

    res.json({
      kpis: {
        totalAppareils: totalAppareilsDistincts.length,
        tempsTotalSecondes: kpi.tempsTotalSecondes,
        tempsTotalHeures: (kpi.tempsTotalSecondes / 3600).toFixed(1),
        tempsMoyenSessionSecondes: kpi.totalSessions > 0
          ? Math.round(kpi.tempsTotalSecondes / kpi.totalSessions)
          : Math.round(kpi.tempsTotalSecondes / Math.max(1, totalAppareilsDistincts.length)),
        totalLecturesArticles: kpi.totalLecturesArticles,
      },
      tempsParCategorie: tempsParCategorie.map((c) => ({
        categorie: c._id || 'Autre',
        tempsSecondes: c.tempsSecondes,
        tempsMinutes: Math.round(c.tempsSecondes / 60),
        lectures: c.lectures,
      })),
      topArticles: topArticles.map((a) => ({
        id: a._id,
        titre: a.titre || 'Article sans titre',
        categorie: a.categorie || 'Général',
        tempsTotalMinutes: (a.tempsTotalSecondes / 60).toFixed(1),
        tempsMoyenSecondes: Math.round(a.tempsMoyenSecondes || 0),
        lectures: a.lectures,
      })),
      profilsAppareils: profilsFormates,
      evolutionJours: evolutionJours.map((j) => ({
        jour: j._id,
        tempsMinutes: Math.round(j.tempsTotalSecondes / 60),
        appareilsActifs: (j.utilisateursActifs || []).length,
      })),
    });
  } catch (err) {
    next(err);
  }
};

// GET /admin/dashboard (Page web dédiée ultra-légère pour ordinateur/tablette)
exports.rendrePageWebDashboard = (req, res) => {
  res.send(`<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AgriDigitale - Tableau de bord Audience & Temps d'écran</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
  <style>
    body { background-color: #0f172a; color: #f8fafc; font-family: system-ui, -apple-system, sans-serif; }
    .card { background-color: #1e293b; border: 1px solid #334155; border-radius: 1rem; }
  </style>
</head>
<body class="p-4 md:p-8 min-h-screen">
  <div class="max-w-7xl mx-auto space-y-6">
    <!-- En-tête -->
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 card p-6 border-emerald-500/30">
      <div>
        <div class="flex items-center gap-3">
          <span class="text-3xl">🌾</span>
          <h1 class="text-2xl font-bold text-emerald-400">AgriDigitale Analytics</h1>
        </div>
        <p class="text-slate-400 text-sm mt-1">Surveillance du temps d'écran & profilage algorithmique par appareil (sans compte)</p>
      </div>
      <div class="flex items-center gap-2">
        <select id="selectPeriode" onchange="chargerStats()" class="bg-slate-800 border border-slate-600 rounded-lg px-4 py-2 text-sm focus:outline-none focus:border-emerald-500">
          <option value="24h">Dernières 24 heures</option>
          <option value="7j">7 derniers jours</option>
          <option value="30j" selected>30 derniers jours</option>
          <option value="tout">Tout l'historique</option>
        </select>
        <button onclick="chargerStats()" class="bg-emerald-600 hover:bg-emerald-500 px-4 py-2 rounded-lg text-sm font-semibold flex items-center gap-2 transition">
          <i class="fa-solid fa-arrows-rotate"></i> Actualiser
        </button>
      </div>
    </div>

    <!-- KPIs -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      <div class="card p-5">
        <div class="flex items-center justify-between text-slate-400">
          <span class="text-xs uppercase tracking-wider font-semibold">Appareils Uniques</span>
          <i class="fa-solid fa-mobile-screen-button text-emerald-400"></i>
        </div>
        <div class="text-3xl font-extrabold mt-2 text-white" id="kpiAppareils">-</div>
        <div class="text-xs text-slate-400 mt-1">Profils fantômes actifs</div>
      </div>
      <div class="card p-5">
        <div class="flex items-center justify-between text-slate-400">
          <span class="text-xs uppercase tracking-wider font-semibold">Temps d'écran Cumulé</span>
          <i class="fa-solid fa-clock text-amber-400"></i>
        </div>
        <div class="text-3xl font-extrabold mt-2 text-amber-300" id="kpiTempsTotal">-</div>
        <div class="text-xs text-slate-400 mt-1">Heures passées sur l'app</div>
      </div>
      <div class="card p-5">
        <div class="flex items-center justify-between text-slate-400">
          <span class="text-xs uppercase tracking-wider font-semibold">Articles Lus</span>
          <i class="fa-solid fa-newspaper text-sky-400"></i>
        </div>
        <div class="text-3xl font-extrabold mt-2 text-sky-300" id="kpiLectures">-</div>
        <div class="text-xs text-slate-400 mt-1">Consultations détaillées</div>
      </div>
      <div class="card p-5">
        <div class="flex items-center justify-between text-slate-400">
          <span class="text-xs uppercase tracking-wider font-semibold">Temps Moyen / Session</span>
          <i class="fa-solid fa-stopwatch text-purple-400"></i>
        </div>
        <div class="text-3xl font-extrabold mt-2 text-purple-300" id="kpiTempsMoyen">-</div>
        <div class="text-xs text-slate-400 mt-1">Par utilisateur actif</div>
      </div>
    </div>

    <!-- Graphiques -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Évolution du temps d'écran -->
      <div class="card p-5 lg:col-span-2">
        <h2 class="text-lg font-bold mb-4 flex items-center gap-2">
          <i class="fa-solid fa-chart-line text-emerald-400"></i> Évolution de l'engagement (14 derniers jours)
        </h2>
        <div class="h-64">
          <canvas id="chartEvolution"></canvas>
        </div>
      </div>

      <!-- Répartition par Catégorie -->
      <div class="card p-5">
        <h2 class="text-lg font-bold mb-4 flex items-center gap-2">
          <i class="fa-solid fa-chart-pie text-amber-400"></i> Goûts & Thèmes les plus captivants
        </h2>
        <div class="h-64 flex items-center justify-center">
          <canvas id="chartCategories"></canvas>
        </div>
      </div>
    </div>

    <!-- Tables de données -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Top Articles -->
      <div class="card p-5">
        <h2 class="text-lg font-bold mb-4 flex items-center gap-2">
          <i class="fa-solid fa-fire text-orange-400"></i> Articles sur lesquels les lecteurs restent le plus
        </h2>
        <div class="overflow-x-auto">
          <table class="w-full text-left text-sm">
            <thead class="text-xs uppercase text-slate-400 border-b border-slate-700">
              <tr>
                <th class="pb-2">Titre</th>
                <th class="pb-2">Catégorie</th>
                <th class="pb-2 text-right">Lectures</th>
                <th class="pb-2 text-right">Durée moy.</th>
              </tr>
            </thead>
            <tbody id="tableTopArticles" class="divide-y divide-slate-800">
              <tr><td colspan="4" class="py-4 text-center text-slate-500">Chargement...</td></tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Profils Fantômes (Style TikTok) -->
      <div class="card p-5">
        <h2 class="text-lg font-bold mb-4 flex items-center gap-2">
          <i class="fa-solid fa-user-secret text-indigo-400"></i> Profils Fantômes (Activité & Goûts par Device ID)
        </h2>
        <div class="overflow-x-auto">
          <table class="w-full text-left text-sm">
            <thead class="text-xs uppercase text-slate-400 border-b border-slate-700">
              <tr>
                <th class="pb-2">Appareil</th>
                <th class="pb-2">Intérêt Dominant</th>
                <th class="pb-2 text-right">Articles</th>
                <th class="pb-2 text-right">Temps d'écran</th>
              </tr>
            </thead>
            <tbody id="tableProfilsAppareils" class="divide-y divide-slate-800">
              <tr><td colspan="4" class="py-4 text-center text-slate-500">Chargement...</td></tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>

  <script>
    let chartEvolutionInstance = null;
    let chartCategoriesInstance = null;

    async function chargerStats() {
      const periode = document.getElementById('selectPeriode').value;
      try {
        const res = await fetch('/api/analytics/stats?periode=' + periode);
        const data = await res.json();

        // KPIs
        document.getElementById('kpiAppareils').innerText = data.kpis.totalAppareils.toLocaleString();
        document.getElementById('kpiTempsTotal').innerText = data.kpis.tempsTotalHeures + 'h';
        document.getElementById('kpiLectures').innerText = data.kpis.totalLecturesArticles.toLocaleString();
        const mins = Math.floor(data.kpis.tempsMoyenSessionSecondes / 60);
        const secs = data.kpis.tempsMoyenSessionSecondes % 60;
        document.getElementById('kpiTempsMoyen').innerText = mins + 'm ' + secs + 's';

        // Table Top Articles
        const tbodyArticles = document.getElementById('tableTopArticles');
        if (data.topArticles.length === 0) {
          tbodyArticles.innerHTML = '<tr><td colspan="4" class="py-4 text-center text-slate-500">Aucune donnée sur cette période</td></tr>';
        } else {
          tbodyArticles.innerHTML = data.topArticles.map(a => \`
            <tr class="hover:bg-slate-800/50">
              <td class="py-2.5 pr-2 font-medium text-slate-200 truncate max-w-xs">\${a.titre}</td>
              <td class="py-2.5 text-xs text-emerald-400"><span class="bg-emerald-950/60 px-2 py-0.5 rounded border border-emerald-800/50">\${a.categorie}</span></td>
              <td class="py-2.5 text-right font-semibold text-slate-300">\${a.lectures}</td>
              <td class="py-2.5 text-right font-semibold text-amber-300">\${a.tempsMoyenSecondes}s</td>
            </tr>
          \`).join('');
        }

        // Table Profils Appareils
        const tbodyAppareils = document.getElementById('tableProfilsAppareils');
        if (data.profilsAppareils.length === 0) {
          tbodyAppareils.innerHTML = '<tr><td colspan="4" class="py-4 text-center text-slate-500">Aucun appareil enregistré</td></tr>';
        } else {
          tbodyAppareils.innerHTML = data.profilsAppareils.map(p => \`
            <tr class="hover:bg-slate-800/50">
              <td class="py-2.5 font-mono text-xs text-indigo-300">\${p.deviceIdCourt}</td>
              <td class="py-2.5 text-xs text-sky-400 font-medium"><i class="fa-solid fa-tag text-[10px] mr-1"></i>\${p.centreInteretPrincipal}</td>
              <td class="py-2.5 text-right font-semibold text-slate-300">\${p.articlesLus}</td>
              <td class="py-2.5 text-right font-semibold text-emerald-300">\${p.tempsTotalMinutes} min</td>
            </tr>
          \`).join('');
        }

        // Graphique Évolution
        const ctxEvolution = document.getElementById('chartEvolution').getContext('2d');
        if (chartEvolutionInstance) chartEvolutionInstance.destroy();
        chartEvolutionInstance = new Chart(ctxEvolution, {
          type: 'line',
          data: {
            labels: data.evolutionJours.map(j => j.jour.slice(5)),
            datasets: [
              {
                label: 'Minutes d\\'écran cumulées',
                data: data.evolutionJours.map(j => j.tempsMinutes),
                borderColor: '#10b981',
                backgroundColor: 'rgba(16, 185, 129, 0.1)',
                tension: 0.3,
                fill: true,
              },
              {
                label: 'Appareils actifs',
                data: data.evolutionJours.map(j => j.appareilsActifs),
                borderColor: '#38bdf8',
                borderDash: [4, 4],
                tension: 0.3,
                yAxisID: 'y1',
              }
            ]
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
              x: { grid: { color: '#334155' }, ticks: { color: '#94a3b8' } },
              y: { grid: { color: '#334155' }, ticks: { color: '#94a3b8' } },
              y1: { position: 'right', grid: { drawOnChartArea: false }, ticks: { color: '#38bdf8' } }
            },
            plugins: { legend: { labels: { color: '#cbd5e1' } } }
          }
        });

        // Graphique Catégories (Camembert)
        const ctxCat = document.getElementById('chartCategories').getContext('2d');
        if (chartCategoriesInstance) chartCategoriesInstance.destroy();
        chartCategoriesInstance = new Chart(ctxCat, {
          type: 'doughnut',
          data: {
            labels: data.tempsParCategorie.map(c => c.categorie),
            datasets: [{
              data: data.tempsParCategorie.map(c => c.tempsMinutes),
              backgroundColor: ['#10b981', '#f59e0b', '#06b6d4', '#8b5cf6', '#ec4899', '#64748b', '#3b82f6'],
              borderWidth: 0,
            }]
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
              legend: { position: 'bottom', labels: { color: '#cbd5e1', boxWidth: 12 } }
            }
          }
        });

      } catch (err) {
        console.error('Erreur chargement analytics:', err);
      }
    }

    document.addEventListener('DOMContentLoaded', chargerStats);
  </script>
</body>
</html>`);
};
