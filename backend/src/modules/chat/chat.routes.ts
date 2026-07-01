import { Router } from "express";
import { authMiddleware } from "../../middlewares/auth.middleware";
import {
  listChatMessages,
  sendChatMessage,
} from "./chat.controller";

export const chatRoutes = Router();

// GET /api/chat/messages
// Lay lich su chat cua user hien tai.
chatRoutes.get("/messages", authMiddleware, listChatMessages);

// POST /api/chat/messages
// Gui tin nhan support va nhan phan hoi bot theo FAQ rule.
chatRoutes.post("/messages", authMiddleware, sendChatMessage);