require('dotenv').config();
const mongoose = require('mongoose');
const axios = require('axios');
const Article = require('./src/models/Article');

const scrapeOgImage = async (url) => {
  try {
    const res = await axios.get(url, {
      timeout: 8000,
      headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' },
    });
    const match = res.data.match(/property="og:image"\s+content="([^"]+)"/);
    if (match) return match[1];
    const match2 = res.data.match(/content="(https?:\/\/[^"]+\.(?:jpg|jpeg|png|webp)[^"]*)"\s+property="og:image"/i);
    if (match2) return match2[1];
  } catch (e) {
    console.log(`  ✗ Scrape échoué: ${e.message}`);
  }
  return null;
};

mongoose.connect(process.env.MONGO_URI).then(async () => {
  // Articles récents sans image
  const troisMois = new Date();
  troisMois.setMonth(troisMois.getMonth() - 3);

  const articles = await Article.find({
    datePublication: { $gte: troisMois },
    $or: [{ image: null }, { image: '' }, { image: { $exists: false } }],
  }).select('_id titre lienSource datePublication');

  console.log(`\n${articles.length} articles récents sans image\n`);

  let fixes = 0;
  for (const a of articles) {
    console.log(`→ ${a.titre.substring(0, 50)}`);
    if (!a.lienSource) { console.log('  ✗ Pas de lienSource\n'); continue; }

    const image = await scrapeOgImage(a.lienSource);
    if (image) {
      // Remplacer .com par .net si nécessaire
      const imageCorrigee = image.replace('agridigitale.com', 'agridigitale.net');
      await Article.updateOne({ _id: a._id }, { $set: { image: imageCorrigee } });
      console.log(`  ✅ Image trouvée: ${imageCorrigee}\n`);
      fixes++;
    } else {
      console.log('  ✗ Aucune image trouvée\n');
    }
  }

  console.log(`\nTerminé : ${fixes}/${articles.length} articles corrigés`);
  await mongoose.disconnect();
});
