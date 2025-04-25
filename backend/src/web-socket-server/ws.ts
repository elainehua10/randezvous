import { WebSocketServer } from "ws";
import ConnectedUser from "./ConnectedUser";
import jwt from "jsonwebtoken";
import PubSubBroker from "./PubSubBroker";
import { Server } from "http";

export const locationBroker = PubSubBroker.getInstance();

export const setupWebsocketServer = (server: Server) => {
  const wsServer = new WebSocketServer({ server: server, path: "/locations" });

  function authenticateUser(token: string): string | null {
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET!);
      if (typeof decoded === "string" || !decoded?.user_metadata?.sub) {
        return null;
      }
      if ((decoded.exp || 0) < Date.now() / 1000) {
        return null;
      }
      return decoded.user_metadata.sub;
    } catch (err) {
      console.error(err);
      return null;
    }
  }

  wsServer.on("connection", async (socket) => {
    let user: ConnectedUser | null = null;

    socket.on("message", async (message) => {
      try {
        const data = JSON.parse(message.toString());
        const { authToken, longitude, latitude, activeGroupId } = data;
        const userId = authenticateUser(authToken);

        if (!userId) {
          user?.disconnect();
          return;
        }

        if (
          !authToken ||
          longitude === undefined ||
          latitude === undefined ||
          !activeGroupId
        ) {
          return;
        }

        if (!user) {
          user = new ConnectedUser(
            userId,
            activeGroupId,
            socket,
            locationBroker
          );
        }

        if (user.socket !== socket) {
          user.disconnect();
          user = new ConnectedUser(
            userId,
            activeGroupId,
            socket,
            locationBroker
          );
        }
        if (user.userInfo && user.userInfo.user_id !== userId) {
          user.disconnect();
          return;
        }

        user.publish(longitude, latitude);

        if (activeGroupId !== user.activeGroupId) {
          user.setActiveGroup(activeGroupId);
        }
      } catch (error) {
        console.error("Error processing message:", error);
      }
    });

    socket.on("close", () => {
      if (user) {
        console.log(`User ${user.userInfo?.username} disconnected`);
      }
    });
  });

  return wsServer;
};
