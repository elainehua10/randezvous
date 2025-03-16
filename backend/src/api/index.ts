import express from "express";
import * as user from "./controllers/user";
import MessageResponse from "../interfaces/MessageResponse";
import emojis from "./emojis";
import { requireAuth, requireGroupLeader } from "../middlewares";
import * as group from "./controllers/group";
import { reassignLeader } from "./controllers/group";

const router = express.Router();

router.get<{}, MessageResponse>("/", (req, res) => {
  res.json({
    message: "API - 👋🌎🌍🌏",
  });
});

// User routes
router.use("/emojis", emojis);
router.use("/register", user.register);
router.use("/login", user.login);
router.use("/user/search", requireAuth, user.search);
router.use("/user/block", requireAuth, user.block);
router.use("/change-username", requireAuth, user.changeUsername);
router.use("/logout", requireAuth, user.logout);
router.use("/set-profile-picture", requireAuth, user.setProfilePicture);
router.use("/delete-account", requireAuth, user.deleteAccount);
router.use("/update-location", requireAuth, user.updateLocation);
router.use("/refresh-token", user.refreshToken);
router.use("/get-user-profile-info", requireAuth, user.getUserProfileInfo);

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
router.use("/groups/assign-leader", requireAuth, group.reassignLeader);
router.use("/groups/search", requireAuth, group.searchPublicGroups);
router.use("/groups/join", requireAuth, group.joinGroup);

export default router;
