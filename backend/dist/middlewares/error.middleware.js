"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.notFoundMiddleware = notFoundMiddleware;
exports.errorMiddleware = errorMiddleware;
const multer_1 = __importDefault(require("multer"));
function notFoundMiddleware(req, res) {
    res.status(404).json({ message: `Route ${req.method} ${req.originalUrl} not found` });
}
function errorMiddleware(err, req, res, next) {
    console.error(err);
    if (err.code === "P2002") {
        return res.status(400).json({ message: "Unique constraint failed" });
    }
    if (err instanceof multer_1.default.MulterError) {
        const message = err.code === "LIMIT_FILE_SIZE"
            ? "Avatar must be 5 MB or smaller."
            : "Invalid avatar upload.";
        return res.status(400).json({ message });
    }
    return res.status(err.statusCode || 500).json({ message: err.message || "Internal Server Error" });
}
