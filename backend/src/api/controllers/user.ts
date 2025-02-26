import supabase from "../../supabase";
import { Request, Response } from "express";

// register
export const register = async (req: Request, res: Response) => {
  const { email, password, username, firstname, lastname } = req.body;

  if (!email || !password || !username || !firstname || !lastname) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  try {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: { username, firstname, lastname },
      },
    });
    if (error) throw error;
    res.status(201).json({
      message: "User registered successfully",
      user: data.session?.access_token,
    });
  } catch (error) {
    res
      .status(500)
      .json({ error: (error as Error).message || "An unknown error occurred" });
  }
};
