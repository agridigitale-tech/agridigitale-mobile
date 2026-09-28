require('dotenv').config();
const https = require('https');

const APP_ID = process.env.ONESIGNAL_APP_ID;
const API_KEY = process.env.ONESIGNAL_API_KEY;

console.log('APP_ID:', APP_ID);
console.log('API_KEY:', API_KEY?.substring(0, 30) + '...');

// Envoyer à tous les abonnés (test)
const body = JSON.stringify({
  app_id: APP_ID,
  included_segments: ['All'],
  headings: { fr: 'AgriDigitale — Test', en: 'AgriDigitale — Test' },
  contents: { fr: 'Notification de test ✅', en: 'Test notification ✅' },
  data: { type: 'test' },
});

const req = https.request({
  hostname: 'api.onesignal.com',
  path: '/notifications',
  method: 'POST',
  headers: {
    'Authorization': `Key ${API_KEY}`,
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(body),
  },
}, (res) => {
  let result = '';
  res.on('data', chunk => result += chunk);
  res.on('end', () => {
    console.log('\nStatus HTTP:', res.statusCode);
    const json = JSON.parse(result);
    console.log('Réponse:', JSON.stringify(json, null, 2));
    if (json.id) console.log('\n✅ Notification envoyée ! ID:', json.id);
    else console.log('\n❌ Erreur:', json.errors || json);
  });
});

req.on('error', e => console.error('Erreur réseau:', e.message));
req.write(body);
req.end();
