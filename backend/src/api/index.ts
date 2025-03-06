import express from "express";
import { register, login, refreshToken } from "./controllers/user";
import MessageResponse from "../interfaces/MessageResponse";
import emojis from "./emojis";
import { inviteToGroup, createGroup } from "./controllers/group";
import { requireAuth, requireGroupLeader } from "../middlewares";

const router = express.Router();

router.get<{}, MessageResponse>("/", (req, res) => {
  res.json({
    message: "API - 👋🌎🌍🌏",
  });
});

router.use("/emojis", emojis);
router.use("/register", register);
router.use("/login", login);
router.use("/refresh-token", refreshToken);
router.use("/groups/create", requireAuth, createGroup);

router.use("/group/invite", requireAuth, requireGroupLeader, inviteToGroup);

export default router;
