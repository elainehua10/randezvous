import { WebSocket } from "ws";
import sql from "../db";
import PubSubBroker from "./PubSubBroker";
import { assignPointsInternal } from "../api/controllers/beacon";
import { sendNotification } from "../notifications";

export interface UserLocationInfo {
  user_id: string;
  first_name: string;
  last_name: string;
  username: string;
  profile_picture: string;
  longitude: number;
  latitude: number;
}

// Helper: Calculate distance using Haversine formula
function getDistanceInMeters(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const toRad = (x: number) => (x * Math.PI) / 180;
  const R = 6371000; // Radius of Earth in meters
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

class ConnectedUser {
  userInfo?: UserLocationInfo;
  groupIds: Set<string>;
  activeGroupId?: string;
  socket: WebSocket;
  private broker: PubSubBroker;
  private lastBeaconCheckTime: number = 0;

  constructor(
    userId: string,
    activeGroupId: string,
    socket: WebSocket,
    broker: PubSubBroker
  ) {
    this.socket = socket;
    this.broker = broker;
    this.groupIds = new Set();

    this.fetchUserGroups(userId).then((groupIds) => {
      this.groupIds = new Set(groupIds);
      this.setActiveGroup(activeGroupId);
    });

    this.getUserInfo(userId)
      .then((info) => {
        console.log(info);
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

  async setActiveGroup(newGroupId: string) {
    if (!this.groupIds.has(newGroupId) && newGroupId != "-1") {
      console.error(
        `User ${this.userInfo?.user_id} is not a member of group ${newGroupId}`
      );
      return;
    }

    try {
      const locations = await sql`
        SELECT ug.user_id, p.longitude, p.latitude, p.first_name, p.last_name, p.username, p.profile_picture
        FROM user_group ug
        JOIN profile p ON ug.user_id = p.id
        WHERE ug.group_id = ${newGroupId ?? "-1"}
      `;
      locations.forEach((location) => {
        if (location.user_id !== this.userInfo?.user_id)
          this.socket.send(JSON.stringify(location), (e) => console.log(e));
      });

      // First check if the group has beacon_frequency > 0
      const [group] = await sql`
        SELECT beacon_frequency FROM groups WHERE id = ${newGroupId};
      `;

      if (group?.beacon_frequency > 0) {
        // Then fetch the latest beacon
        const [beacon] = await sql`
          SELECT latitude, longitude
          FROM beacon
          WHERE group_id = ${newGroupId}
          ORDER BY started_at DESC
          LIMIT 1;
        `;

        if (beacon) {
          this.socket.send(
            JSON.stringify({
              user_id: "BEACON",
              first_name: "",
              last_name: "",
              username: "",
              profile_picture: "",
              ...beacon,
            })
          );
        }
      }
    } catch (err) {
      console.error("Error fetching initial locations:", err);
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

  async updateGroupIds() {
    if (!this.userInfo) {
      return;
    }
    const newGroupIds = await sql`
    SELECT group_id
    FROM user_group
    WHERE user_id = ${this.userInfo.user_id};
  `;
    const newGroupIdsSet = new Set(newGroupIds.map((row) => row.group_id));
    const newGroups = Array.from(newGroupIdsSet).filter(
      (groupId) => !this.groupIds.has(groupId)
    );
    this.groupIds = new Set([...this.groupIds, ...newGroupIdsSet]);
  }

  async publish(long: number, lat: number) {
    if (!this.userInfo) {
      return;
    }

    this.userInfo.longitude = long;
    this.userInfo.latitude = lat;

    this.groupIds.forEach((groupId) =>
      this.broker.publish(groupId, this.userInfo!)
    );

    sql`
      UPDATE profile
      SET longitude = ${long}, latitude = ${lat}
      WHERE id = ${this.userInfo.user_id};
    `.catch((e) => console.error("ERRORED ON UPDATE"));

    // rate limiting
    const now = Date.now();
    if (now - this.lastBeaconCheckTime < 10000) return; // wait at least 10 seconds
    this.lastBeaconCheckTime = now;

    this.updateGroupIds();

    // Beacon proximity check & auto-confirmation
    this.groupIds.forEach(async (groupId) => {
      if (!groupId || !this.userInfo) return;

      try {
        const [beacon] = await sql`
          SELECT id, latitude, longitude
          FROM beacon
          WHERE group_id = ${groupId}
          ORDER BY started_at DESC
          LIMIT 1;
        `;

        if (!beacon) return;

        const distance = getDistanceInMeters(
          lat,
          long,
          beacon.latitude,
          beacon.longitude
        );

        if (distance <= 200) {
          // Check if already confirmed
          const [alreadyConfirmed] = await sql`
            SELECT 1 FROM user_beacons
            WHERE user_id = ${this.userInfo.user_id}
            AND beacon_id = ${beacon.id};
          `;

          if (!alreadyConfirmed) {
            console.log("Within range! Confirming arrival...");
            this.socket.send("You've reached the beacon!");

            await sql`
              INSERT INTO user_beacons (beacon_id, user_id, reached, time_reached, latitude, longitude)
              VALUES (${beacon.id}, ${this.userInfo.user_id}, true, NOW(), ${lat}, ${long});
            `;

            // Notify other members in the group when this user reaches the beacon
            const otherMembers = await sql`
              SELECT p.id, p.notifications_enabled
              FROM user_group ug
              JOIN profile p ON ug.user_id = p.id
              WHERE ug.group_id = ${groupId}
                AND p.id != ${this.userInfo.user_id}
                AND p.notifications_enabled = true
              `;

            if (otherMembers.length > 0) {
              const notifTitle = `${this.userInfo.first_name} reached the beacon!`;
              const notifBody = `${this.userInfo.first_name} just arrived at the beacon for group ${groupId}.`;

              const notifPromises = otherMembers.map((member) =>
                sendNotification(member.id, notifTitle, notifBody)
              );

              await Promise.all(notifPromises);
            }

            // Reassign points and ranks
            await assignPointsInternal(groupId);

            // Check if all members have reached the beacon
            const [unconfirmedCount] = await sql`
            SELECT COUNT(*)
            FROM user_group ug
            LEFT JOIN user_beacons ub ON ug.user_id = ub.user_id AND ub.beacon_id = ${beacon.id}
            WHERE ug.group_id = ${groupId} AND (ub.reached IS DISTINCT FROM true);
            `;

            if (parseInt(unconfirmedCount.count) === 0) {
              // --- START: Added logic to increase group score ---
              const scoreIncrement = 10; // Define how much the score increases for a full meetup
              try {
                const updateResult = await sql`
                  UPDATE groups
                  SET group_score = group_score + ${scoreIncrement}
                  WHERE id = ${groupId}
                  RETURNING name, group_score;
                `;
                if (updateResult.length > 0) {
                  console.log(
                    `Group score updated for group ${updateResult[0].name} (ID: ${groupId}) due to full beacon arrival. New score: ${updateResult[0].group_score}`
                  );
                } else {
                  console.warn(
                    `Could not find group with ID ${groupId} to update score after full beacon arrival.`
                  );
                }
              } catch (scoreUpdateError) {
                console.error(
                  `Error updating group score for group ${groupId} after full beacon arrival:`,
                  scoreUpdateError
                );
              }
              // --- END: Added logic to increase group score ---

              // Everyone has reached — notify all members with notifications enabled
              const groupMembersToNotify = await sql`
              SELECT p.id
              FROM user_group ug
              JOIN profile p ON ug.user_id = p.id
              WHERE ug.group_id = ${groupId} AND p.notifications_enabled = true;
            `;

              if (groupMembersToNotify.length > 0) {
                const congratsTitle = "🎉 Congrats!";
                const congratsBody =
                  "Everyone in your group has reached the beacon!";

                const congratsPromises = groupMembersToNotify.map((member) =>
                  sendNotification(member.id, congratsTitle, congratsBody)
                );

                await Promise.all(congratsPromises);
              }
            }
          }
        }
      } catch (err) {
        console.error("Beacon auto-check error:", err);
      }
    });
  }

  receiveUpdate(data: UserLocationInfo) {
    if (
      this.socket.readyState === WebSocket.OPEN &&
      data.user_id != this.userInfo?.user_id
    ) {
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

    this.groupIds.clear();
    this.userInfo = undefined;
  }
}

export default ConnectedUser;
