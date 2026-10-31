// Modèle de données pour les marchés et prix des denrées agricoles (Togo)
const mongoose = require('mongoose');

const prixProduitSchema = new mongoose.Schema({
  produit: { type: String, required: true },
  prixActuel: { type: Number, required: true },
  prixPrecedent: { type: Number, required: true },
  unite: { type: String, required: true },
  tendance: {
    type: String,
    enum: ['hausse', 'baisse', 'stable'],
    default: 'stable',
  },
  icone: { type: String, default: '🌾' },
  historiquePrix: { type: [Number], default: [] },
  dateMiseAJour: { type: Date, default: Date.now },
}, { _id: false });

const prixMarcheSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true }, // 'cacaveli', 'notse', 'kpalime', 'kara', 'dapaong'
  nom: { type: String, required: true },
  ville: { type: String, required: true },
  region: { type: String, required: true },
  produits: [prixProduitSchema],
  dateMiseAJour: { type: Date, default: Date.now },
}, { timestamps: true });

module.exports = mongoose.model('PrixMarche', prixMarcheSchema);
