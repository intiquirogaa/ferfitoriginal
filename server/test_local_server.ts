import http from "http";

async function makeRequest(path: string, payload: any) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(payload);
    const req = http.request(
      {
        hostname: "localhost",
        port: 3000,
        path: path,
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(data),
          // We bypass requireAuth by checking what the server returns without auth,
          // or we can mock auth. Wait, requireAuth requires a valid Clerk token or TRPC context.
        },
      },
      (res) => {
        let body = "";
        res.on("data", (chunk) => (body += chunk));
        res.on("end", () => {
          resolve({ status: res.statusCode, body });
        });
      }
    );
    req.on("error", reject);
    req.write(data);
    req.end();
  });
}

async function test() {
  try {
    const res = await makeRequest("/social/feo-chat", {
      message: "Hola Feo",
      history: []
    });
    console.log("Chat Response:", res);
  } catch (e) {
    console.error("Chat Error:", e);
  }
}
test();
