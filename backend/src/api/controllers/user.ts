import supabase from "../../supabase";
import { Request, Response } from "express";
import sql from "../../db";

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
      throw "User failed to sign in"
    }
    await sql`
            INSERT INTO profile (id, username, first_name, last_name)
            VALUES (${data.user.id}, ${username}, ${firstname}, ${lastname});
            `;

    res.status(201).json({
      message: "User registered successfully",
      user: data.session
    });
  } catch (error) {
    console.log(error)
    res.status(500).json({ error: (error as Error).message || "An unknown error occurred" });
  }
};

// Log in
export const login = async (req: Request, res: Response) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Missing email or password' });
  }

  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });

    if (error) throw error;

    res.status(200).json({
      message: 'Login successful',
      user: data.user,
      access_token: data.session?.access_token,
      refresh_token: data.session?.refresh_token,
    });
  } catch (error) {
    res.status(401).json({ error: (error as Error).message || 'Invalid login credentials' });
  }
};
