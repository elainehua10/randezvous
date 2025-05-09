// group.ts
// All the group processing logic
import supabase from "../../supabase";
import { Request, Response } from "express";
import { UploadedFile } from "express-fileupload";
import sql from "../../db";
import sharp from "sharp";
import { sendNotification } from "../../notifications";
import { rescheduleBeaconJob } from "../../jobs/beaconSpawner";

// Set limit to how many groups a user can create
const MAX_GROUPS_PER_USER = 10000;

// ============= Leader of group functions ===================

// Create a new group
export const createGroup = async (req: Request, res: Response) => {
  try {
    // Check fields
    const { userId, groupName, isPublic, frequency = 86400 } = req.body;
    if (!userId || !groupName || isPublic === undefined) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    console.log(isPublic);

    // Check if user has reached the limit of groups they can create
    const userProfile = await sql`
      SELECT num_groups FROM profile WHERE id = ${userId};
    `;
    if (userProfile.length === 0) {
      return res.status(404).json({ error: "User not found." });
    }
    if (userProfile[0].num_groups >= MAX_GROUPS_PER_USER) {
      return res.status(403).json({
        error: `You cannot be in more than ${MAX_GROUPS_PER_USER} group.`,
      });
    }

    // Check group name length
    if (groupName.length < 3 || groupName.length > 30) {
      return res
        .status(400)
        .json({ error: "Group name must be between 3 and 30 characters." });
    }

    // Check for duplicate name
    const existingGroup = await sql`
      SELECT id FROM groups WHERE name = ${groupName};
    `;
    if (existingGroup.length > 0) {
      return res.status(409).json({
        error:
          "A group with this name already exists. Please choose a different name.",
      });
    }

    // Insert new group (user is the leader)
    let newGroup = await sql`
            INSERT INTO groups (name, is_public, leader_id, beacon_frequency) 
            VALUES (${groupName}, ${isPublic}, ${userId}, ${frequency})
            RETURNING id;
        `;

    // Add user to user_group table
    const groupId = newGroup[0].id;
    await sql`
            INSERT INTO user_group (group_id, user_id) 
            VALUES (${groupId}, ${userId})
            RETURNING *;
        `;

    // Update profile to reflect that user is in a group
    await sql`
            UPDATE profile 
            SET num_groups = num_groups + 1
            WHERE id = ${userId};
        `;

    return res.status(200).json({ success: true, group: newGroup[0] });
  } catch (error) {
    console.error("Error creating group:", error);
    return res.status(500).json({ error: "Internal server error" });
  }
};

export const reassignLeader = async (req: Request, res: Response) => {
  try {
    // Check fields
    const { groupId, userId, newLeaderId } = req.body;
    if (!groupId || !userId || !newLeaderId) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    // Check if the user is the current leader of the group
    const group = await sql`
      SELECT leader_id FROM groups WHERE id = ${groupId};
    `;
    if (group.length === 0) {
      return res.status(404).json({ error: "Group not found." });
    }
    if (group[0].leader_id !== userId) {
      return res
        .status(403)
        .json({ error: "Only the current leader can reassign leadership." });
    }

    // Check if the new leader is a member of the group
    const member = await sql`
      SELECT user_id FROM user_group WHERE group_id = ${groupId} AND user_id = ${newLeaderId};
    `;
    if (member.length === 0) {
      return res
        .status(400)
        .json({ error: "New leader must be a member of the group." });
    }

    // Update the leader in the groups table
    await sql`
      UPDATE groups 
      SET leader_id = ${newLeaderId} 
      WHERE id = ${groupId};
    `;

    return res
      .status(200)
      .json({ success: true, message: "Leader reassigned successfully." });
  } catch (error) {
    console.error("Error reassigning leader:", error);
    return res.status(500).json({ error: "Internal server error" });
  }
};

