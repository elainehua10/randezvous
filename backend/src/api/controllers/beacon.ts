import { Request, Response } from "express";
import sql from "../../db";
import { spawnBeacon } from "../../jobs/beaconSpawner";

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
      WHERE group_id = ${groupId}
      ORDER BY started_at DESC
      LIMIT 1;
    `;

    if (!beacon) return res.status(404).json({ error: "No active beacon found" });

    // Insert arrival
    await sql`
      INSERT INTO user_beacons (beacon_id, user_id, reached, time_reached, latitude, longitude)
      VALUES (${beacon.id}, ${userId}, true, NOW(), ${user.latitude}, ${user.longitude})
    `;

    // Automatically assign points and ranks
    await assignPointsInternal(groupId);

    return res
      .status(200)
      .json({ message: "Arrival confirmed and points assigned!" });
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

// Internal helper to assign points and rank
const assignPointsInternal = async (groupId: string) => {
  // Get latest beacon for group
  const [beacon] = await sql`
    SELECT id FROM beacon
    WHERE group_id = ${groupId}
    ORDER BY created_at DESC
    LIMIT 1;
  `;
  if (!beacon) return;

  // Get arrivals ordered by time
  const arrivals = await sql`
    SELECT user_id FROM user_beacons
    WHERE beacon_id = ${beacon.id} AND reached = true
    ORDER BY time_reached ASC;
  `;

  // Assign points: 10, 5, 3, 2, 1, 1, 1...
  const basePoints = [10, 5, 3, 2, 1];
  for (let i = 0; i < arrivals.length; i++) {
    const userId = arrivals[i].user_id;
    const points = basePoints[i] ?? 1;

    await sql`
      UPDATE user_group
      SET points = COALESCE(points, 0) + ${points}
      WHERE user_id = ${userId} AND group_id = ${groupId};
    `;
  }

  // Recalculate rank for all group members
  const ranked = await sql`
    SELECT user_id
    FROM user_group
    WHERE group_id = ${groupId}
    ORDER BY points DESC;
  `;

  for (let i = 0; i < ranked.length; i++) {
    const userId = ranked[i].user_id;
    const rank = i + 1;

    await sql`
      UPDATE user_group
      SET rank = ${rank}
      WHERE user_id = ${userId} AND group_id = ${groupId};
    `;
  }
};

export const manualSpawn = async (req: Request, res: Response) => {
  const { groupId } = req.body;
  if (!groupId) {
    return res.status(400).json({ error: "groupId is required" });
  }
  try {
    await spawnBeacon(groupId);
    return res
      .status(200)
      .json({ message: `Beacon spawned for group ${groupId}` });
  } catch (err) {
    console.error("Error in spawnBeacon:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
};

// Assign points based on arrival order
export const assignPoints = async (req: Request, res: Response) => {
  const { groupId } = req.body;

  if (!groupId) {
    return res.status(400).json({ error: "Missing groupId" });
  }

  try {
    await assignPointsInternal(groupId);
    res.status(200).json({ message: "Points and ranks updated!" });
  } catch (error) {
    console.error("Error assigning points:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export { assignPointsInternal };
