"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.uploadMyAvatar = exports.changeMyPassword = exports.updateMyProfile = exports.getMe = void 0;
const promises_1 = require("node:fs/promises");
const node_path_1 = __importDefault(require("node:path"));
const avatar_upload_1 = require("../../config/avatar-upload");
const asyncHandler_1 = require("../../utils/asyncHandler");
const user_service_1 = require("./user.service");
function getLocalAvatarFilename(avatarUrl) {
    if (!avatarUrl) {
        return null;
    }
    try {
        const pathname = new URL(avatarUrl).pathname;
        const prefix = "/uploads/avatars/";
        if (!pathname.startsWith(prefix)) {
            return null;
        }
        const filename = node_path_1.default.basename(pathname);
        return pathname === `${prefix}${filename}` ? filename : null;
    }
    catch (_) {
        return null;
    }
}
async function removePreviousAvatar(avatarUrl) {
    const filename = getLocalAvatarFilename(avatarUrl);
    if (filename == null) {
        return;
    }
    try {
        await (0, promises_1.rm)(node_path_1.default.join(avatar_upload_1.avatarDirectory, filename), { force: true });
    }
    catch (_) {
        // Do not fail a successful avatar update just because old-file cleanup failed.
    }
}
// GET /api/users/me
// Lấy thông tin user hiện tại từ JWT.
exports.getMe = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const user = await (0, user_service_1.getCurrentUser)(req.user.id);
    res.status(200).json({ data: { user } });
});
// PATCH /api/users/me
// Cập nhật full_name / phone của user hiện tại.
exports.updateMyProfile = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const { fullName, phone } = req.body ?? {};
    if (fullName !== undefined && typeof fullName !== "string") {
        res.status(400).json({ message: "fullName must be a string." });
        return;
    }
    if (phone !== undefined && typeof phone !== "string") {
        res.status(400).json({ message: "phone must be a string." });
        return;
    }
    const user = await (0, user_service_1.updateMyProfile)(req.user.id, { fullName, phone });
    res.status(200).json({ message: "Profile updated successfully", data: { user } });
});
// PATCH /api/users/me/password
// Đổi mật khẩu
exports.changeMyPassword = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const { oldPassword, newPassword } = req.body ?? {};
    await (0, user_service_1.changeMyPassword)(req.user.id, { oldPassword, newPassword });
    res.status(200).json({ message: "Password updated successfully" });
});
exports.uploadMyAvatar = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const file = req.file;
    if (!file) {
        res.status(400).json({ message: "Avatar file is required." });
        return;
    }
    const requestBaseUrl = req.get("host")
        ? `${req.protocol}://${req.get("host")}`
        : "";
    const publicBaseUrl = process.env.PUBLIC_API_BASE_URL ?? requestBaseUrl;
    if (!publicBaseUrl) {
        await (0, promises_1.rm)(file.path, { force: true });
        const error = Object.assign(new Error("Could not determine the public API URL."), { statusCode: 500 });
        throw error;
    }
    const avatarUrl = `${publicBaseUrl.replace(/\/$/, "")}/uploads/avatars/${file.filename}`;
    try {
        const result = await (0, user_service_1.updateAvatarUrl)(req.user.id, avatarUrl);
        await removePreviousAvatar(result.previousAvatarUrl);
        res.status(200).json({
            data: {
                avatarUrl: result.avatarUrl,
            },
        });
    }
    catch (error) {
        await (0, promises_1.rm)(file.path, { force: true });
        throw error;
    }
});
