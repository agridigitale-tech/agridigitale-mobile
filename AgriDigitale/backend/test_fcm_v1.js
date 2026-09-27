const { GoogleAuth } = require('google-auth-library');
const https = require('https');

const serviceAccount = require('./src/config/firebase-service-account.json');
const PROJECT_ID = serviceAccount.project_id;
const FCM_TOKEN = 'eIKGX3GfQaSSoDiP6-ZMwE:APA91bE7loZCojdOH0yP3M_QYVgaVhtSPoLLkm56PWzz-Xz0QxewCH2g2dDOaTB7l2c5HV-hs4MSXcLcM7w1HulhyeKKtdzY7wI3YhNzVPAePGGOvdtXkE0';

async function getAccessToken() {
  const auth = new GoogleAuth({
    credentials: serviceAccount,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  });
  const client = await auth.getClient();
  const token = await client.getAccessToken();
  return token.token;
}

async function sendNotification() {
  const accessToken = await getAccessToken();
  console.log('✅ Token OAuth2 obtenu');

  const body = JSON.stringify({
    message: {
      token: FCM_TOKEN,
      notification: { title: 'Test AgriDigitale', body: 'FCM HTTP v1 fonctionne !' },
      android: { priority: 'high' },
    },
  });

  const options = {
    hostname: 'fcm.googleapis.com',
    path: `/v1/projects/${PROJECT_ID}/messages:send`,
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(body),
    },
  };

  return new Promise((resolve) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        console.log('Status HTTP:', res.statusCode);
        console.log('Réponse FCM:', data);
        resolve();
      });
    });
    req.on('error', (e) => console.error('Erreur réseau:', e.message));
    req.write(body);
    req.end();
  });
}

sendNotification().catch(console.error);
