import { ENV } from "./server/_core/env";

async function test() {
  const exerciseId = "0024";
  const url = `https://exercisedb.p.rapidapi.com/image?exerciseId=${encodeURIComponent(exerciseId)}&resolution=360`;
  console.log("Fetching image url:", url);
  try {
    const res = await fetch(url, {
      method: "GET",
      headers: {
        "x-rapidapi-key": process.env.MUSCLE_WIKI_API_KEY || "ba9adb9712msh352e29fd344ac8bp148058jsn581825fc1760",
        "x-rapidapi-host": "exercisedb.p.rapidapi.com",
      }
    });
    console.log("Status:", res.status, res.statusText);
    console.log("Headers:", [...res.headers.entries()]);
  } catch (err) {
    console.error("Error:", err);
  }
}

test();
