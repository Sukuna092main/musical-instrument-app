import { NextFunction, Request, Response } from "express";
import multer from "multer";

type AppError = Error & { statusCode?: number; code?: string };

export function notFoundMiddleware(req: Request, res: Response) {
    res.status(404).json({ message: `Route ${req.method} ${req.originalUrl} not found` });
}

export function errorMiddleware(err: AppError, req: Request, res: Response, next: NextFunction) {
    console.error(err);

    if (err.code === "P2002") {
        return res.status(400).json({ message: "Unique constraint failed" });
    }

    if (err instanceof multer.MulterError) {
        const message =
            err.code === "LIMIT_FILE_SIZE"
            ? "Avatar must be 5 MB or smaller."
            : "Invalid avatar upload.";

        return res.status(400).json({ message });
    }

    return res.status(err.statusCode || 500).json({ message: err.message || "Internal Server Error" });
}