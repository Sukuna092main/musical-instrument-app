"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.listChatMessages = exports.sendChatMessage = void 0;
const asyncHandler_1 = require("../../utils/asyncHandler");
const chat_support_service_1 = require("./chat.support.service");
exports.sendChatMessage = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
    }
    const { message } = req.body;
    if (!message || typeof message !== 'string' || !message.trim()) {
        res.status(400).json({ message: 'message required' });
        return;
    }
    if (message.length > 4000) {
        res.status(400).json({ message: 'message is too long' });
        return;
    }
    const result = await (0, chat_support_service_1.createChatMessage)(req.user.id, message);
    res.status(201).json({ data: result });
});
exports.listChatMessages = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
    }
    const messages = await (0, chat_support_service_1.getChatMessages)(req.user.id);
    res.status(200).json({ data: messages });
});
