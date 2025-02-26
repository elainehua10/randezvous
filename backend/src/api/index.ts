import express from "express";
import { register } from "./controllers/user";
import MessageResponse from "../interfaces/MessageResponse";
import emojis from "./emojis";
import { inviteToGroup } from "./controllers/group";

const router = express.Router();

router.get<{}, MessageResponse>("/", (req, res) => {
  res.json({
    message: "API - 👋🌎🌍🌏",
  });
});

router.use("/emojis", emojis);
router.use("/register", register);

router.use("/group/invite", inviteToGroup);

export default router;
