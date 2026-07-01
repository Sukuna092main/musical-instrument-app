import { Router } from "express";
import { authMiddleware } from "../../middlewares/auth.middleware";
import {
  listRecentMedia,
  removeMedia,
  saveYoutubeMedia,
} from "./media.controller";

export const mediaRoutes = Router();

// GET /api/media/recent
// Lấy danh sách media gần đây của user hiện tại.
mediaRoutes.get("/recent", authMiddleware, listRecentMedia);

// POST /api/media/youtube
// Lưu một link YouTube vào lịch sử thưởng thức nhạc cụ.
mediaRoutes.post("/youtube", authMiddleware, saveYoutubeMedia);

// DELETE /api/media/:id
// Xóa một media item khỏi lịch sử của user hiện tại.
mediaRoutes.delete("/:id", authMiddleware, removeMedia);