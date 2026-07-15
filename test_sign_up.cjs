const http = require('http');

const data = JSON.stringify({ email: "test@test.com", password: "password123" });

const options = {
  hostname: '127.0.0.1',
  port: 3001,
  path: '/api/mobile/clerk/sign-up',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

const req = http.request(options, res => {
  console.log(`STATUS: ${res.statusCode}`);
  console.log(`HEADERS: ${JSON.stringify(res.headers)}`);
  
  let body = '';
  res.on('data', d => body += d);
  res.on('end', () => console.log(`BODY: ${body.substring(0, 100)}...`));
});

req.on('error', error => {
  console.error(error);
});

req.write(data);
req.end();
