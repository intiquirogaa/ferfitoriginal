const SECRET_KEY = "sk_test_WRDZZMvsofYjxDo8acppAcON7IGvzQAV5kaFyFj8q7";

async function main() {
  const email = "uripichipi@gmail.com";
  const password = "FerfitPassword123!";
  
  const res = await fetch("https://api.clerk.com/v1/users", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${SECRET_KEY}`
    },
    body: JSON.stringify({
      email_address: [email],
      password: password,
      first_name: "Uri",
      username: "uripichipi",
      skip_password_checks: true
    })
  });
  const data = await res.json();
  console.log(JSON.stringify(data, null, 2));
}

main();
