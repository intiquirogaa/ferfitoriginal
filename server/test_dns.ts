import dns from "dns";

const check = (domain: string) => {
  dns.lookup(domain, (err, address, family) => {
    if (err) {
      console.log(`${domain} FAILED:`, err.message);
    } else {
      console.log(`${domain} SUCCEEDED:`, address);
    }
  });
};

check("free-quetzal-72.accounts.dev");
check("free-quetzal-72.clerk.accounts.dev");
