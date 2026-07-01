import { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import {
  createChatMessage,
  getChatMessages,
} from "./chat.support.service";

export const sendChatMessage = asyncHandler(async (req:Request,res:Response) => {
    if (!req.user) {
        return res.status(401).json({message: "Unauthorized"});
    }

    const {message} = req.body;

    if (!message || typeof message !== 'string' || !message.trim()) {
        res.status(400).json({message: 'message required'});
        return;
    }

    if (message.length > 4000) {
        res.status(400).json({message: 'message is too long'});
        return;
    }

    const result = await createChatMessage(req.user.id, message);

    res.status(201).json({ data: result });
});

export const listChatMessages = asyncHandler(async (req:Request,res:Response) => {
    if (!req.user) {
        return res.status(401).json({message: "Unauthorized"});
    }

    const messages = await getChatMessages(req.user.id);

    res.status(200).json({ data: messages });
})
