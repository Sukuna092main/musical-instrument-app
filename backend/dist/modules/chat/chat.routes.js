"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.chatRoutes = void 0;
const express_1 = require("express");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const chat_controller_1 = require("./chat.controller");
exports.chatRoutes = (0, express_1.Router)();
// GET /api/chat/messages
// Lay lich su chat cua user hien tai.
exports.chatRoutes.get("/messages", auth_middleware_1.authMiddleware, chat_controller_1.listChatMessages);
// POST /api/chat/messages
// Gui tin nhan support va nhan phan hoi bot theo FAQ rule.
exports.chatRoutes.post("/messages", auth_middleware_1.authMiddleware, chat_controller_1.sendChatMessage);
