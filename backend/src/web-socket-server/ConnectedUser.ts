import { WebSocket } from "ws";
import sql from "../db";
import PubSubBroker from "./PubSubBroker";

export interface UserLocationInfo {
  user_id: string;
  first_name: string;
  last_name: string;
  username: string;
  profile_picture: string;
  longitude: number;
  latitude: number;
}

class ConnectedUser {
  userInfo?: UserLocationInfo;
  groupIds: Set<string>;
  activeGroupId?: string;
  socket: WebSocket;
  private broker: PubSubBroker;

  static connectedUsers: Map<string, ConnectedUser> = new Map();

  constructor(
    userId: string,
    activeGroupId: string,
    socket: WebSocket,
    broker: PubSubBroker
  ) {
    this.socket = socket;
    this.broker = broker;
    this.groupIds = new Set();

    ConnectedUser.connectedUsers.set(userId, this);

    this.fetchUserGroups(userId).then((groupIds) => {
      this.groupIds = new Set(groupIds);
      this.setActiveGroup(activeGroupId);
    });

    this.getUserInfo(userId)
      .then((info) => {
        this.userInfo = info;
      })
      .catch((err) => console.error("Error initializing user info:", err));
  }

  private async fetchUserGroups(userId: string): Promise<string[]> {
    try {
      const result = await sql`
        SELECT group_id FROM user_group WHERE user_id = ${userId};
      `;
      return result.map((row: any) => row.group_id);
    } catch (error) {
      console.error("Error fetching user groups:", error);
      return [];
    }
  }

  private async getUserInfo(userId: string): Promise<UserLocationInfo> {
    try {
      const result = await sql`
        SELECT first_name, last_name, username, profile_picture, longitude, latitude
        FROM profile 
        WHERE id = ${userId};
      `;
      if (result.length === 0) {
        throw new Error("User not found");
      }
      const {
        first_name,
        last_name,
        username,
        profile_picture,
        longitude,
        latitude,
      } = result[0];

      return {
        user_id: userId,
        first_name,
        last_name,
        username,
        profile_picture,
        longitude,
        latitude,
      };
    } catch (error) {
      console.error(error);
      throw new Error("Server error");
    }
  }

  setActiveGroup(newGroupId: string) {
    if (!this.groupIds.has(newGroupId)) {
      console.error(`User is not a member of group ${newGroupId}`);
      return;
    }

    if (this.activeGroupId === newGroupId) {
      return;
    }

    if (this.activeGroupId) {
      this.broker.unsubscribe(this.activeGroupId, this);
    }

    this.activeGroupId = newGroupId;
    this.broker.subscribe(newGroupId, this);
  }

  publish(long: number, lat: number) {
    if (!this.userInfo || !this.activeGroupId) {
      return;
    }
    this.userInfo.longitude = long;
    this.userInfo.latitude = lat;

    this.broker.publish(this.activeGroupId, this.userInfo);
    sql`
      UPDATE profile 
      SET longitude = ${long}, latitude = ${lat} 
      WHERE id = ${this.userInfo.user_id};
    `;
  }

  receiveUpdate(data: any) {
    if (this.socket.readyState === WebSocket.OPEN) {
      console.log("SENDING");
      this.socket.send(JSON.stringify(data));
    }
  }

  disconnect() {
    if (this.activeGroupId) {
      this.broker.unsubscribe(this.activeGroupId, this);
      this.activeGroupId = undefined;
    }

    if (this.socket.readyState === WebSocket.OPEN) {
      this.socket.close();
    }

    if (this.userInfo) {
      ConnectedUser.connectedUsers.delete(this.userInfo.user_id);
    }

    this.groupIds.clear();
    this.userInfo = undefined;
  }
}

export default ConnectedUser;
