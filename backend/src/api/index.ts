import express from "express";
import { register, login, changeUsername } from "./controllers/user";
import MessageResponse from "../interfaces/MessageResponse";
import emojis from "./emojis";
import { inviteToGroup, createGroup } from "./controllers/group";

const router = express.Router();

router.get<{}, MessageResponse>("/", (req, res) => {
  res.json({
    message: "API - 👋🌎🌍🌏",
  });
});

router.use("/emojis", emojis);
router.use("/register", register);
router.use("/login", login);
router.use("/change-username", changeUsername)
router.use("/groups/create", createGroup)

router.use("/group/invite", inviteToGroup);

export default router;