// Rename group (only leader can change)
export const renameGroup = async (req: Request, res: Response) => {
  try {
    // Check fields
    const { userId, groupId, newName } = req.body;
    if (!userId || !groupId || !newName) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    // Check name length
    if (newName.length < 3 || newName.length > 30) {
      return res
        .status(400)
        .json({ error: "Group name must be between 3 and 30 characters." });
    }

    // Check for duplicate name
    const existingGroup = await sql`
            SELECT id FROM groups WHERE name = ${newName} AND id <> ${groupId};
        `;
    if (existingGroup.length > 0) {
      return res.status(409).json({
        error:
          "A group with this name already exists. Please choose a different name.",
      });
    }

    // Update group name
    const updatedGroup = await sql`
            UPDATE groups 
            SET name = ${newName} 
            WHERE id = ${groupId}
            RETURNING *;
        `;
    return res.status(200).json({ success: true, group: updatedGroup[0] });
  } catch (error) {
    console.error("Error renaming group:", error);
    return res.status(500).json({ error: "error lol" });
  }
};

// Upload an icon for group
export const uploadIcon = async (req: Request, res: Response) => {
  try {
    // Check fields
    const { userId, groupId } = req.body;
    if (!userId || !groupId || !req.files) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    // Check group ownership
    const group = await sql`
            SELECT id FROM groups WHERE id = ${groupId} AND leader_id = ${userId};
        `;
    if (group.length === 0) {
      return res.status(403).json({
        error: "You are not authorized to upload an icon for this group.",
      });
    }

    // Extract file
    const iconFile = req.files?.icon as UploadedFile;
    if (!iconFile) {
      return res.status(400).json({ error: "No file uploaded" });
    }

    // Validate file type
    const allowedExtensions = ["png", "jpg", "jpeg", "gif"];
    const fileExtension = iconFile.name.split(".").at(-1);
    if (!allowedExtensions.includes(fileExtension || "")) {
      return res.status(400).json({
        error: "Invalid file type. Only PNG, JPG, JPEG, and GIF are allowed.",
      });
    }

    // Size the file down
    const resizedImageBuffer = await sharp(iconFile.data)
      .resize(200, 200)
      .toBuffer();

    // Upload to Supabase Storage (Bucket: "images")
    const fileName = `group_${groupId}_${Date.now()}.${fileExtension}`;
    const { error } = await supabase.storage
      .from("images")
      .upload(fileName, resizedImageBuffer, {
        cacheControl: "3600",
        upsert: false,
        contentType: iconFile.mimetype,
      });
    if (error) {
      console.error("Error uploading icon to Supabase:", error);
      return res.status(500).json({ error: "supabase error lol" });
    }

    // Get public URL
    const { data } = supabase.storage.from("images").getPublicUrl(fileName);

    // Update group icon URL
    const updatedGroup = await sql`
            UPDATE groups
            SET icon_url = ${data.publicUrl}
            WHERE id = ${groupId}
            RETURNING *;
        `;

    return res.status(200).json({ success: true, group: updatedGroup[0] });
  } catch (error) {
    console.error("Error uploading icon:", error);
    return res.status(500).json({ error: "error lol" });
  }
};

// Change group publicity
export const setPublicity = async (req: Request, res: Response) => {
  try {
    // Check fields
    const { userId, groupId, isPublic } = req.body;
    if (!userId || !groupId || isPublic === undefined) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    console.log(isPublic);

    // Update group publicity
    const updatedPublicity = await sql`
            UPDATE groups 
            SET is_public = ${isPublic} 
            WHERE id = ${groupId}
            RETURNING *;
        `;

    return res.status(200).json({ success: true, group: updatedPublicity[0] });
  } catch (error) {
    console.error("Error changing group publicity:", error);
    return res.status(500).json({ error: "error lol" });
  }
};

