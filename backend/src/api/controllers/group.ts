// group.ts
// All the group processing logic
import { Request, Response } from 'express';
import sql from "../../db";

// Set limit to how many groups a user can create
const MAX_GROUPS_PER_USER = 5;

// ============= Leader of group functions ===================

// Create a new group
export const createGroup = async (req: Request, res: Response) => {
  const { userId, groupName, isPublic } = req.body;

  // Validate required fields
  if (!userId || !groupName || isPublic === undefined) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  try {
    // Insert new group (user is the leader)
    let res = await sql`
            INSERT INTO groups (name, leader_id, is_public) 
            VALUES (${groupName}, ${userId}, ${isPublic})
            RETURNING id;
        `;

    // Add user to user_group table
    const groupId = res[0].id;
    await sql`
            INSERT INTO user_group (group_id, user_id) 
            VALUES (${groupId}, ${userId})
            RETURNING *;
        `;

    return res[0];
  } catch (error) {
    console.error("Error creating group:", error);
    throw error;
  }
};

// Rename group (only leader can change)
const renameGroup = (userId: string, groupId: number, newName: string) => {};

// Upload an icon for group

// Change group publicity

// Send an invite to other users
const inviteToGroup = async (
  fromUserId: string,
  toUserId: string,
  groupID: string
) => {};

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
