import express from "express";
import { register, login } from "./controllers/user";
import MessageResponse from "../interfaces/MessageResponse";
import emojis from "./emojis";
import { createGroup, renameGroup, setPublicity, inviteToGroup } from "./controllers/group";

const router = express.Router();

router.get<{}, MessageResponse>("/", (req, res) => {
  res.json({
    message: "API - 👋🌎🌍🌏",
  });
});

router.use("/emojis", emojis);
router.use("/register", register);
router.use("/login", login)
router.use("/groups/create", createGroup)
router.use("/groups/rename", renameGroup)
router.use("/groups/setpub", setPublicity)

router.use("/group/invite", inviteToGroup);

export default router;
