import schedule from "node-schedule";
import sql from "../db";
import { sendNotification } from "../notifications";
import { randomUUID } from "crypto";

const scheduledJobs = new Map<string, schedule.Job>();

// Log all active scheduled jobs
function logScheduledJobs() {
  console.log("🔍 Currently Scheduled Jobs:");
  const jobs = schedule.scheduledJobs;
  for (const [name, job] of Object.entries(jobs)) {
    console.log(`📌 ${name}: Next invocation at ${job.nextInvocation()}`);
  }
}

// === Beacon Spawning Logic ===
async function getRandomCoordinates(groupId: string) {
  try {
    // Get lat/lng of all group members
    const members = await sql`
        SELECT p.latitude, p.longitude
        FROM user_group ug
        JOIN profile p ON ug.user_id = p.id
        WHERE ug.group_id = ${groupId}
        AND p.latitude IS NOT NULL
        AND p.longitude IS NOT NULL;
      `;

    if (members.length === 0) {
      // Fallback to default area if no members have location
      const lat = 32.7 + Math.random() * 0.1;
      const lng = -117.2 + Math.random() * 0.1;
      return { latitude: lat, longitude: lng };
    }

    // Compute average coordinates
    const total = members.reduce(
      (acc, m) => {
        acc.lat += m.latitude;
        acc.lng += m.longitude;
        return acc;
      },
      { lat: 0, lng: 0 }
    );

    const avgLat = total.lat / members.length;
    const avgLng = total.lng / members.length;

    // Add small random jitter (within ~100 meters)
    const jitter = () => (Math.random() - 0.5) * 0.002; // ~0.002 deg = ~222m
    return {
      latitude: avgLat + jitter(),
      longitude: avgLng + jitter(),
    };
  } catch (err) {
    console.error("❌ Error getting average location:", err);
    // fallback if something breaks
    const lat = 32.7 + Math.random() * 0.1;
    const lng = -117.2 + Math.random() * 0.1;
    return { latitude: lat, longitude: lng };
  }
}

export async function spawnBeacon(groupId: string) {
  const now = new Date();
  const { latitude, longitude } = await getRandomCoordinates(groupId);

  try {
    // delete existing beacons for the group
    // await sql`
    //   DELETE FROM beacon WHERE group_id = ${groupId};
    // `;
    // insert new beacon
    await sql`
      INSERT INTO beacon (
        group_id,
        created_at,
        started_at,
        longitude,
        latitude
      ) VALUES (
        ${groupId},
        ${now.toISOString()},
        ${now.toISOString()},
        ${longitude},
        ${latitude}
      );
    `;
    console.log(
      `✅ Beacon spawned for group ${groupId} at (${latitude}, ${longitude})`
    );

    // Send notifs
    const members = await sql`
      SELECT p.id, p.notifications_enabled, g.name
      FROM user_group ug
      JOIN profile p ON ug.user_id = p.id
      JOIN groups g ON ug.group_id = g.id
      WHERE ug.group_id = ${groupId} AND p.notifications_enabled = true;
    `;

    if (members.length > 0) {
      const notificationPromises = members.map((member) =>
        sendNotification(
          member.id,
          `(${member.name}) New Beacon Spawned!`,
          "A new beacon has been placed. Check the map for its location."
        )
      );

      await Promise.all(notificationPromises);
      console.log(`Sent notifications to ${members.length} members.`);
    } else {
      console.log("No members have notifications enabled.");
    }
  } catch (err) {
    console.error(`❌ Failed to spawn beacon for ${groupId}:`, err);
  }
}

// === Helper to schedule a beacon job ===
function scheduleGroupBeacon(
  groupId: string,
  frequency: number
): schedule.Job | null {
  spawnBeacon(groupId); // Spawn immediately

  let cronExpr: string;
  let maxDelay: number;

  if (frequency === 86400) {
    cronExpr = "0 0 * * *"; // Daily at midnight
    maxDelay = 86400;
  } else if (frequency === 604800) {
    cronExpr = "0 0 * * 0"; // Weekly at midnight on Sunday
    maxDelay = 604800;
  } else if (frequency === 1209600) {
    cronExpr = "0 0 * * 0"; // Biweekly, filter every other week
    maxDelay = 1209600;
  } else if (frequency === 2592000) {
    cronExpr = "0 0 1 * *"; // Monthly, on 1st day
    maxDelay = 2592000;
  } else {
    console.log(`⚠️ Unknown frequency for group ${groupId}, skipping...`);
    return null;
  }

  return schedule.scheduleJob(`${groupId}-beacon`, cronExpr, () => {
    if (frequency === 1209600) {
      const weekNumber = Math.floor(Date.now() / (1000 * 60 * 60 * 24 * 7));
      if (weekNumber % 2 !== 0) return;
    }
    const delay = Math.floor(Math.random() * maxDelay * 1000);
    setTimeout(() => spawnBeacon(groupId), delay);
  });
}

// === Initialize Schedulers for All Groups ===
export async function setupBeaconSchedulers() {
  const groups = await sql`
    SELECT id, beacon_frequency FROM groups WHERE beacon_frequency > 0;
  `;

  for (const group of groups) {
    const { id: groupId, beacon_frequency } = group;

    const job = scheduleGroupBeacon(groupId, beacon_frequency);
    if (job) {
      scheduledJobs.set(groupId, job);
    }
  }
  logScheduledJobs();
  console.log("📆 Beacon schedulers set up.");
}

// === Rescheduling Logic ===
export function rescheduleBeaconJob(groupId: string, newFrequency: number) {
  const existingJob = scheduledJobs.get(groupId);
  if (existingJob) {
    existingJob.cancel();
  }

  const job = scheduleGroupBeacon(groupId, newFrequency);
  if (job) {
    scheduledJobs.set(groupId, job);
    console.log(
      `🔄 Rescheduled job for group ${groupId} to frequency ${newFrequency}`
    );
  }
}
