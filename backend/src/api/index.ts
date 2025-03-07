import express from "express";
import {
  register,
  login,
  changeUsername,
  logout,
  setProfilePicture,
  deleteAccount,
  refreshToken,
  getUserProfileInfo,
  search,
} from "./controllers/user";
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
router.use("/user/search", search);
router.use("/change-username", requireAuth, changeUsername);
router.use("/logout", requireAuth, logout);
router.use("/set-profile-picture", requireAuth, setProfilePicture);
router.use("/delete-account", requireAuth, deleteAccount);
router.use("/refresh-token", refreshToken);
router.use("/get-user-profile-info", requireAuth, getUserProfileInfo);

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
router.use("/groups/getgroups", requireAuth, group.getUserGroups);
router.use("/groups/getinvites", requireAuth, group.getUserInvites);
router.use("/groups/members", requireAuth, group.getGroupMembers);
router.use("/groups/check-membership", requireAuth, group.checkMembership);

export default router;
