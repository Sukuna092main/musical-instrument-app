"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.vipRoutes = void 0;
const express_1 = require("express");
const vip_controller_1 = require("./vip.controller");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
exports.vipRoutes = (0, express_1.Router)();
// GET /api/vip/plans
// Lấy danh sách gói VIP đang active.
exports.vipRoutes.get("/plans", vip_controller_1.listVipPlans);
// GET /api/vip/subscription
// Lấy trạng thái gói VIP hiện tại của user từ JWT access token.
exports.vipRoutes.get("/subscription", auth_middleware_1.authMiddleware, vip_controller_1.showMySubscription);
