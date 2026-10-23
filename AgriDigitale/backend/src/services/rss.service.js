const Parser = require('rss-parser'); //pour parser les flux RSS
const cron = require('node-cron');//pour scheduler les tâches cron
const axios = require('axios');//pour faire des requêtes HTTP
const { URL } = require('url');//pour valider les URLs
const Article = require('../models/Article');
const { notifierNouvelArticle } = require('./notification.service');
const { desactiverBannieresExpirees } = require('../controllers/banniere.controller');

//pour parser les flux RSS avec des champs personnalisés (content:encoded, media:content, enclosure, author)
const parser = new Parser({
  customFields: {
    item: [
      ['content:encoded', 'contentEncoded'],
      ['media:content', 'mediaContent'],
      ['enclosure', 'enclosure'],
      ['dc:creator', 'creator'],
      ['author', 'author'],
    ],
  },
});

// Valide que l'URL est http/https et pointe vers un hôte public (anti-SSRF)
const urlEstSure = (urlStr) => {
  try {
    const parsed = new URL(urlStr);
    if (!['http:', 'https:'].includes(parsed.protocol)) return false;
    const host = parsed.hostname;
    if (/^(localhost|127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.|169\.254\.)/.test(host)) return false;
    return true;
  } catch (_) {
    return false;
  }
};

// Domaine public où sont hébergées les images de contenu (agridigitale.com est down)
const DOMAINE_IMAGES = process.env.MEDIA_BASE_URL || 'https://agridigitale.net';

// Les fichiers "ck" sont réellement servis sous "/storage/ck/" sur le site public
// ("/ck/xxx.jpg" retombe sur la SPA et renvoie du HTML au lieu de l'image).
const CHEMIN_CK = /^(https?:\/\/[^/]+)?\/ck\//i;

