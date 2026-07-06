const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const app = express();

// Middlewares globaux de sécurité et de formatage
app.use(helmet()); 
app.use(cors());   
app.use(morgan('dev')); 
app.use(express.json()); 

// Route de test principale
app.get('/', (req, res) => {
    res.json({ message: "Bienvenue sur l'API AgriDigitale !" });
});

// Exportation de l'application Express pour server.js
module.exports = app;
