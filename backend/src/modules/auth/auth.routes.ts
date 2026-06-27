import { Router } from "express";
import { login, register, me } from "./auth.controller";
import { authMiddleware } from "../../middlewares/auth.middleware";

export const authRoutes = Router();

// POST /api/auth/register
// Đăng ký tài khoản mới, mã hóa password và trả access token.
authRoutes.post("/register", register);

// POST /api/auth/login
// Đăng nhập bằng email/password và trả access token.
authRoutes.post("/login", login);

// GET /api/auth/me
// Lấy thông tin user hiện tại từ JWT access token.
authRoutes.get("/me", authMiddleware, me);