/**
 * Migration : corrige les URLs d'images "ck" dans le contenu des articles.
 *
 * Problème : les images inline du flux RSS sont référencées en "/ck/xxx.jpg"
 * alors qu'elles sont réellement servies sous "/storage/ck/xxx.jpg".
 * L'URL "/ck/..." retombe sur la SPA (HTML) au lieu de l'image → image cassée.
 *
 * Ce script est idempotent : il peut être relancé sans risque.
 */
require('dotenv').config();
const mongoose = require('mongoose');
const Article = require('./src/models/Article');

const CHERCHER_CK = /\/ck\//i;
const REMPLACER_CK = (texte) =>
  texte
    // {{BASE_URL}}/ck/... → {{BASE_URL}}/storage/ck/...
    .replace(/\{\{BASE_URL\}\}\/ck\//gi, '{{BASE_URL}}/storage/ck/')
    // https://agridigitale.net/ck/... → .../storage/ck/...
    .replace(/(https?:\/\/[^/"'\s]+)\/ck\//gi, '$1/storage/ck/')
    // src="/ck/... (chemin relatif) → src="/storage/ck/...
    .replace(/(\ssrc\s*=\s*["'])\/ck\//gi, '$1/storage/ck/')
    .replace(/(\sdata-src\s*=\s*["'])\/ck\//gi, '$1/storage/ck/');

mongoose.connect(process.env.MONGO_URI).then(async () => {
  const articles = await Article.find({ contenu: { $regex: CHERCHER_CK } })
    .select('_id titre contenu image');
  console.log(`\n${articles.length} article(s) avec un chemin /ck/ à corriger\n`);

  let corriges = 0;
  for (const a of articles) {
    const avant = a.contenu;
    const apres = REMPLACER_CK(avant);
    const set = {};
    if (apres !== avant) set.contenu = apres;

    // Même correction pour l'image principale
    if (a.image && CHERCHER_CK.test(a.image) && !/\/storage\/ck\//i.test(a.image)) {
      set.image = a.image.replace(/(\/ck\/)/i, '/storage/ck/');
    }

    if (Object.keys(set).length === 0) continue;

    await Article.updateOne({ _id: a._id }, { $set: set });
    corriges++;
    console.log(`  ✅ ${a.titre.substring(0, 60)}`);
  }

  console.log(`\nTerminé : ${corriges} article(s) corrigé(s)`);
  await mongoose.disconnect();
}).catch((e) => {
  console.error('❌ Erreur :', e.message);
  process.exit(1);
});
