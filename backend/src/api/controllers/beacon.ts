import { Request, Response } from "express";
import sql from "../../db";

// Helper: Calculate distance using Haversine formula
function getDistanceInMeters(lat1: number, lon1: number, lat2: number, lon2: number): number {
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

// Confirm a user has reached the beacon
export const confirmArrival = async (req: Request, res: Response) => {
  const { userId, groupId } = req.body;

  if (!userId || !groupId) {
    return res.status(400).json({ error: "Missing userId or groupId" });
  }

  try {
    // Get user's current location
    const [user] = await sql`
      SELECT latitude, longitude FROM profile WHERE id = ${userId};
    `;
    if (!user) return res.status(404).json({ error: "User not found" });

    // Get most recent beacon for this group
    const [beacon] = await sql`
      SELECT id, latitude, longitude
      FROM beacon
      WHERE id = (
        SELECT MAX(id) FROM beacon
        WHERE id IN (
          SELECT beacon_id FROM user_group WHERE group_id = ${groupId}
        )
      );
    `;
    if (!beacon) return res.status(404).json({ error: "No active beacon found" });

    const distance = getDistanceInMeters(user.latitude, user.longitude, beacon.latitude, beacon.longitude);
    if (distance > 50) {
      return res.status(400).json({ error: "You are too far from the beacon to confirm arrival" });
    }

    // Insert arrival
    await sql`
      INSERT INTO user_beacons (beacon_id, user_id, reached, time_reached, latitude, longitude)
      VALUES (${beacon.id}, ${userId}, true, NOW(), ${user.latitude}, ${user.longitude})
      ON CONFLICT (beacon_id, user_id) DO NOTHING;
    `;

    return res.status(200).json({ message: "Arrival confirmed!" });
  } catch (error) {
    console.error("Error confirming arrival:", error);
    return res.status(500).json({ error: "Internal server error" });
  }
};

// Get the beacon for a group
export const getLatestBeacon = async (req: Request, res: Response) => {
  const { groupId } = req.params;
  try {
    const [beacon] = await sql`
      SELECT id, latitude, longitude, started_at
      FROM beacon
      WHERE group_id = ${groupId}
      ORDER BY started_at DESC
      LIMIT 1;
    `;
    if (!beacon) {
      return res.status(404).json({ error: "No active beacon for this group" });
    }
    res.status(200).json(beacon);
  } catch (err) {
    res.status(500).json({ error: "Error fetching latest beacon" });
  }
};

// Assign points based on arrival order
export const assignPoints = async (req: Request, res: Response) => {
  const { groupId } = req.body;

  if (!groupId) {
    return res.status(400).json({ error: "Missing groupId" });
  }

  try {
    // Get latest beacon for group
    const [beacon] = await sql`
      SELECT id FROM beacon
      WHERE id IN (
        SELECT beacon_id FROM user_group WHERE group_id = ${groupId}
      )
      ORDER BY created_at DESC
      LIMIT 1;
    `;
    if (!beacon) return res.status(404).json({ error: "No beacon found" });

    // Get arrivals for this beacon
    const arrivals = await sql`
      SELECT user_id FROM user_beacons
      WHERE beacon_id = ${beacon.id} AND reached = true
      ORDER BY time_reached ASC;
    `;

    const pointValues = [100, 75, 50];
    for (let i = 0; i < arrivals.length; i++) {
      const userId = arrivals[i].user_id;
      const points = pointValues[i] ?? 25;

      await sql`
        UPDATE profile
        SET group_score = COALESCE(group_score, 0) + ${points}
        WHERE id = ${userId};
      `;
    }

    return res.status(200).json({ message: "Points assigned!" });
  } catch (error) {
    console.error("Error assigning points:", error);
    return res.status(500).json({ error: "Internal server error" });
  }
};