import express from "express";
import { register, login, refreshToken } from "./controllers/user";
import MessageResponse from "../interfaces/MessageResponse";
import emojis from "./emojis";
import { inviteToGroup, createGroup } from "./controllers/group";
import { requireAuth, requireGroupLeader } from "../middlewares";
import * from "./controllers/group";


const router = express.Router();

router.get<{}, MessageResponse>("/", (req, res) => {
  res.json({
    message: "API - 👋🌎🌍🌏",
  });
});

// User routes
router.use("/emojis", emojis);
router.use("/register", register);
router.use("/login", login);
router.use("/refresh-token", refreshToken);
router.use("/groups/create", requireAuth, createGroup);

router.use("/group/invite", requireAuth, requireGroupLeader, inviteToGroup);

// Group routes
router.use("/groups/create", requireAuth, createGroup);
router.use("/groups/rename", requireAuth, requireGroupLeader, renameGroup);
router.use("/groups/setpub", requireAuth, requireGroupLeader, setPublicity);
router.use("/groups/invite", requireAuth, requireGroupLeader, inviteToGroup);
router.use("/groups/icon", requireAuth, requireGroupLeader, uploadIcon);
router.use("/groups/remove", requireAuth, requireGroupLeader, removeFromGroup);
router.use("/groups/accept", requireAuth, acceptInvite);
router.use("/groups/leave", requireAuth, leaveGroup);
router.use("/groups/locations", requireAuth, getGroupLocations);

export default router;
