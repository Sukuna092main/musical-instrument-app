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
    // Manual Bank Transfer (VietQR)
    bankTransferBankId: process.env.BANK_TRANSFER_BANK_ID || "",
    bankTransferAccountNo: process.env.BANK_TRANSFER_ACCOUNT_NO || "",
    bankTransferAccountName: process.env.BANK_TRANSFER_ACCOUNT_NAME || "",
    bankTransferDescriptionPrefix: process.env.BANK_TRANSFER_DESCRIPTION_PREFIX || "MUSICAL",
    // Số giờ VIP trial khi user tạo manual request. Đặt 0 để tắt trial.
    manualTrialHours: Number(process.env.MANUAL_TRIAL_HOURS ?? 24),
};
if (!exports.env.databaseUrl) {
    throw new Error("DATABASE_URL is missing in .env");
}
if (!exports.env.jwtSecret) {
    throw new Error("JWT_SECRET is missing in .env");
}
