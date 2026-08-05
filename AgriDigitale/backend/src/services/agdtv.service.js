//permet de gérer les opérations liées aux données de l'AGDTV

const axios = require('axios');
const VideoAGDTV = require('../models/VideoAGDTV');

const synchroniserVideos = async () => {
  try {
    const { data } = await axios.get('https://www.googleapis.com/youtube/v3/search', {
      params: {
        key: process.env.YOUTUBE_API_KEY,
        channelId: process.env.YOUTUBE_CHANNEL_ID,
        part: 'snippet',
        order: 'date',
        maxResults: 15,
        type: 'video',
      },
    });

    for (const item of data.items) {
      await VideoAGDTV.findOneAndUpdate(
        { idYoutube: item.id.videoId },
        {
          titre: item.snippet.title,
          vignette: item.snippet.thumbnails.high.url,
          datePublication: item.snippet.publishedAt,
        },
        { upsert: true }
      );
    }
    console.log(' Vidéos AGDTV synchronisées');
  } catch (err) {
    console.error(' Erreur AGDTV :', err.message);
  }
};

module.exports = { synchroniserVideos };
