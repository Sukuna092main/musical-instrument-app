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
// POST /api/payments/manual/request
// User gửi yêu cầu mua VIP qua chuyển khoản, được cấp trial 24h ngay.
exports.paymentRoutes.post("/manual/request", auth_middleware_1.authMiddleware, payment_controller_1.requestManualVip);
// GET /api/payments/manual/my-requests
// User xem danh sách yêu cầu chuyển khoản của mình.
exports.paymentRoutes.get("/manual/my-requests", auth_middleware_1.authMiddleware, payment_controller_1.listMyManualRequestsHandler);
// GET /api/payments/history
// Lấy lịch sử thanh toán của user hiện tại.
exports.paymentRoutes.get("/history", auth_middleware_1.authMiddleware, payment_controller_1.listPaymentHistory);
