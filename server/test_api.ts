async function run() {
  const req0 = await fetch("http://localhost:3000/api/mobile/training-history", {
    headers: { Authorization: "Bearer dev_bypass_token" }
  });
  const res0 = await req0.json();
  const day = res0.history.activePlan.generatedContent.days[0];
  console.log("Is completed saved?:", day.exercises[0].seriesCompleted);
}
run();
