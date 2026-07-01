"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.youtubeRoutes = void 0;
const express_1 = require("express");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const youtube_controller_1 = require("./youtube.controller");
exports.youtubeRoutes = (0, express_1.Router)();
// GET /api/youtube/search?q=<keyword>
// Tim video YouTube theo tu khoa. Can dang nhap de tranh bi spam quota.
exports.youtubeRoutes.get("/search", auth_middleware_1.authMiddleware, youtube_controller_1.searchVideos);
