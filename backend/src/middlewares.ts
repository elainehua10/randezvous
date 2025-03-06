import { NextFunction, Request, Response } from "express";

import ErrorResponse from "./interfaces/ErrorResponse";
import jwt from "jsonwebtoken";
import sql from "./db";

export function notFound(req: Request, res: Response, next: NextFunction) {
  res.status(404);
  const error = new Error(`🔍 - Not Found - ${req.originalUrl}`);
  next(error);
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars
export function errorHandler(
  err: Error,
  req: Request,
  res: Response<ErrorResponse>,
  next: NextFunction
) {
  const statusCode = res.statusCode !== 200 ? res.statusCode : 500;
  res.status(statusCode);
  res.json({
    message: err.message,
    stack: process.env.NODE_ENV === "production" ? "🥞" : err.stack,
  });
}

// middleware for requiring user to be loggedin
export function requireAuth(
  req: Request,
  res: Response<ErrorResponse>,
  next: NextFunction
) {
  const authorizationHeader = req.headers.authorization;
  if (!authorizationHeader) {
    const error = new Error("Unauthorized: Missing authorization header");
    next(error);
    return;
  }

  const token = authorizationHeader.split(" ").at(-1);

  if (!token) {
    const error = new Error("Unauthorized: Missing authorization token");
    next(error);
    return;
  }

  const decoded = jwt.verify(token, process.env.JWT_SECRET!);

  if (typeof decoded == "string") {
    const error = new Error("Unauthorized: Unrecognized token pattern");
    next(error);
    return;
  }

  if (!decoded || !decoded.user_metadata || !decoded.user_metadata.sub) {
    const error = new Error("Unauthorized: Unrecognized token pattern");
    next(error);
    return;
  }

  console.log(Date.now() / 1000);
  console.log(decoded.exp || 0 < Date.now() / 1000);

  if ((decoded.exp || 0) < Date.now() / 1000) {
    const error = new Error("Unauthorized: Token Expired");
    next(error);
    return;
  }

  req.body.userId = decoded.user_metadata.sub;

  next();
}

// middleware for requiring user to be leader of group
export async function requireGroupLeader(
  req: Request,
  res: Response<ErrorResponse>,
  next: NextFunction
) {
  const { userId, groupId } = req.body;

  if (!userId || !groupId) {
    const error = new Error("Missing required fields");
    next(error);
    return;
  }

  const group = await sql`
            SELECT * FROM groups WHERE id = ${groupId} AND leader_id = ${userId};
        `;
  if (group.length === 0) {
    const error = new Error("You are not authorized to rename this group.");
    next(error);
    return;
  }
  next();
}