// Send an invite to other users
export const inviteToGroup = async (req: Request, res: Response) => {
  try {
    // Check fields
    const { userId, toUserId, groupId } = req.body;
    if (!userId || !toUserId || !groupId) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    // Check if invite already exists
    const existingInvite = await sql`
      SELECT id FROM invite
      WHERE from_user_id = ${userId} 
      AND to_user_id = ${toUserId} 
      AND group_id = ${groupId} 
      AND status = 'pending';
    `;

    if (existingInvite.length > 0) {
      return res
        .status(409)
        .json({ error: "Invite already sent to this user." });
    }

    // Fetch group name and sender's username
    const groupAndUser = await sql`
      SELECT g.name AS group_name, p.username AS sender_username, p.notifications_enabled
      FROM groups g
      JOIN profile p ON p.id = ${toUserId}  -- Ensure you're selecting the invited user's notification setting
      WHERE g.id = ${groupId};
    `;

    if (groupAndUser.length === 0) {
      return res.status(404).json({ error: "Group or user not found" });
    }

    const { group_name, sender_username, notifications_enabled } =
      groupAndUser[0];

    // Insert the invite
    let result = await sql`
      INSERT INTO invite (from_user_id, to_user_id, group_id) 
      VALUES (${userId}, ${toUserId}, ${groupId})
      RETURNING id;
    `;

    const inviteId = result[0].id;
    console.log("NOTIF: ", notifications_enabled);
    // Send notification to the invited user
    if (notifications_enabled) {
      console.log("Sending notification to user:", toUserId);
      await sendNotification(
        toUserId,
        "Group Invitation",
        `${sender_username} invited you to join ${group_name}.`
      );
    }

    return res.status(200).json({ message: "Invite Created", inviteId });
  } catch (error) {
    console.error("Error creating group:", error);
    res.status(500).json({ message: "error lol" });
    throw error;
  }
};

// Remove people from the group
export const removeFromGroup = async (req: Request, res: Response) => {
  try {
    const { userId, removingUserId, groupId } = req.body;
    if (!userId || !removingUserId || !groupId) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    // Check group ownership
    const group = await sql`
            SELECT id FROM groups WHERE id = ${groupId} AND leader_id = ${userId};
        `;
    if (group.length === 0) {
      return res.status(403).json({
        error: "You are not authorized to remove people from this group.",
      });
    }

    // Remove user from user_group table
    await sql`
            DELETE FROM user_group
            WHERE user_id = ${removingUserId} AND group_id = ${groupId};
        `;

    // Update profile to not be in a group
    await sql`
            UPDATE profile 
            SET num_groups = num_groups - 1
            WHERE id = ${removingUserId};
        `;

    return res.status(200).json({ message: "User removed from group" });
  } catch (error) {
    console.error("Error removing user from group:", error);
    res.status(500).json({ message: "error lol" });
    throw error;
  }
};

// Set beacon frequency
export const setBeaconFreq = async (req: Request, res: Response) => {
  try {
    const { userId, groupId, frequency } = req.body;

    // Validate input
    if (!userId || !groupId || frequency === undefined) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    // Frequency should be a number
    if (typeof frequency !== "number") {
      return res.status(400).json({ error: "Invalid frequency value" });
    }

    // Check if user is the leader of the group
    const group = await sql`
      SELECT leader_id FROM groups WHERE id = ${groupId};
    `;

    if (group.length === 0) {
      return res.status(404).json({ error: "Group not found" });
    }

    if (group[0].leader_id !== userId) {
      return res.status(403).json({
        error: "Only the group leader can set the beacon frequency",
      });
    }

    // Update the beacon frequency
    const updatedGroup = await sql`
      UPDATE groups 
      SET beacon_frequency = ${frequency}
      WHERE id = ${groupId}
      RETURNING *;
    `;

    // console.log("📡 Calling rescheduleBeaconJob with frequency:", frequency);
    await rescheduleBeaconJob(groupId, frequency);

    return res.status(200).json({
      success: true,
      message: "Beacon frequency updated successfully",
      group: updatedGroup[0],
    });
  } catch (error) {
    console.error("Error setting beacon frequency:", error);
    return res.status(500).json({ error: "Internal server error" });
  }
};

// ============= Member of group functions ===================

