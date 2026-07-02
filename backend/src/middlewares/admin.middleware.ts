import { NextFunction, Request, Response } from "express";

export function adminMiddleware(req: Request, res: Response, next: NextFunction) {
    if (!req.user || req.user.role !== "admin") {
        return res.status(403).json({ message: "Access denied. Admin privileges required." });
    }
    next();
}