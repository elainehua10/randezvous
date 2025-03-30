import { WebSocketServer } from "ws";

const port = 8080;
const wsServer = new WebSocketServer({ port });

wsServer.on("connection", (socket) => {
  let user = null;

  socket.on("message", (message) => {});

  socket.on("close", () => {});
});
