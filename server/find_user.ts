const SECRET_KEY = "sk_test_WRDZZMvsofYjxDo8acppAcON7IGvzQAV5kaFyFj8q7";

async function main() {
  const res = await fetch("https://api.clerk.com/v1/users?email_address=uripichipi@gmail.com", {
    headers: {
      Authorization: `Bearer ${SECRET_KEY}`
    }
  });
  const data = await res.json();
  console.log(JSON.stringify(data, null, 2));
}

main();
