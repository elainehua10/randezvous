import express from "express";
import { register, login } from "./controllers/user";
import MessageResponse from "../interfaces/MessageResponse";
import emojis from "./emojis";
import { createGroup, renameGroup, setPublicity, inviteToGroup, uploadIcon, removeFromGroup, acceptInvite, leaveGroup, getGroupLocations } from "./controllers/group";

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

// Group routes
router.use("/groups/create", createGroup);
router.use("/groups/rename", renameGroup);
router.use("/groups/setpub", setPublicity);
router.use("/groups/invite", inviteToGroup);
router.use("/groups/icon", uploadIcon);
router.use("/groups/remove", removeFromGroup);
router.use("/groups/accept", acceptInvite);
router.use("/groups/leave", leaveGroup);
router.use("/groups/locations", getGroupLocations);

export default router;
