import express, { Request, Response, NextFunction } from "express";
import morgan from "morgan";
import helmet from "helmet";
import cors from "cors";
import dotenv from "dotenv";
import fileUpload from "express-fileupload";

dotenv.config();

import * as middlewares from "./middlewares";
import api from "./api";
import MessageResponse from "./interfaces/MessageResponse";
import { setupWebsocketServer } from "./web-socket-server/ws";
import http from "http";

const app = express();

app.use(morgan("dev"));
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(
  fileUpload({
    limits: { fileSize: 50 * 1024 * 1024 },
  })
);

// Initialize Supabase

// Default message
app.get<{}, MessageResponse>("/", (req, res) => {
  res.json({
    message: "🦄🌈✨👋🌎🌍🌏✨🌈🦄",
  });
});

app.use("/api/v1", api);

app.use(middlewares.notFound);
app.use(middlewares.errorHandler);

const server = http.createServer(app);

setupWebsocketServer(server);

export default server;
