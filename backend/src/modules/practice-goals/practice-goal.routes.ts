import { Router } from "express";
import { authMiddleware } from "../../middlewares/auth.middleware";
import {
  create,
  update,
  remove,
  list,
  progress,
} from "./practice-goal.controller";

export const practiceGoalRoutes = Router();

// Tất cả routes đều yêu cầu auth
practiceGoalRoutes.use(authMiddleware);

// GET  /api/practice-goals            — danh sách goals của user
practiceGoalRoutes.get("/", list);

// GET  /api/practice-goals/progress   — tiến trình tất cả goals đang active
practiceGoalRoutes.get("/progress", progress);

// POST /api/practice-goals            — tạo goal mới
practiceGoalRoutes.post("/", create);

// PUT  /api/practice-goals/:id        — cập nhật goal
practiceGoalRoutes.put("/:id", update);

// DELETE /api/practice-goals/:id      — xóa goal
practiceGoalRoutes.delete("/:id", remove);