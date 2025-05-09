import supabase from "../../supabase";
import { Request, Response } from "express";
import sql from "../../db";
import sharp from "sharp";
import { UploadedFile } from "express-fileupload";
import { sendNotification } from "../../notifications";

// Register
export const register = async (req: Request, res: Response) => {
  const { email, password, username, firstname, lastname } = req.body;

  if (!email || !password || !username || !firstname || !lastname) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  try {
    const existingUser = await sql`
      SELECT id FROM profile WHERE username = ${username};
    `;
    if (existingUser.length > 0) {
      return res.status(400).json({ error: "Username already taken" });
    }
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
    });
    if (error) throw error;
    if (!data.user) {
      throw new Error("User failed to sign in");
    }

    await sql`
      INSERT INTO profile (id, username, first_name, last_name)
      VALUES (${data.user.id}, ${username}, ${firstname}, ${lastname});
    `;

    res.status(201).json({
      message: "User registered successfully",
      session: data.session,
    });
  } catch (error) {
    console.error(error);
    res
      .status(500)
      .json({ error: (error as Error).message || "An unknown error occurred" });
  }
};

// Log in
export const login = async (req: Request, res: Response) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: "Missing email or password" });
  }

  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) throw error;

    console.log(data);

    res.status(200).json({
      message: "Login successful",
      session: data.session,
    });
  } catch (error) {
    res
      .status(401)
      .json({ error: (error as Error).message || "Invalid login credentials" });
  }
};

// Change username
export const changeUsername = async (req: Request, res: Response) => {
  const { userId, newUsername } = req.body;

  if (!userId || !newUsername) {
    return res.status(400).json({ error: "Missing userId or newUsername" });
  }

  try {
    const currentUser = await sql`
      SELECT username FROM profile WHERE id = ${userId};
    `;
    if (currentUser.length > 0 && currentUser[0].username == newUsername) {
      return res.status(400).json({
        error: "The new username must be different from the current one",
      });
    }
    const existingUser = await sql`
      SELECT id FROM profile WHERE username = ${newUsername};
    `;
    if (existingUser.length > 0) {
      return res.status(400).json({ error: "Username already taken" });
    }
    await sql`
      UPDATE profile SET username = ${newUsername} WHERE id = ${userId};
    `;
    res.status(200).json({ message: "Username updated successfully" });
  } catch (error) {
    res
      .status(500)
      .json({ error: (error as Error).message || "An unknown error occurred" });
  }
};

// Set profile picture
export const setProfilePicture = async (req: Request, res: Response) => {
  const { userId, deletePhoto } = req.body;
  if (!userId) {
    return res.status(400).json({ error: "Missing userId" });
  }

  if (deletePhoto) {
    try {
      await sql`
        UPDATE profile
        SET profile_picture = NULL
        WHERE id = ${userId};
      `;
      return res
        .status(200)
        .json({ message: "Profile picture deleted successfully" });
    } catch (error) {
      console.error(error);
      return res.status(500).json({ error: "Internal server error" });
    }
  } else {
    try {
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
      const fileName = `user_${userId}_${Date.now()}.${fileExtension}`;
      const { error } = await supabase.storage
        .from("images")
        .upload(fileName, resizedImageBuffer, {
          cacheControl: "3600",
          upsert: false,
          contentType: iconFile.mimetype,
        });

      if (error) {
        console.error("Error uploading profile picture:", error);
        return res
          .status(500)
          .json({ error: "Error uploading profile picture" });
      }

      // Get public URL of the uploaded image
      const { data } = await supabase.storage
        .from("images")
        .getPublicUrl(fileName);

      // Update user profile with the new profile picture URL
      await sql`
        UPDATE profile
        SET profile_picture = ${data.publicUrl}
        WHERE id = ${userId};
      `;
      return res
        .status(200)
        .json({ success: true, profilePictureUrl: data.publicUrl });
    } catch (error) {
      console.log(error);
      return res.status(500).json({ error: "Internal server error" });
    }
  }
};

