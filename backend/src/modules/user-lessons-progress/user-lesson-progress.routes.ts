import { Router } from "express";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { start, complete, reset, list } from "./user-lesson-progress.controller";

export const userLessonProgressRoutes = Router();

userLessonProgressRoutes.use(authMiddleware);

// GET  /api/user-lesson-progress                        — danh sách progress (filter status, categoryId)
userLessonProgressRoutes.get("/", list);

// POST /api/user-lesson-progress/:lessonId/start        — bắt đầu bài học
userLessonProgressRoutes.post("/:lessonId/start", start);

// POST /api/user-lesson-progress/:lessonId/complete     — hoàn thành bài học
userLessonProgressRoutes.post("/:lessonId/complete", complete);

// POST /api/user-lesson-progress/:lessonId/reset        — học lại
userLessonProgressRoutes.post("/:lessonId/reset", reset);