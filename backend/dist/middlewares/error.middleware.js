"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.notFoundMiddleware = notFoundMiddleware;
exports.errorMiddleware = errorMiddleware;
function notFoundMiddleware(req, res) {
    res.status(404).json({ message: `Route ${req.method} ${req.originalUrl} not found` });
}
function errorMiddleware(err, req, res, next) {
    console.error(err);
    if (err.code === "P2002") {
        return res.status(400).json({ message: "Unique constraint failed" });
    }
    return res.status(err.statusCode || 500).json({ message: err.message || "Internal Server Error" });
}
