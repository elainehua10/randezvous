import server from "./app";
import { setupBeaconSchedulers } from "./jobs/beaconSpawner";

const port = 8080;

server.listen(port, "0.0.0.0", 34, async () => {
  /* eslint-disable no-console */
  console.log(`Listening: http://localhost:${port}`);
  /* eslint-enable no-console */

  try {
    await setupBeaconSchedulers(); // <-- call it after server starts
  } catch (err) {
    console.error("Failed to set up beacon schedulers:", err);
  }
});
