// Script diagnostic : affiche les 10 premiers articles avec leur URL image
require('dotenv').config();
const mongoose = require('mongoose');
const Article = require('./src/models/Article');

mongoose.connect(process.env.MONGO_URI).then(async () => {
  const total = await Article.countDocuments();
  const sansImage = await Article.countDocuments({ $or: [{ image: null }, { image: '' }, { image: { $exists: false } }] });
  const avecImage = await Article.countDocuments({ image: { $exists: true, $ne: null, $ne: '' } });

  console.log(`\nTotal articles : ${total}`);
  console.log(`Avec image     : ${avecImage}`);
  console.log(`Sans image     : ${sansImage}`);

  console.log('\n--- 5 exemples d\'URLs image ---');
  const exemples = await Article.find({ image: { $exists: true, $ne: null, $ne: '' } }).select('titre image').limit(5);
  exemples.forEach(a => console.log(`  ${a.titre.substring(0, 40)} => ${a.image}`));

  await mongoose.disconnect();
});
