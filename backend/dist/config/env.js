"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.env = void 0;
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
exports.env = {
    port: process.env.PORT || "5000",
    databaseUrl: process.env.DATABASE_URL || "",
    jwtSecret: process.env.JWT_SECRET || "",
    youtubeApiKey: process.env.YOUTUBE_API_KEY || "",
};
if (!exports.env.databaseUrl) {
    throw new Error("DATABASE_URL is missing in .env");
}
if (!exports.env.jwtSecret) {
    throw new Error("JWT_SECRET is missing in .env");
}
if (!exports.env.youtubeApiKey) {
    throw new Error("YOUTUBE_API_KEY is missing in .env");
}
