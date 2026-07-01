"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.authRoutes = void 0;
const express_1 = require("express");
const auth_controller_1 = require("./auth.controller");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
exports.authRoutes = (0, express_1.Router)();
// POST /api/auth/register
// Đăng ký tài khoản mới, mã hóa password và trả access token.
exports.authRoutes.post("/register", auth_controller_1.register);
// POST /api/auth/login
// Đăng nhập bằng email/password và trả access token.
exports.authRoutes.post("/login", auth_controller_1.login);
// GET /api/auth/me
// Lấy thông tin user hiện tại từ JWT access token.
exports.authRoutes.get("/me", auth_middleware_1.authMiddleware, auth_controller_1.me);
