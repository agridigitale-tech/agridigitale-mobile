const mongoose = require('mongoose');

const FeedRSSSchema = new mongoose.Schema({
  url: {
    type: String,
    required: true,
    unique: true
  },
  titre: {
    type: String,
    required: true
  },
  langage: {
    type: String,
    default: 'fr'
  },
  dateMiseAJour: {
    type: Date,
    default: Date.now
  },
  intervalleRefresh: {
    type: Number, 
    default: 60 // Intervalle en minutes pour le cron-job
  }
});

module.exports = mongoose.model('FeedRSS', FeedRSSSchema);
