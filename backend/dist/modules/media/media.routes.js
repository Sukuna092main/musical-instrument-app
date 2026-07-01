"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.mediaRoutes = void 0;
const express_1 = require("express");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const media_controller_1 = require("./media.controller");
exports.mediaRoutes = (0, express_1.Router)();
// GET /api/media/recent
// Lấy danh sách media gần đây của user hiện tại.
exports.mediaRoutes.get("/recent", auth_middleware_1.authMiddleware, media_controller_1.listRecentMedia);
// POST /api/media/youtube
// Lưu một link YouTube vào lịch sử thưởng thức nhạc cụ.
exports.mediaRoutes.post("/youtube", auth_middleware_1.authMiddleware, media_controller_1.saveYoutubeMedia);
// DELETE /api/media/:id
// Xóa một media item khỏi lịch sử của user hiện tại.
exports.mediaRoutes.delete("/:id", auth_middleware_1.authMiddleware, media_controller_1.removeMedia);
