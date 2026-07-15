const url = 'https://free-quetzal-72.clerk.accounts.dev/v1/client/sign_ups';
const publishableKey = 'pk_test_ZnJlZS1xdWV0emFsLTcyLmNsZXJrLmFjY291bnRzLmRldiQ';
const body = new URLSearchParams({ email_address: 'test@example.com', password: 'Abcd1234' }).toString();
const tests = [
  {
    name: 'basic',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      Authorization: `Bearer ${publishableKey}`,
    },
  },
  {
    name: 'browser-origin',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      Authorization: `Bearer ${publishableKey}`,
      Origin: 'http://localhost:54618',
      Referer: 'http://localhost:54618',
    },
  },
  {
    name: 'only-origin',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      Origin: 'http://localhost:54618',
      Referer: 'http://localhost:54618',
    },
  },
];

for (const test of tests) {
  console.log(`--- ${test.name}`);
  const response = await fetch(url, {
    method: 'POST',
    headers: test.headers,
    body,
  });
  console.log('status', response.status);
  console.log(await response.text());
}
