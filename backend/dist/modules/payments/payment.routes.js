"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.paymentRoutes = void 0;
const express_1 = require("express");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const payment_controller_1 = require("./payment.controller");
exports.paymentRoutes = (0, express_1.Router)();
// POST /api/payments/dev-success
// Tạo thanh toán giả lập thành công để test luồng VIP trong môi trường dev.
exports.paymentRoutes.post("/dev-success", auth_middleware_1.authMiddleware, payment_controller_1.devSuccessPayment);
// GET /api/payments/history
// Lấy lịch sử thanh toán của user hiện tại.
exports.paymentRoutes.get("/history", auth_middleware_1.authMiddleware, payment_controller_1.listPaymentHistory);
