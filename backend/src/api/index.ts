import express from "express";
import * as user from "./controllers/user";
import MessageResponse from "../interfaces/MessageResponse";
import emojis from "./emojis";
import { requireAuth, requireGroupLeader } from "../middlewares";
import * as group from "./controllers/group";
import * as beacon from "./controllers/beacon";

const router = express.Router();

router.get<{}, MessageResponse>("/", (req, res) => {
  res.json({
    message: "API - 👋🌎🌍🌏 NO YES??!!!!!!!PLEASE",
  });
});

// User routes
router.use("/manual-spawn", beacon.manualSpawn);

router.use("/emojis", emojis);
router.use("/register", user.register);
router.use("/login", user.login);
router.use("/set-device-id", requireAuth, user.setDeviceId);
router.use("/user/search", requireAuth, user.search);
router.use("/user/block", requireAuth, user.block);
router.use("/user/view-profile", requireAuth, user.getMemberProfile);
router.use("/user/send-friend-request", requireAuth, user.sendFriendRequest);
router.use("/user/accept-friend-request", user.acceptFriendRequest);
router.use(
  "/user/decline-friend-request",
  requireAuth,
  user.declineFriendRequest
);
router.use("/change-username", requireAuth, user.changeUsername);
router.use("/logout", requireAuth, user.logout);
router.use("/set-profile-picture", requireAuth, user.setProfilePicture);
router.use("/delete-account", requireAuth, user.deleteAccount);
router.use("/refresh-token", user.refreshToken);
router.use("/get-user-profile-info", requireAuth, user.getUserProfileInfo);
router.use("/toggle-notifications", requireAuth, user.toggleNotifications);
router.use("/reset-password", requireAuth, user.resetPassword);

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
router.use(
  "/groups/assign-leader",
  requireAuth,
  requireGroupLeader,
  group.reassignLeader
);
router.use("/groups/search", requireAuth, group.searchPublicGroups);
router.use("/groups/all-public", requireAuth, group.getAllPublicGroups);
router.use("/groups/join", requireAuth, group.joinGroup);
router.use("/groups/setbfreq", requireAuth, group.setBeaconFreq);
router.use("/groups/leaderboard", requireAuth, group.getGroupLeaderboard);
router.get(
  "/groups/member-leaderboard",
  requireAuth,
  group.getGroupMemberLeaderboard
);
router.get(
  "/groups/global-leaderboard",
  requireAuth,
  group.getGlobalLeaderboard
);

// Beacon routes
router.use("/getbeacon", requireAuth, beacon.getLatestBeacon);

export default router;