// Convertit une URL d'image relative (/ck/xxx.jpg) ou un marqueur en URL absolue
const urlAbsolue = (url) => {
  if (url == null) return url;
  const u = String(url).trim();
  if (u === '') return url;
  // Data URI, ancres, protocoles non http → inchangés
  if (/^(data:|blob:|mailto:|tel:|#)/i.test(u)) return u;
  // Déjà absolue → corriger l'ancien domaine .com et le chemin /ck/
  if (/^https?:\/\//i.test(u)) {
    return u
      .replace(/agridigitale\.com/gi, 'agridigitale.net')
      .replace(CHEMIN_CK, '$1/storage/ck/');
  }
  // Protocole-relative (//cdn.exemple.com/img.jpg)
  if (u.startsWith('//')) return `https:${u}`;
  // Chemin relatif → préfixé par le domaine public (+ /ck/ → /storage/ck/)
  return `${DOMAINE_IMAGES}${u.startsWith('/') ? u : `/${u}`}`.replace(
    CHEMIN_CK,
    '$1/storage/ck/'
  );
};

// Normalise une valeur srcset ("url1 1x, url2 2x") en absolutisant chaque URL
const normaliserSrcset = (valeur) =>
  String(valeur)
    .split(',')
    .map((partie) => {
      const bits = partie.trim().split(/\s+/);
      if (bits.length === 0 || bits[0] === '') return partie.trim();
      bits[0] = urlAbsolue(bits[0]);
      return bits.join(' ');
    })
    .join(', ');

// Normalise le HTML du corps d'un article :
//  - remplace le marqueur {{BASE_URL}} par le domaine public
//  - corrige le domaine agridigitale.com → agridigitale.net
//  - transforme les src / data-src / srcset relatifs en URL absolues (images inline)
const normaliserImagesContenu = (html = '') => {
  if (!html) return html;

  let resultat = String(html)
    .replace(/\{\{BASE_URL\}\}/gi, DOMAINE_IMAGES)
    .replace(/agridigitale\.com/gi, 'agridigitale.net');

  // Traite chaque balise <img ...> individuellement
  resultat = resultat.replace(/<img\b[^>]*>/gi, (tag) => {
    let t = tag;

    const dataSrc = t.match(/\sdata-src\s*=\s*(["'])([\s\S]*?)\1/i);
    const src = t.match(/\ssrc\s*=\s*(["'])([\s\S]*?)\1/i);
    const srcVide = !src || src[2].trim() === '';

    // Lazy-loading : si src absent/vide mais data-src présent → on promeut data-src en src
    if (dataSrc && srcVide) {
      const absolue = urlAbsolue(dataSrc[2]);
      if (/\ssrc\s*=/i.test(t)) {
        t = t.replace(/\ssrc\s*=\s*(["'])[\s\S]*?\1/i, ` src="${absolue}"`);
      } else {
        t = t.replace(/<img/i, `<img src="${absolue}"`);
      }
    }

    // Absolutise src et data-src
    t = t.replace(
      /(\s(?:src|data-src)\s*=\s*)(["'])([\s\S]*?)\2/gi,
      (m, prefixe, q, valeur) => `${prefixe}${q}${urlAbsolue(valeur)}${q}`,
    );
    // Absolutise srcset
    t = t.replace(
      /(\ssrcset\s*=\s*)(["'])([\s\S]*?)\2/gi,
      (m, prefixe, q, valeur) => `${prefixe}${q}${normaliserSrcset(valeur)}${q}`,
    );

    return t;
  });

  return resultat;
};

// Extrait un résumé du contenu HTML en supprimant les balises et en limitant la longueur
const extraireResume = (html = '', limite = 300) => {
  if (!html) return '';
  const texte = html
    .replace(/<[^>]*>?/gm, '')
    .replace(/&nbsp;/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  return texte.length > limite ? texte.substring(0, limite) + '...' : texte;
};

// Extrait l'URL de l'image d'un article RSS
const extraireImageRSS = (item) => {
  if (item.mediaContent && item.mediaContent.$ && item.mediaContent.$.url) {
    return item.mediaContent.$.url;
  }
  if (item.enclosure && item.enclosure.url) {
    return item.enclosure.url;
  }
  // Fallback : extraire l'image du contenu HTML (content:encoded ou description)
  const contenu = item.contentEncoded || item.content || item.description || '';
  const match = contenu.match(/<img[^>]+src="([^">]+)"/);
  if (match) return match[1];
  return null;
};
// Scrape l'image Open Graph (og:image) depuis la page web
const scrapeOgImage = async (url) => {
  if (!url || !urlEstSure(url)) return null; 
  try {
    const res = await axios.get(url, {
      timeout: 8000,
      headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' },
    });
    const match = res.data.match(/property="og:image"\s+content="([^"]+)"/);
    if (match) return match[1];
    const match2 = res.data.match(/content="(https?:\/\/[^"]+\.(?:jpg|jpeg|png|webp)[^"]*)"\s+property="og:image"/i);
    if (match2) return match2[1];
  } catch (_) {}
  return null;
};

/**
 * Extrait le contenu complet depuis une page agridigitale.net (Inertia.js/Laravel).
 * Le contenu est dans data-page JSON : props.article.content = '{"fr":"<p>...</p>"}'
 */
const scrapeContenuInertia = async (url) => {
  if (!url || !urlEstSure(url)) return null;
  try {
    const res = await axios.get(url, {
      timeout: 12000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml',
      },
    });
    const html = res.data;

    // Extraire le JSON Inertia depuis data-page="..."
    // Les guillemets sont encodés en &quot; dans l'attribut HTML
    const dataPageMatch = html.match(/data-page="({.*?})"/s);
    if (!dataPageMatch) return null;

    // Décoder les entités HTML de l'attribut
    const jsonStr = dataPageMatch[1]
      .replace(/&quot;/g, '"')
      .replace(/&#039;/g, "'")
      .replace(/&amp;/g, '&')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>');

    const pageData = JSON.parse(jsonStr);
    const article = pageData?.props?.article;
    if (!article) return null;

    // Le champ content est un JSON stringifié : '{"fr":"<p>...</p>"}'
    let contenu = '';
    if (article.content) {
      try {
        const contentObj = typeof article.content === 'string'
          ? JSON.parse(article.content)
          : article.content;
        contenu = contentObj.fr || contentObj.en || Object.values(contentObj)[0] || '';
      } catch (_) {
        contenu = article.content;
      }
    }

    if (contenu && contenu.replace(/<[^>]*>/g, '').trim().length > 50) {
      // Réécrit les images inline : {{BASE_URL}} + chemins relatifs → URL absolues
      // (ex. src="{{BASE_URL}}/ck/xxx.jpg" ou src="/ck/xxx.jpg"
      //      → https://agridigitale.net/storage/ck/xxx.jpg)
      contenu = normaliserImagesContenu(contenu);
      return contenu;
    }
    return null;
  } catch (err) {
    console.warn(`[RSS] Échec scrape Inertia ${url}: ${err.message}`);
    return null;
  }
};

const recupererFlux = async (tentative = 1) => {
  try {
    const response = await axios.get(process.env.RSS_FEED_URL, {
      timeout: 20000,
      headers: { 'User-Agent': 'Mozilla/5.0 (compatible; AgriDigitaleBot/1.0)' },
    });
    const feed = await parser.parseString(response.data);
    let nouveaux = 0;

    for (const item of feed.items) {
      if (!item.guid) continue;
      const existe = await Article.findOne({ guid: item.guid });
      if (existe) {
        // Si l'article existe déjà, mettre à jour le titre ou le résumé si la rédaction les a modifiés sur le site
        const updates = {};
        if (item.title && existe.titre !== item.title) {
          updates.titre = item.title;
        }
        const resumeItem = item.contentSnippet || item.description || '';
        if (resumeItem && existe.resume !== resumeItem) {
          updates.resume = resumeItem;
        }
        if (Object.keys(updates).length > 0) {
          await Article.updateOne({ _id: existe._id }, { $set: updates });
          console.log(`[RSS] Article actualisé : "${item.title}" (${item.guid})`);
        }
        continue;
      }

      const categorieDetectee =
        item.categories && item.categories.length > 0 ? item.categories[0] : 'Général';

      let image = extraireImageRSS(item);
      if (!image && item.link) {
        image = await scrapeOgImage(item.link);
      }
      // Toujours corriger .com → .net (agridigitale.com est down)
      if (image) image = image.replace('agridigitale.com', 'agridigitale.net');

      // Toujours scraper le contenu complet depuis la page Inertia
      let contenu = '';
      if (item.link) {
        contenu = await scrapeContenuInertia(item.link) || '';
      }
      // Fallback sur le contenu RSS si le scrape échoue
      if (!contenu || contenu.replace(/<[^>]*>/g, '').trim().length < 50) {
        contenu = item.contentEncoded || item.content || item.description || '';
      }

      const sourceResume = item.contentSnippet || item.description || '';
      
      // Extraire la source depuis le lien de l'article
      let sourceArticle = 'AgriDigitale';
      if (item.link) {
        try {
          const urlObj = new URL(item.link);
          sourceArticle = urlObj.hostname.replace('www.', '');
        } catch (_) {}
      }

      // Extraire la légende de la photo si présente dans le contenu (balise figcaption)
      let legendeImage = null;
      const matchFigcaption = (contenu || '').match(/<figcaption[^>]*>([\s\S]*?)<\/figcaption>/i);
      if (matchFigcaption) {
        legendeImage = matchFigcaption[1].replace(/<[^>]*>/g, '').trim();
      }

      // Extraire l'auteur de l'article
      const auteurArticle = item.author || item.creator || 'Agridigitale Admin';

      // Normalise les images inline du contenu
      contenu = normaliserImagesContenu(contenu);

      const article = await Article.create({
        guid: item.guid,
        titre: item.title,
        contenu: contenu,
        resume: extraireResume(sourceResume),
        image,
        lienSource: item.link,
        source: sourceArticle,
        categorie: categorieDetectee,
        datePublication: new Date(item.pubDate),
        auteur: auteurArticle,
        legendeImage: legendeImage,
      });

      nouveaux++;

      // Push FCM + sauvegarde en base en parallèle
      const Utilisateur = require('../models/Utilisateur');
      const Notification = require('../models/Notification');

      await Promise.all([
        // 1. Notification push FCM
        notifierNouvelArticle(article),

        // 2. Sauvegarde en base pour tous les utilisateurs
        Utilisateur.find({}).select('_id').then(utilisateurs => {
          if (utilisateurs.length === 0) return;
          return Notification.insertMany(
            utilisateurs.map(u => ({
              titre: 'Nouvel article',
              message: article.titre,
              destinataire: u._id,
              article: article._id,
              lu: false,
            }))
          );
        }),
      ]).catch(err => console.warn('[RSS] Erreur notification:', err.message));
    }
    console.log(`[RSS] Synchronisation terminée : ${nouveaux} nouveaux articles sur ${feed.items.length}`);
  } catch (err) {
    if (tentative < 3) {
      const delai = tentative * 10000;
      console.warn(`[RSS] Tentative ${tentative} échouée, retry dans ${delai / 1000}s : ${err.message}`);
      setTimeout(() => recupererFlux(tentative + 1), delai);
    } else {
      console.error('[RSS] Flux inaccessible après 3 tentatives :', err.message);
    }
  }
};

// Met à jour TOUS les articles existants en base avec le contenu complet
const mettreAJourContenuArticles = async () => {
  try {
    console.log('[RSS] Début de la mise à jour du contenu des articles existants...');
    const articles = await Article.find({ lienSource: { $exists: true, $ne: '' } });

    let misAJour = 0;
    for (const article of articles) {
      const contenuTexte = (article.contenu || '').replace(/<[^>]*>/g, '').trim();
      // Mettre à jour si le contenu est vide ou trop court (moins de 200 chars de texte)
      if (contenuTexte.length >= 200) continue;

      try {
        const nouveauContenu = await scrapeContenuInertia(article.lienSource);
        if (nouveauContenu && nouveauContenu.replace(/<[^>]*>/g, '').trim().length > contenuTexte.length) {
          await Article.updateOne({ _id: article._id }, { $set: { contenu: nouveauContenu } });
          misAJour++;
          console.log(`[RSS] ✓ Mis à jour : ${article.titre.substring(0, 60)}`);
        }
      } catch (err) {
        console.warn(`[RSS] ✗ Échec : ${article.titre.substring(0, 40)} — ${err.message}`);
      }
    }
    console.log(`[RSS] Mise à jour terminée : ${misAJour} articles mis à jour`);
  } catch (err) {
    console.error('[RSS] Erreur mise à jour contenu:', err.message);
  }
};

const demarrerScheduler = () => {
  cron.schedule('*/15 * * * *', recupererFlux);
  recupererFlux();
  console.log('[RSS] Scheduler démarré (toutes les 15 min)');
  cron.schedule('0 3 * * *', mettreAJourContenuArticles);
  // Désactivation automatique des bannières expirées toutes les heures
  cron.schedule('0 * * * *', desactiverBannieresExpirees);
  desactiverBannieresExpirees(); // exécution immédiate au démarrage
};

module.exports = { recupererFlux, demarrerScheduler, mettreAJourContenuArticles, scrapeContenuInertia, normaliserImagesContenu };
