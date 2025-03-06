import supabase from "../../supabase";
import { Request, Response } from "express";
import sql from "../../db";
import sharp from "sharp";
import { UploadedFile } from "express-fileupload";



// Register
export const register = async (req: Request, res: Response) => {
  const { email, password, username, firstname, lastname } = req.body;

  if (!email || !password || !username || !firstname || !lastname) {
    return res.status(400).json({ error: "Missing required fields" });
  }
  // Register a new user
  try {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
    });
    if (error) throw error;
    if (!data.user) {
      throw "User failed to sign in";
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
    console.log(error);
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

export const changeUsername = async (req: Request, res: Response) => {
  const { userId, newUsername } = req.body;
  
  if (!userId || !newUsername) {
    return res.status(400).json({ error: "Missing userId or newUsername" });
  }

  try {
    const existingUser = await sql`
      SELECT id FROM profile WHERE username = ${newUsername}
    `;
    if (existingUser.length > 0) {
      return res.status(400).json({ error: "Username already taken" });
    }
    await sql`
      UPDATE profile SET username = ${newUsername} WHERE id = ${userId}
    `;
    res.status(200).json({ message: "Username updated successfully" });
  } catch (error) {
    res.status(500).json({ error: (error as Error).message || "An unknown error occurred" });
  }
};

// Set profile picture

export const setProfilePicture = async (req: Request, res: Response) => {
  const { userId } = req.body;
  if (!userId) {
    return res.status(400).json({ error: "Missing userId" });
  }
  try {
    // Extract file
    const iconFile = req.files?.icon as UploadedFile;
    if (!iconFile) {
      return res.status(400).json({ error: "No file uploaded" });
    }

    // Validate file type
    const allowedExtensions = [".png", ".jpg", ".jpeg", ".gif"];
    const fileExtension = iconFile.name.split(".").at(-1);
    if (!allowedExtensions.includes(fileExtension || "")) {
      return res.status(400).json({ error: "Invalid file type. Only PNG, JPG, JPEG, and GIF are allowed." });
    }

    // Size the file down
    const resizedImageBuffer = await sharp(iconFile.data)
      .resize(200, 200)
      .toBuffer();

    // Upload to Supabase Storage (Bucket: "images")
    const fileName = `user_${userId}_${Date.now()}${fileExtension}`;
    const { error } = await supabase.storage
      .from("images")
      .upload(fileName, resizedImageBuffer, {
        cacheControl: "3600",
        upsert: false,
        contentType: iconFile.mimetype,
      });
    
    if (error) {
      console.error("Error uploading profile picture:", error);
      return res.status(500).json({ error: "Error uploading profile picture" });
    }
    
    // Get public URL of the uploaded image
    const { data } = await supabase.storage
    .from("profile_pictures")
    .getPublicUrl(fileName);

    // Update user profile with the new profile picture URL
    await sql`
      UPDATE profile
      SET profile_picture_url = ${data.publicUrl}
      WHERE id = ${userId}
    `;
    return res.status(200).json({ success: true, profilePictureUrl: data.publicUrl });
  } catch (error) {
    return res.status(500).json({ error: "Internal server error" });
  }
}

// Logout of account

export const logout = async (req: Request, res: Response) => {
  try {
    const { error } = await supabase.auth.signOut();
    if (error) throw error
    res.status(200).json({ message: "Logout successful" });
  } catch (error) {
    res.status(500).json({ error: (error as Error).message || "Internal server error" });
  }
};

// Delete account
export const deleteAccount = async (req: Request, res: Response) => {
  const { userId } = req.body;
  if (!userId) {
    return res.status(400).json({ error: "Missing userId"});
  }
  try {
    await sql`
      DELETE FROM profile WHERE id = ${userId};
    `;
    const { data, error } = await supabase.auth.admin.deleteUser(userId);
    if (error) {
      return res.status(500).json({ error: error.message });
    }
    res.status(200).json({ message: 'Account deleted successfully',
    });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
}

// refresh
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