// Accept invite
export const acceptInvite = async (req: Request, res: Response) => {
  const { userId, groupId } = req.body;

  if (!userId || !groupId) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  try {
    // Check if there's a pending invite for this user and group
    const invite = await sql`
      SELECT from_user_id FROM invite
      WHERE group_id = ${groupId} 
        AND to_user_id = ${userId} 
        AND status = 'pending'
      LIMIT 1;
    `;
    if (!invite || invite.length === 0) {
      return res
        .status(404)
        .json({ error: "No pending invite found for this user and group" });
    }

    // Check if the user is already in a group
    const userProfile = await sql`
      SELECT num_groups FROM profile WHERE id = ${userId};
    `;
    if (userProfile.length === 0) {
      return res.status(404).json({ error: "User not found." });
    }
    if (userProfile[0].num_groups >= MAX_GROUPS_PER_USER) {
      return res.status(403).json({
        error: `You cannot be in more than ${MAX_GROUPS_PER_USER} group.`,
      });
    }

    // Check if user is already a member
    const membership = await sql`
      SELECT id 
      FROM user_group 
      WHERE group_id = ${groupId} AND user_id = ${userId};
    `;

    if (membership.length > 0) {
      return res.status(400).json({ error: "Already a member of this group" });
    }

    // Adding user to the user_group table
    await sql`
      INSERT INTO user_group (group_id, user_id)
      VALUES (${groupId}, ${userId})
      ON CONFLICT DO NOTHING;
    `;

    // Update the invite status to 'accepted'
    await sql`
      UPDATE invite
      SET status = 'accepted'
      WHERE group_id = ${groupId} AND to_user_id = ${userId};
    `;

    // Update profile to indicate the user is now in a group
    await sql`
      UPDATE profile 
      SET num_groups = num_groups + 1 
      WHERE id = ${userId};
    `;

    return res
      .status(200)
      .json({ message: "Invite accepted. You have been added to the group." });
  } catch (error) {
    console.error("Error accepting invite:", error);
    return res.status(500).json({
      error: (error as Error).message || "An unknown error occurred",
    });
  }
};

// Leave the a group user is in
export const leaveGroup = async (req: Request, res: Response) => {
  const { userId, groupId } = req.body;

  if (!userId || !groupId) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  try {
    // Remove user from user_group table
    await sql`
            DELETE FROM user_group
            WHERE user_id = ${userId} AND group_id = ${groupId}
        `;
    // Update profile to not be in a group
    await sql`
            UPDATE profile
            SET num_groups = num_groups - 1
            WHERE id = ${userId}
        `;

    return res.status(200).json({ message: "User removed from group" });
  } catch (error) {
    console.error("Error leaving group:", error);
    return res.status(500).json({
      error: (error as Error).message || "An unknown error occurred",
    });
  }
};

export const getGroupMembers = async (req: Request, res: Response) => {
  try {
    const { userId, groupId } = req.body;

    if (!userId || !groupId) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    // Check if the group exists and fetch the leader's ID and group name
    const group = await sql`
    SELECT leader_id, name, group_score, icon_url, is_public, beacon_frequency FROM groups WHERE id = ${groupId};
  `;

    if (group.length === 0) {
      return res.status(404).json({ error: "Group not found." });
    }

    const leader_id = group[0].leader_id;
    const name = group[0].name;
    const group_score = group[0].group_score;
    const iconUrl = group[0].icon_url;
    const isPublic = group[0].is_public;
    const isUserLeader = userId === leader_id;
    const beaconFrequency = group[0].beacon_frequency;

    // Fetch all members of the group, filtering out those in a blocked relationship with the current user
    const members = await sql`
    SELECT u.id, u.first_name, u.last_name, u.profile_picture, u.username
    FROM user_group ug
    JOIN profile u ON ug.user_id = u.id
    WHERE ug.group_id = ${groupId}
      AND NOT EXISTS (
        SELECT 1 FROM blocked b
        WHERE (b.user_id = ${userId} AND b.blocked_id = u.id)
           OR (b.user_id = u.id AND b.blocked_id = ${userId})
      )
  `;

    return res.status(200).json({
      groupId,
      name,
      group_score,
      leader_id,
      isUserLeader,
      members,
      iconUrl,
      isPublic,
      beaconFrequency,
    });
  } catch (error) {
    console.error("Error fetching group members:", error);
    return res.status(500).json({ error: "Internal server error" });
  }
};

