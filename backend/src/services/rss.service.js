// permet de récupérer les articles depuis le flux RSS et de les stocker dans la base de données

const Parser = require('rss-parser');
const cron = require('node-cron');
const Article = require('../models/Article');
const { notifierNouvelArticle } = require('./notification.service');

const parser = new Parser({ customFields: { item: ['category'] } });

const nettoyerHTML = (html = '') =>
  html.replace(/<[^>]*>?/gm, '').replace(/&nbsp;/g, ' ').trim();

const extraireImage = (item) => {
  const match = (item['content:encoded'] || '').match(/<img[^>]+src="([^">]+)"/);
  return match ? match[1] : null;
};

const recupererFlux = async () => {
  try {
    const feed = await parser.parseURL(process.env.RSS_FEED_URL);
    let nouveaux = 0;

    for (const item of feed.items) {
      const existe = await Article.findOne({ guid: item.guid });
      if (existe) continue;

      const article = await Article.create({
        guid: item.guid,
        titre: item.title,
        contenu: nettoyerHTML(item['content:encoded'] || item.content),
        resume: nettoyerHTML(item.contentSnippet || item.description),
        image: extraireImage(item),
        lienSource: item.link,
        categorie: item.categories?.[0] || 'Non classé',
        datePublication: new Date(item.pubDate),
      });

      nouveaux++;
      await notifierNouvelArticle(article); // push ciblé selon les préférences des utilisateurs
    }
    console.log(` Flux RSS synchronisé : ${nouveaux} nouveaux article(s) sur ${feed.items.length}`);
  } catch (err) {
    console.error(' Erreur récupération RSS :', err.message);
  }
};

const demarrerScheduler = () => {
  cron.schedule('*/15 * * * *', recupererFlux); // toutes les 15 minutes
  recupererFlux(); // exécution immédiate au démarrage du serveur
};

module.exports = { demarrerScheduler, recupererFlux };