// Logout of account

export const logout = async (req: Request, res: Response) => {
  try {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
    res.status(200).json({ message: "Logout successful" });
  } catch (error) {
    res
      .status(500)
      .json({ error: (error as Error).message || "Internal server error" });
  }
};

export const deleteAccount = async (req: Request, res: Response) => {
  const { userId } = req.body;

  if (!userId) {
    return res.status(400).json({ error: "Missing userId" });
  }

  try {
    console.log("Deleting user with ID:", userId);
    await Promise.all([
      sql`DELETE FROM profile WHERE id = ${userId};`,
      sql`DELETE FROM user_group WHERE user_id = ${userId};`,
      sql`DELETE FROM user_beacons WHERE user_id = ${userId};`,
      sql`DELETE FROM blocked WHERE user_id = ${userId} OR blocked_id = ${userId};`,
      sql`DELETE FROM invite WHERE from_user_id = ${userId} OR to_user_id = ${userId};`,
      sql`DELETE FROM groups WHERE leader_id = ${userId};`,
    ]);

    const { error: authError } = await supabase.auth.admin.deleteUser(userId);
    if (authError) {
      console.error(
        "Error deleting user from authentication system:",
        authError
      );
      return res.status(500).json({ error: authError.message });
    }

    res.status(200).json({ message: "Account deleted successfully" });
  } catch (error) {
    console.error("Error during account deletion:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

// Refresh token
export const refreshToken = async (req: Request, res: Response) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  try {
    const { data, error } = await supabase.auth.refreshSession({
      refresh_token: refreshToken,
    });

    if (error) {
      console.log(refreshToken);
      throw error;
    }

    res.status(200).json({
      message: "Refresh successful",
      session: data.session,
    });
  } catch (error) {
    res
      .status(401)
      .json({ error: (error as Error).message || "Invalid Refresh Token" });
  }
};

export const search = async (req: Request, res: Response) => {
  const { username, userId } = req.body;

  if (!username) {
    return res.status(400).json({ error: "Missing username parameter" });
  }

  try {
    const results = await sql`
      SELECT id, username, first_name, last_name, profile_picture
      FROM profile
      WHERE (username LIKE ${`%${username}%`} 
             OR first_name LIKE ${`%${username}%`} 
             OR last_name LIKE ${`%${username}%`})
        AND id NOT IN (
          SELECT blocked_id FROM blocked WHERE user_id = ${userId}
          UNION
          SELECT user_id FROM blocked WHERE blocked_id = ${userId}
        )
      LIMIT 4;
    `;

    if (results.length === 0) {
      return res
        .status(200)
        .json({ message: "No users found matching that username.", users: [] });
    }

    res.status(200).json({ message: "Search results:", users: results });
  } catch (error) {
    console.error("Search error:", error);
    res.status(500).json({
      error:
        (error as Error).message || "An unknown error occurred during search",
    });
  }
};

export const block = async (req: Request, res: Response) => {
  const { blockedId, userId } = req.body;

  if (!blockedId || !userId) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  try {
    await sql`
      INSERT INTO blocked (user_id, blocked_id) VALUES (${userId}, ${blockedId}) ON CONFLICT DO NOTHING;`;

    res.status(200).json({ message: "User blocked successfully" });
  } catch (error) {
    console.log(error);
    res.status(500).json({ error: "Failed to block user" });
  }
};

// Enable or disable notifications
export const toggleNotifications = async (req: Request, res: Response) => {
  const { userId, enableNotifications } = req.body;
  if (!userId || enableNotifications === undefined) {
    return res.status(400).json({ error: "Missing required fields" });
  }
  try {
    await sql`
      UPDATE profile
      SET notifications_enabled = ${enableNotifications}
      WHERE id = ${userId};
    `;
    res.status(200).json({
      message: `Notifications ${
        enableNotifications ? "enabled" : "disabled"
      } successfully`,
    });
  } catch (error) {
    console.error("Error updating notifcation preferences: ", error);
    res
      .status(500)
      .json({ error: "Failed to update notification preferences" });
  }
};

// Retrieve user profile information
export const getUserProfileInfo = async (req: Request, res: Response) => {
  try {
    const userId = req.body.userId;
    const result = await sql`
      SELECT first_name, last_name, username, profile_picture, notifications_enabled
      FROM profile 
      WHERE id = ${userId};
    `;

    if (result.length === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    const {
      first_name,
      last_name,
      username,
      profile_picture,
      notifications_enabled,
    } = result[0];

    const friends = await sql`
      SELECT p.id, p.username, p.first_name, p.last_name, p.profile_picture
      FROM friend_requests f
      JOIN profile p ON (p.id = CASE 
        WHEN f.sender_id = ${userId} THEN f.receiver_id
        WHEN f.receiver_id = ${userId} THEN f.sender_id
        ELSE NULL END)
      WHERE (f.sender_id = ${userId} OR f.receiver_id = ${userId})
        AND f.status = 'accepted';
    `;

    const pendingRequests = await sql`
        SELECT p.id, p.username, p.first_name, p.last_name, p.profile_picture
        FROM friend_requests f
        JOIN profile p ON f.sender_id = p.id
        WHERE f.receiver_id = ${userId} AND f.status = 'pending';
    `;

    res.status(200).json({
      first_name,
      last_name,
      username,
      profile_picture,
      notifications_enabled,
      friends,
      pending_requests: pendingRequests,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};

// retrieve other user profile information
export const getMemberProfile = async (req: Request, res: Response) => {
  try {
    const userId = req.body.targetUserId;
    const currId = req.body.userId;
    const result = await sql`
      SELECT first_name, last_name, username, profile_picture, num_groups
      FROM profile
      WHERE id = ${userId};
    `;

    if (result.length == 0) {
      return res.status(404).json({ error: "User not found" });
    }

    if (!currId || !userId) {
      return res
        .status(400)
        .json({ error: "Missing userId or current user ID" });
    }

    const isFriend = await sql`
      SELECT 1 FROM friend_requests
      WHERE 
        ((sender_id = ${currId} AND receiver_id = ${userId}) OR
        (sender_id = ${userId} AND receiver_id = ${currId}))
        AND status = 'accepted'
      LIMIT 1;
    `;

    const isRequestPending = await sql`
      SELECT 1 FROM friend_requests
      WHERE sender_id = ${currId} AND receiver_id = ${userId} AND status = 'pending'
      LIMIT 1;
    `;

    const rawGroups = await sql`
      SELECT g.id, g.name, g.icon_url, ug.points, ug.rank
      FROM user_group ug
      JOIN groups g ON ug.group_id = g.id
      WHERE ug.user_id = ${userId};
    `;

    const groups = rawGroups.map((group: any) => ({
      id: group.id,
      name: group.name,
      icon_url: group.icon_url,
      points: group.points,
      rank: group.rank,
    }));

    res.status(200).json({
      profile: {
        first_name: result[0].first_name,
        last_name: result[0].last_name,
        username: result[0].username,
        profile_picture: result[0].profile_picture,
      },
      groups: groups,
      is_friend: isFriend.length > 0,
      is_request_pending: isRequestPending.length > 0,
    });
  } catch (error) {
    console.error("Error fetching user profile:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const sendFriendRequest = async (req: Request, res: Response) => {
  const { senderId, receiverId } = req.body;

  if (!senderId || !receiverId) {
    return res.status(400).json({ error: "Missing senderId or receiverId" });
  }
  if (senderId === receiverId) {
    return res
      .status(400)
      .json({ error: "Cannot send a friend request to yourself" });
  }

  try {
    // Check if users are already friends
    const existingFriend = await sql`
      SELECT 1 FROM friend_requests
      WHERE ((sender_id = ${senderId} AND receiver_id = ${receiverId})
         OR (sender_id = ${receiverId} AND receiver_id = ${senderId}))
        AND status = 'accepted';
    `;
    if (existingFriend.length > 0) {
      return res.status(400).json({ error: "You are already friends" });
    }

    const pendingRequest = await sql`
      SELECT 1 FROM friend_requests
      WHERE sender_id = ${senderId} AND receiver_id = ${receiverId} AND status = 'pending';
    `;
    if (pendingRequest.length > 0) {
      return res.status(400).json({ error: "Friend request already sent" });
    }

    // Fetch sender's username and receiver's notification settings
    const usersInfo = await sql`
      SELECT 
        sender.username AS sender_username,
        receiver.notifications_enabled
      FROM profile sender, profile receiver
      WHERE sender.id = ${senderId} AND receiver.id = ${receiverId};
    `;

    if (usersInfo.length === 0) {
      return res.status(404).json({ error: "One or both users not found" });
    }

    const { sender_username, notifications_enabled } = usersInfo[0];

    // Insert the friend request
    await sql`
      INSERT INTO friend_requests (sender_id, receiver_id)
      VALUES (${senderId}, ${receiverId});
    `;

    // Send notification to the recipient if notifications are enabled
    if (notifications_enabled) {
      console.log("Sending friend request notification to user:", receiverId);
      await sendNotification(
        receiverId,
        "Friend Request",
        `${sender_username} sent you a friend request.`
      );
    }

    res.status(200).json({ message: "Friend request sent successfully" });
  } catch (error) {
    console.error("Error sending friend request:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

// Accept friend request
export const acceptFriendRequest = async (req: Request, res: Response) => {
  const { senderId, receiverId } = req.body;

  if (!senderId || !receiverId) {
    return res.status(400).json({ error: "Missing senderId or receiverId" });
  }

  try {
    // Update the friend request to accepted
    const updated = await sql`
      UPDATE friend_requests
      SET status = 'accepted', updated_at = timezone('utc', now())
      WHERE sender_id = ${senderId} AND receiver_id = ${receiverId}
      RETURNING *;
    `;

    if (updated.length === 0) {
      return res.status(404).json({ error: "Friend request not found" });
    }

    res
      .status(200)
      .json({ message: "Friend request accepted", request: updated[0] });
  } catch (err) {
    console.error("Error accepting friend request:", err);
    res.status(500).json({ error: "Internal server error" });
  }
};

// Decline friend request
export const declineFriendRequest = async (req: Request, res: Response) => {
  const { senderId, receiverId } = req.body;

  if (!senderId || !receiverId) {
    return res.status(400).json({ error: "Missing senderId or receiverId" });
  }

  try {
    await sql`
      DELETE FROM friend_requests
      WHERE sender_id = ${senderId}
        AND receiver_id = ${receiverId}
        AND status = 'pending';
    `;

    res.status(200).json({ message: "Friend request declined" });
  } catch (error) {
    console.error("Error declining request:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const setDeviceId = async (req: Request, res: Response) => {
  try {
    const { userId, deviceId } = req.body;

    // Validate required fields
    if (!userId || !deviceId) {
      return res
        .status(400)
        .json({ error: "userId and deviceId are required" });
    }

    // Update the device_id in the profile table
    const result = await sql`
      UPDATE profile
      SET device_id = ${deviceId}
      WHERE id = ${userId}
      RETURNING id, username, device_id;
    `;

    if (result.length === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    res.status(200).json({
      message: "Device ID updated successfully",
      user: {
        id: result[0].id,
        username: result[0].username,
        device_id: result[0].device_id,
      },
    });
  } catch (error) {
    console.error("Error setting device ID:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const getUserGroups = async (req: Request, res: Response) => {
  try {
    const userId = req.body.userId;

    if (!userId) {
      return res.status(400).json({ error: "Missing userId" });
    }

    const groups = await sql`
      SELECT g.id, g.name, g.icon_url
      FROM user_group ug
      JOIN groups g ON ug.group_id = g.id
      WHERE ug.user_id = ${userId};
    `;

    res.status(200).json(groups);
  } catch (error) {
    console.error("Error fetching user groups:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const getUserAchievements = async (req: Request, res: Response) => {
  // Check all possible achievements first
  const { userId } = req.body;
  await checkAllAchievements(userId);

  // Then fetch and return unlocked/locked achievements
  const unlocked = await sql`
    SELECT a.id, a.name, a.description, ua.unlocked_at
    FROM user_achievements ua
    JOIN achievements a ON ua.achievement_id = a.id
    WHERE ua.user_id = ${userId};
  `;

  const allAchievements = await sql`SELECT * FROM achievements;`;

  const locked = allAchievements.filter(
    (a) => !unlocked.some((ua) => ua.id === a.id)
  );

  res.status(200).json({
    unlocked: unlocked,
    locked: locked,
  });
};

export const checkAllAchievements = async (userId: string) => {
  await Promise.all([
    checkFriendAchievements(userId),
    checkGroupAchievements(userId),
  ]);
};

export const checkFriendAchievements = async (userId: string) => {
  const friends = await sql`
    SELECT COUNT(*) AS count FROM friend_requests
    WHERE 
      (sender_id = ${userId} OR receiver_id = ${userId})
      AND status = 'accepted';
  `;

  const friendCount = parseInt(friends[0].count);

  // Check multiple friend achievements
  await checkAndAwardAchievement(userId, 1, friendCount >= 3); // Social Butterfly (5 friends)
};

// Join one group achievement
export const checkGroupAchievements = async (userId: string) => {
  const groups = await sql`
    SELECT COUNT(*) AS count FROM user_group
    WHERE user_id = ${userId};
  `;

  const groupCount = parseInt(groups[0].count);
  await checkAndAwardAchievement(userId, 2, groupCount >= 1);
};

export const checkAndAwardAchievement = async (
  userId: string,
  achievementId: number,
  condition: boolean
) => {
  if (!condition) return; // Skip if condition not met

  // Check if already awarded
  const existing = await sql`
    SELECT 1 FROM user_achievements
    WHERE user_id = ${userId} AND achievement_id = ${achievementId};
  `;

  if (existing.length === 0) {
    // Award new achievement with timestamp
    await sql`
      INSERT INTO user_achievements (user_id, achievement_id, unlocked_at)
      VALUES (${userId}, ${achievementId}, NOW());
    `;

    const achievement = await sql`
      SELECT 1 FROM achievements
      WHERE id = ${achievementId};
    `;

    if (achievement.length === 0) {
      console.error("Achievement not found:", achievementId);
      return;
    }

    // Send notification
    const { name, description } = achievement[0];
    console.log(
      `Achievement unlocked: ${name} - ${description} for user ${userId}`
    );
    sendNotification(userId, `Achievement Unlocked: ${name}`, `${description}`);
  }
};

// Reset password
export const resetPassword = async (req: Request, res: Response) => {
  const { email, newPassword, confirmPassword, userId } = req.body;

  if (!email || !newPassword || !confirmPassword || !userId) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  if (newPassword !== confirmPassword) {
    return res.status(400).json({ error: "Passwords do not match" });
  }

  try {
    const { data: userInfo, error: userError } =
      await supabase.auth.admin.getUserById(userId);

    if (userError) {
      return res.status(500).json({ error: userError.message });
    } else if (!userInfo?.user?.email) {
      return res.status(404).json({ error: "User not found" });
    }

    const registeredEmail = userInfo.user.email;

    if (registeredEmail !== email) {
      return res
        .status(403)
        .json({ error: "You can only reset your own password" });
    }

    const { error: updateError } = await supabase.auth.admin.updateUserById(
      userId,
      {
        password: newPassword,
      }
    );

    if (updateError) {
      return res.status(500).json({ error: updateError.message });
    }

    return res.status(200).json({ message: "Password reset successful" });
  } catch (err) {
    console.error("Password reset error:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
};
