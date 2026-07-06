const mongoose = require('mongoose');

const videoSchema = new mongoose.Schema({
  idYoutube: { type: String, required: true, unique: true },
  titre: String,
  vignette: String,
  datePublication: Date,
}, { timestamps: true });

module.exports = mongoose.model('VideoAGDTV', videoSchema);