import { Router } from "express";
import {
  listVipPlans,
  showMySubscription,
} from "./vip.controller";
import { authMiddleware } from "../../middlewares/auth.middleware";

export const vipRoutes = Router();

// GET /api/vip/plans
// Lấy danh sách gói VIP đang active.
vipRoutes.get("/plans", listVipPlans);

// GET /api/vip/subscription
// Lấy trạng thái gói VIP hiện tại của user từ JWT access token.
vipRoutes.get("/subscription", authMiddleware, showMySubscription);