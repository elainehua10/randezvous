// group.ts
// All the group processing logic
import { Request, Response } from "express";
import sql from "../../db";

// Set limit to how many groups a user can create
const MAX_GROUPS_PER_USER = 5;

// ============= Leader of group functions ===================

// Create a new group
export const createGroup = async (req: Request, res: Response) => {
  try {
    // Check fields
    const { userId, groupName, isPublic } = req.body;
    if (!userId || !groupName || !isPublic) {
      return res.status(400).json({ error: "Missing required fields" });
    }
    console.log(`
            INSERT INTO groups (name, is_public, leader_id) 
            VALUES (${groupName}, ${isPublic ? 'TRUE' : 'FALSE'}, ${userId})
            RETURNING id;
        `)

    // Insert new group (user is the leader)
    let newGroup = await sql`
            INSERT INTO groups (name, is_public, leader_id) 
            VALUES (${groupName}, ${isPublic ? 'TRUE' : 'FALSE'}, ${userId})
            RETURNING id;
        `;

    // Add user to user_group table
    const groupId = newGroup[0].id;
    await sql`
            INSERT INTO user_group (group_id, user_id) 
            VALUES (${groupId}, ${userId})
            RETURNING *;
        `;

    return res.status(200).json({ success: true, group: newGroup[0] });
  } catch (error) {
    console.error("Error creating group:", error);
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

    // Check group ownership
    const group = await sql`
            SELECT * FROM groups WHERE id = ${groupId} AND leader_id = ${userId};
        `;
    if (group.length === 0) {
      return res.status(403).json({ error: "You are not authorized to rename this group." });
    }

    // Check for duplicate name 
    const existingGroup = await sql`
            SELECT * FROM groups WHERE name = ${newName} AND id <> ${groupId};
        `;
    if (existingGroup.length > 0) {
      return res.status(409).json({ error: "A group with this name already exists. Please choose a different name." });
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
    const { userId, groupId, iconUrl } = req.body;
    if (!userId || !groupId || !iconUrl) {
      return res.status(400).json({ error: "Missing required fields" });
    } 
    // Check group ownership
    const group = await sql`
            SELECT * FROM groups WHERE id = ${groupId} AND leader_id = ${userId};
        `;
    if (group.length === 0) {
      return res.status(403).json({ error: "You are not authorized to rename this group." });
    }
    // Update group icon
    const updatedGroup = await sql`
            UPDATE groups
            SET icon_url = ${iconUrl}
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
    if (!userId || !groupId || !isPublic) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    // Check group ownership
    const group = await sql`
            SELECT * FROM groups WHERE id = ${groupId} AND leader_id = ${userId};
        `;
    if (group.length === 0) {
      return res.status(403).json({ error: "You are not authorized to rename this group." });
    }

    // Update group publicity
    const updatedPublicity = await sql`
            UPDATE groups 
            SET name = ${isPublic} 
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
  const { userId, toUserId, groupId } = req.body;

  if (!userId || !toUserId || !groupId) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  try {
    let result = await sql`
            INSERT INTO invite (from_user_id, to_user_id, group_id) 
            VALUES (${userId}, ${toUserId}, ${groupId})
            RETURNING id;
        `;

    // Add user to user_group table
    const inviteId = result[0].id;

    return res.status(200).json({ message: "Invite Created", inviteId });
  } catch (error) {
    console.error("Error creating group:", error);
    res.status(500).json({ message: "error lol" });
    throw error;
  }
};

// Remove people from the group
export const removeFromGroup = async (req: Request, res: Response) => {
  const { userId, removingUserId, groupId } = req.body;

  if (!userId || !removingUserId || !groupId) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  try {
    // Check group ownership
    const group = await sql`
            SELECT * FROM groups WHERE id = ${groupId} AND leader_id = ${userId};
        `;
    if (group.length === 0) {
      return res.status(403).json({ error: "You are not authorized to rename this group." });
    }

    // Remove user from user_group table
    await sql`
            DELETE FROM user_group
            WHERE user_id = ${removingUserId} AND group_id = ${groupId}
        `;

    return res.status(200).json({ message: "User removed from group" });
  } catch (error) {
    console.error("Error removing user from group:", error);
    res.status(500).json({ message: "error lol" });
    throw error;
  }
};

// ============= Member of group functions ===================

// Accept invite
export const acceptInvite = async (req: Request, res: Response) => {
  const { userId, groupId } = req.body;

  if (!userId || !groupId) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  try {
    // Check if there's a pending invite for this user and group
    const invite = await sql`
      SELECT * FROM invite
      WHERE group_id = ${groupId} 
        AND to_user_id = ${userId} 
        AND status = 'pending'
      LIMIT 1;
    `;

    if (invite.length === 0) {
      return res.status(404).json({ error: 'No pending invite found for this user and group' })
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
      WHERE group_id = ${groupId}
        AND to_user_id = ${userId};
    `;

    return res.status(200).json({ message: 'Invite accepted. You have been added to the group.' });

  } catch (error) {
    console.error('Error accepting invite:', error);
    return res.status(500).json({
      error: (error as Error).message || 'An unknown error occurred',
    });
  }
};


// Leave the a group user is in
export const leaveGroup = async (req: Request, res: Response) => {
  const { userId, groupId } = req.body;

  if (!userId || !groupId) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  try {
    // Remove user from user_group table
    await sql`
            DELETE FROM user_group
            WHERE user_id = ${userId} AND group_id = ${groupId}
        `;

    return res.status(200).json({ message: 'User removed from group' });
  } catch (error) {
    console.error('Error leaving group:', error);
    return res.status(500).json({
      error: (error as Error).message || 'An unknown error occurred',
    });
  }
};

// Get locations of other users
export const getGroupLocations = async (req: Request, res: Response) => {
  const { userId, groupId } = req.body;

  if (!userId || !groupId) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  try {
    // Check if user is in the group
    const userInGroup = await sql`
            SELECT * FROM user_group
            WHERE user_id = ${userId} AND group_id = ${groupId}
        `;
    if (userInGroup.length === 0) {
      return res.status(403).json({ error: 'You are not a member of this group' });
    }

    // Get locations of other users in the group
    const locations = await sql`
            SELECT p.longitude, p.latitude
            FROM user_group ug
            JOIN profile p ON ug.user_id = p.user_id
            WHERE ug.group_id = ${groupId}
        `;

    return res.status(200).json({ locations });
  } catch (error) {
    console.error('Error getting group locations:', error);
    return res.status(500).json({
      error: (error as Error).message || 'An unknown error occurred',
    });
  }
};