export const getGlobalLeaderboard = async (req: Request, res: Response) => {
  try {
    // Fetch all groups sorted by score
    const groups = await sql`
      SELECT 
        id, 
        name, 
        group_score, 
        icon_url
      FROM groups
      WHERE is_public = true
      ORDER BY group_score DESC
      LIMIT 100;
    `;

    if (groups.length === 0) {
      return res.status(200).json({ leaderboard: [] });
    }

    // Format the response to match what the frontend expects
    const leaderboard = groups.map((group) => ({
      id: group.id,
      name: group.name,
      group_score: group.group_score || 0,
      icon_url: group.icon_url,
    }));

    return res.status(200).json({ leaderboard });
  } catch (error) {
    console.error("Error fetching global leaderboard:", error);
    return res.status(500).json({ error: "Internal server error" });
  }
};

// Get locations of other users
export const getGroupLocations = async (req: Request, res: Response) => {
  const { userId, groupId } = req.body;

  if (!userId || !groupId) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  try {
    // Check if user is in the group
    const userInGroup = await sql`
      SELECT user_id FROM user_group
      WHERE user_id = ${userId} AND group_id = ${groupId}
    `;

    if (userInGroup.length === 0) {
      return res
        .status(403)
        .json({ error: "You are not a member of this group" });
    }

    // Get locations of other users in the group
    const locations = await sql`
      SELECT ug.user_id, p.longitude, p.latitude, p.first_name, p.last_name, p.username, p.profile_picture
      FROM user_group ug
      JOIN profile p ON ug.user_id = p.id
      WHERE ug.group_id = ${groupId}
    `;

    console.log("LOCATIONS", locations);

    return res.status(200).json({ locations });
  } catch (error) {
    console.error("Error getting group locations:", error);
    return res.status(500).json({
      error: (error as Error).message || "An unknown error occurred",
    });
  }
};

// ============= General group functions ===================

// Get all groups the user is part of
export const getUserGroups = async (req: Request, res: Response) => {
  try {
    const { userId } = req.body;
    if (!userId) {
      return res.status(400).json({ error: "Missing userId" });
    }

    // Get all groups the user is part of
    const groups = await sql`
      SELECT groups.id, name,icon_url
      FROM groups
      JOIN user_group ON groups.id = user_group.group_id
      WHERE user_group.user_id = ${userId};
    `;

    console.log(groups.map((group) => group["icon_url"]));

    return res.status(200).json(groups);
  } catch (error) {
    console.error("Error fetching user groups:", error);
    return res.status(500).json({ error: "Internal server error" });
  }
};

