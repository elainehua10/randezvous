// group.ts
// All the group processing logic

import sql from "../db"

// Set limit to how many groups a user can create
const MAX_GROUPS_PER_USER = 5; 


// ============= Leader of group functions ===================

// Create a new group
const createGroup = async (userId: string, groupName: string, isPublic: boolean) => {
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
const renameGroup = (userId: string, groupId: number, newName: string) => {
    
}

// Upload an icon for group

// Change group publicity

// Send an invite to other users
const inviteToGroup = async (fromUserId: string, toUserId: string, groupID: string) => {
    
} 

// Remove people from the group


// ============= Member of group functions ===================

// Accept invite

// Leave the a group user is in

// Get locations of other users






