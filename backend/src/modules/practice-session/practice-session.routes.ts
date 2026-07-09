import { Router } from "express";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { start, end, cancel, active, list, stats, streak } from "./practice-session.controller";

export const practiceSessionRoutes = Router();

// Tất cả routes đều yêu cầu auth
practiceSessionRoutes.use(authMiddleware);

// GET /api/practice-sessions          — lịch sử buổi tập (paginated)
practiceSessionRoutes.get("/", list);

// GET /api/practice-sessions/active   — session đang chạy (nếu có)
practiceSessionRoutes.get("/active", active);

// GET /api/practice-sessions/stats    — tổng phút today/week/month
practiceSessionRoutes.get("/stats", stats);

// GET /api/practice-sessions/streak   — current & longest streak
practiceSessionRoutes.get("/streak", streak);

// POST /api/practice-sessions/start   — bắt đầu buổi tập mới
practiceSessionRoutes.post("/start", start);

// POST /api/practice-sessions/:id/end — kết thúc buổi tập
practiceSessionRoutes.post("/:id/end", end);

// POST /api/practice-sessions/:id/cancel — hủy buổi tập
practiceSessionRoutes.post("/:id/cancel", cancel);