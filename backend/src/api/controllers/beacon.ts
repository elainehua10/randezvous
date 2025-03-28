// beacon.ts
import { Request, Response } from "express";
import sql from "../../db";

// Helper: calculate distance between two lat/lng pairs (Haversine formula)
function getDistanceInMeters(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const toRad = (x: number) => (x * Math.PI) / 180;
  const R = 6371000; // Earth's radius in meters

  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
}

// Confirm that a user has arrived at the beacon
export const confirmArrival = async (req: Request, res: Response) => {
  const { userId, groupId } = req.body;

  if (!userId || !groupId) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  try {
    // Get user's current location
    const [user] = await sql`
      SELECT latitude, longitude FROM profile WHERE id = ${userId};
    `;
    if (!user) return res.status(404).json({ error: "User not found" });

    // Get beacon's location
    const [beacon] = await sql`
      SELECT latitude, longitude FROM beacon WHERE group_id = ${groupId} ORDER BY created_at DESC LIMIT 1;
    `;
    if (!beacon) return res.status(404).json({ error: "No active beacon found for this group" });

    const distance = getDistanceInMeters(user.latitude, user.longitude, beacon.latitude, beacon.longitude);

    if (distance > 50) {
      return res.status(400).json({ error: "You are too far from the beacon to confirm arrival" });
    }

    // Insert into beacon_arrivals if not already recorded
    await sql`
      INSERT INTO beacon_arrivals (user_id, group_id, beacon_id, arrival_time)
      SELECT ${userId}, ${groupId}, ${beacon.id}, NOW()
      WHERE NOT EXISTS (
        SELECT 1 FROM beacon_arrivals 
        WHERE user_id = ${userId} AND group_id = ${groupId} AND beacon_id = ${beacon.id}
      );
    `;

    res.status(200).json({ message: "Arrival confirmed!" });
  } catch (error) {
    console.error("Error confirming arrival:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

// Assign points to users based on arrival order
export const assignPoints = async (req: Request, res: Response) => {
  const { groupId } = req.body;

  if (!groupId) {
    return res.status(400).json({ error: "Missing groupId" });
  }

  try {
    // Get most recent beacon for the group
    const [beacon] = await sql`
      SELECT id FROM beacon WHERE group_id = ${groupId} ORDER BY created_at DESC LIMIT 1;
    `;
    if (!beacon) return res.status(404).json({ error: "No beacon found" });

    // Get arrivals for this beacon, ordered by arrival_time
    const arrivals = await sql`
      SELECT user_id FROM beacon_arrivals
      WHERE beacon_id = ${beacon.id}
      ORDER BY arrival_time ASC;
    `;

    // Assign points (e.g., 1st = 100, 2nd = 75, 3rd = 50, rest = 25)
    const pointValues = [100, 75, 50];
    for (let i = 0; i < arrivals.length; i++) {
      const userId = arrivals[i].user_id;
      const points = pointValues[i] ?? 25;

      await sql`
        UPDATE profile
        SET points = COALESCE(points, 0) + ${points}
        WHERE id = ${userId};
      `;
    }

    res.status(200).json({ message: "Points assigned!" });
  } catch (error) {
    console.error("Error assigning points:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};
