"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.app = void 0;
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const prisma_1 = require("./config/prisma");
exports.app = (0, express_1.default)();
exports.app.use((0, cors_1.default)());
exports.app.use(express_1.default.json());
// GET /health
// Kiểm tra server backend còn chạy hay không.
exports.app.get("/health", async (req, res) => {
    res.status(200).json({ status: "ok", message: "Server is running" });
});
// GET /api/instruments
// Lấy danh sách nhạc cụ đang active để Flutter hiển thị.
exports.app.get("/api/instruments", async (req, res) => {
    const instruments = await prisma_1.prisma.instruments.findMany({
        where: { status: "active" },
        orderBy: { created_at: "desc" },
    });
    res.status(200).json({ data: instruments });
});
