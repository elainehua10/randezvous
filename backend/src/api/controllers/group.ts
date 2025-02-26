// group.ts
// All the group processing logic
import { Request, Response } from "express";
import sql from "../../db";

// Set limit to how many groups a user can create
const MAX_GROUPS_PER_USER = 5;

// ============= Leader of group functions ===================

// Create a new group
const createGroup = async (req: Request, res: Response) => {
  try {
    // Check fields
    const { userId, groupName, isPublic } = req.body;
    if (!userId || !groupName || !isPublic) {
      return res.status(400).json({ error: "Missing required fields" });
    }
    console.log(`
            INSERT INTO groups (name, is_public, leader_id) 
            VALUES (${groupName}, ${isPublic ? 'TRUE' :'FALSE'}, ${userId})
            RETURNING id;
        `)

    // Insert new group (user is the leader)
    let newGroup = await sql`
            INSERT INTO groups (name, is_public, leader_id) 
            VALUES (${groupName}, ${isPublic ? 'TRUE' :'FALSE'}, ${userId})
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
export { createGroup };

// Rename group (only leader can change)
const renameGroup = async (req: Request, res: Response) => {
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
    return res.status(500).json({ error: "Internal server error" });
  }

};
export { renameGroup };

// Upload an icon for group

// Change group publicity
const setPublicity = async (req: Request, res: Response) => {
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
            UPDATE is_public 
            SET name = ${isPublic} 
            WHERE id = ${groupId}
            RETURNING *;
        `;

    return res.status(200).json({ success: true, group: updatedPublicity[0] });
  } catch (error) {
    console.error("Error changing group publicity:", error);
    return res.status(500).json({ error: "Internal server error" });
  }
};
export { setPublicity };

// Send an invite to other users
const inviteToGroup = async (
  fromUserId: string,
  toUserId: string,
  groupID: string
) => { };

// Remove people from the group

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

    if (!invite) {
      return res.status(404).json({ error: 'No pending invite found for this user and group'})
    }
    
    // Adding user to the user_group table
    await sql`
      INSERT INTO user_group (group_id, user_id)
      VALUES (${groupId}, ${userId})
      ON CONFLICT DO NOTHING;
    `;

    // Update the invite status to 'accepted'
    await sql`
      UPDATE invites
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

// Get locations of other users
