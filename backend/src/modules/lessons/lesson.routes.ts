import { Router } from "express";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { categories, categoryDetail, list, detail } from "./lesson.controller";

export const lessonRoutes = Router();

lessonRoutes.use(authMiddleware);

// GET /api/lessons/categories           — danh sách category (kèm count bài học)
lessonRoutes.get("/categories", categories);

// GET /api/lessons/categories/:slug     — chi tiết category theo slug
lessonRoutes.get("/categories/:slug", categoryDetail);

// GET /api/lessons                      — danh sách bài học (filter, paginated)
lessonRoutes.get("/", list);

// GET /api/lessons/:slug                — chi tiết bài học (VIP check, kèm progress)
lessonRoutes.get("/:slug", detail);