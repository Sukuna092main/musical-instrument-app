import { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";
import { env } from "../config/env";

type AccessTokenPayload = {
    userId: string;
    role: string;
};

export function authMiddleware(req: Request, res: Response, next: NextFunction) {
    const authorization = req.headers.authorization;

    if (!authorization || !authorization.startsWith("Bearer ")) {
        return res.status(401).json({ message: "Missing or invalid Authorization header" });
    }

    const token = authorization.replace("Bearer ", "");

    try {
        const payload = jwt.verify(token, env.jwtSecret) as AccessTokenPayload;

        req.user = { id: payload.userId, role: payload.role };

        return next();
    } catch {
        return res.status(401).json({ message: "Invalid or expired token"});
    }
}