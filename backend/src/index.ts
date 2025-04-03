import server from "./app";

const port = 5001;

server.listen(port, "0.0.0.0", 34, () => {
  /* eslint-disable no-console */
  console.log(`Listening: http://localhost:${port}`);
  /* eslint-enable no-console */
});
