require('dotenv').config();
const mongoose = require('mongoose');
const Article = require('./src/models/Article');

mongoose.connect(process.env.MONGO_URI).then(async () => {
  const articles = await Article.find({ image: { $regex: 'agridigitale\\.com' } }).select('_id image');
  console.log(`${articles.length} articles à corriger...`);
  let count = 0;
  for (const a of articles) {
    await Article.updateOne({ _id: a._id }, { $set: { image: a.image.replace('agridigitale.com', 'agridigitale.net') } });
    count++;
  }
  console.log(`✅ ${count} articles mis à jour (.com → .net)`);
  await mongoose.disconnect();
});