export const searchPublicGroups = async (req: Request, res: Response) => {
  try {
    const { groupName } = req.body;

    // Validate input
    if (!groupName || typeof groupName !== "string") {
      return res
        .status(400)
        .json({ error: "Group name is required and must be a string" });
    }

    // Search for public groups where name matches the query (case-insensitive)
    const result = await sql`
      SELECT id, name, leader_id, is_public, icon_url, group_score
      FROM groups 
      WHERE is_public = true 
      AND LOWER(name) LIKE LOWER(${`%${groupName}%`});
    `;

    if (result.length === 0) {
      return res.status(200).json({ groups: [] }); // Return empty array instead of 404
    }

    // Map results to a clean response format
    const groups = result.map((group: any) => ({
      id: group.id,
      name: group.name,
      leader_id: group.leader_id,
      is_public: group.is_public,
      icon_url: group.icon_url,
    }));

    console.log("Found groups:", groups);

    res.status(200).json({
      groups,
    });
  } catch (error) {
    console.error("Error searching public groups:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const getAllPublicGroups = async (req: Request, res: Response) => {
  try {
    const results = await sql`
      SELECT id, name, leader_id, is_public, icon_url
      FROM groups 
      WHERE is_public = true 
      ORDER BY name ASC
    `;
    res.status(200).json({
      groups: results,
    });
  } catch (error) {
    console.error("Error fetching all public groups:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const joinGroup = async (req: Request, res: Response) => {
  try {
    const { groupId, userId } = req.body;

    // Validate group exists and is public
    const group = await sql`
      SELECT id, is_public 
      FROM groups 
      WHERE id = ${groupId} AND is_public = true;
    `;

    if (group.length === 0) {
      return res.status(404).json({ error: "Public group not found" });
    }

    // Check if user is already a member
    const membership = await sql`
      SELECT id 
      FROM user_group 
      WHERE group_id = ${groupId} AND user_id = ${userId};
    `;

    if (membership.length > 0) {
      return res.status(400).json({ error: "Already a member of this group" });
    }

    // Add user to group
    await sql`
      INSERT INTO user_group (group_id, user_id)
      VALUES (${groupId}, ${userId});
    `;

    await sql`
      UPDATE profile 
      SET num_groups = num_groups + 1 
      WHERE id = ${userId};
    `;

    res.status(200).json({ message: "Successfully joined the group" });
  } catch (error) {
    console.error("Error joining group:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// Get all invites for the user
export const getUserInvites = async (req: Request, res: Response) => {
  const { userId } = req.body;
  if (!userId) {
    return res.status(400).json({ error: "Missing userId" });
  }

  try {
    const invites = await sql`
      SELECT 
        groups.id, 
        groups.name, 
        COALESCE(groups.icon_url, NULL) AS icon_url 
      FROM invite
      JOIN groups ON invite.group_id = groups.id
      WHERE invite.to_user_id = ${userId} AND invite.status = 'pending';
    `;

    console.log("Sending invites:", invites); // Debugging print

    return res.status(200).json(invites);
  } catch (error) {
    console.error("Error fetching user invites:", error);
    return res.status(500).json({ error: "Internal server error" });
  }
};

export const checkMembership = async (req: Request, res: Response) => {
  try {
    const { userId, groupId } = req.body;

    // Validate input
    if (!userId || !groupId) {
      return res.status(400).json({
        error: "Missing required fields: userId and groupId are required",
      });
    }

    // Check if the group exists
    const groupCheck = await sql`
      SELECT id FROM groups WHERE id = ${groupId};
    `;
    if (groupCheck.length === 0) {
      return res.status(404).json({ error: "Group not found" });
    }

    // Check if the user is a member of the group
    const membershipCheck = await sql`
      SELECT user_id 
      FROM user_group 
      WHERE user_id = ${userId} AND group_id = ${groupId};
    `;

    const isMember = membershipCheck.length > 0;

    return res.status(200).json({
      groupId,
      userId,
      isMember,
    });
  } catch (error) {
    console.error("Error checking group membership:", error);
    return res.status(500).json({ error: "Internal server error" });
  }
};

export const getGroupMemberLeaderboard = async (
  req: Request,
  res: Response
) => {
  try {
    const groupIdParam = req.query.groupId;

    if (!groupIdParam) {
      return res.status(400).json({ error: "Missing groupId in query" });
    }

    // Convert to string - handles different possible types
    const groupId = String(groupIdParam);

    const members = await sql`
      SELECT 
        p.id, 
        p.first_name, 
        p.last_name, 
        p.username, 
        p.profile_picture,
        ug.points
      FROM user_group ug
      JOIN profile p ON ug.user_id = p.id
      WHERE ug.group_id = ${groupId}
      ORDER BY ug.points DESC;
    `;

    const leaderboard = members.map((member) => ({
      id: member.id,
      name: `${member.first_name} ${member.last_name}`,
      username: member.username,
      profilePicture: member.profile_picture,
      points: member.points ?? 0,
    }));

    return res.status(200).json({ leaderboard });
  } catch (error) {
    console.error("Error fetching group leaderboard:", error);
    return res.status(500).json({ error: "Internal server error" });
  }
};

// Get group leaderboard
export const getGroupLeaderboard = async (req: Request, res: Response) => {
  try {
    const { groupId } = req.body;

    if (!groupId) {
      return res.status(400).json({ error: "Missing groupId" });
    }

    const leaderboard = await sql`
      SELECT 
        u.id AS user_id, 
        u.first_name, 
        u.last_name, 
        u.profile_picture, 
        ug.points, 
        ug.rank
      FROM user_group ug
      JOIN profile u ON ug.user_id = u.id
      WHERE ug.group_id = ${groupId}
      ORDER BY ug.points DESC;
    `;

    res.status(200).json(leaderboard);
  } catch (error) {
    console.error("Error fetching group leaderboard:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};
