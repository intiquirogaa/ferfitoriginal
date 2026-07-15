const https = require('https');
const secret = 'sk_test_WRDZZMvsofYjxDo8acppAcON7IGvzQAV5kaFyFj8q7';
const email = `testuser+${Date.now()}@example.com`;
const username = `testuser${Date.now()}`;
const password = 'Str0ng!Pass#2026';
const post = (url, headers, body) => new Promise((resolve, reject) => {
  const req = https.request(url, { method: 'POST', headers }, res => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => resolve({ status: res.statusCode, body: data }));
  });
  req.on('error', reject);
  req.write(body);
  req.end();
});
(async () => {
  try {
    const userBody = new URLSearchParams({ email_address: email, password, username }).toString();
    const createUser = await post('https://api.clerk.com/v1/users', {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Bearer ' + secret,
    }, userBody);
    console.log('createUser', createUser.status, createUser.body);
    if (createUser.status !== 200) return;
    const user = JSON.parse(createUser.body);
    const sessionBody = JSON.stringify({ user_id: user.id });
    const createSession = await post('https://api.clerk.com/v1/sessions', {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + secret,
    }, sessionBody);
    console.log('createSession', createSession.status, createSession.body);
    if (createSession.status !== 200) return;
    const session = JSON.parse(createSession.body);
    const createToken = await post(`https://api.clerk.com/v1/sessions/${session.id}/tokens`, {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + secret,
    }, JSON.stringify({}));
    console.log('createToken', createToken.status, createToken.body);
  } catch (err) {
    console.error(err);
  }
})();
