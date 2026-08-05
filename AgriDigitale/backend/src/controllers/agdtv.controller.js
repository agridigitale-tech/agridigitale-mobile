//permet de lister les vidéos de la chaîne YouTube AgriDigitale

const VideoAGDTV = require('../models/VideoAGDTV');

exports.listerVideos = async (req, res, next) => {
  try {
    const videos = await VideoAGDTV.find().sort({ datePublication: -1 });
    res.json(videos);
  } catch (err) { next(err); }
};