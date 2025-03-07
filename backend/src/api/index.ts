import express from "express";
import { register, login, refreshToken } from "./controllers/user";
import MessageResponse from "../interfaces/MessageResponse";
import emojis from "./emojis";
import { requireAuth, requireGroupLeader } from "../middlewares";
import * as group from "./controllers/group";

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

// Group routes
router.use("/groups/members", requireAuth, group.getGroupMembers);
router.use("/groups/create", requireAuth, group.createGroup);
router.use(
  "/groups/rename",
  requireAuth,
  requireGroupLeader,
  group.renameGroup
);
router.use(
  "/groups/setpub",
  requireAuth,
  requireGroupLeader,
  group.setPublicity
);
router.use(
  "/groups/invite",
  requireAuth,
  requireGroupLeader,
  group.inviteToGroup
);
router.use("/groups/icon", requireAuth, requireGroupLeader, group.uploadIcon);
router.use(
  "/groups/remove",
  requireAuth,
  requireGroupLeader,
  group.removeFromGroup
);
router.use("/groups/accept", requireAuth, group.acceptInvite);
router.use("/groups/leave", requireAuth, group.leaveGroup);
router.use("/groups/locations", requireAuth, group.getGroupLocations);
router.use("/groups/members", requireAuth, group.getGroupMembers);


export default router;
