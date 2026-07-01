import { Router } from "express";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { searchVideos } from "./youtube.controller";

export const youtubeRoutes = Router();

// GET /api/youtube/search?q=<keyword>
// Tim video YouTube theo tu khoa. Can dang nhap de tranh bi spam quota.
youtubeRoutes.get("/search", authMiddleware, searchVideos);