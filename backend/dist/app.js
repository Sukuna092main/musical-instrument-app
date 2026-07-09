"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.app = void 0;
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const instrument_routes_1 = require("./modules/instruments/instrument.routes");
const vip_routes_1 = require("./modules/vip/vip.routes");
const auth_routes_1 = require("./modules/auth/auth.routes");
const error_middleware_1 = require("./middlewares/error.middleware");
const payment_routes_1 = require("./modules/payments/payment.routes");
const chat_routes_1 = require("./modules/chat/chat.routes");
const admin_routes_1 = require("./modules/admin/admin.routes");
exports.app = (0, express_1.default)();
exports.app.use((0, cors_1.default)());
exports.app.use(express_1.default.json());
// GET /health
// Kiểm tra server backend còn chạy hay không.
exports.app.get("/health", async (req, res) => {
    res.status(200).json({ status: "ok", message: "Server is running" });
});
// GET /api/instruments
// Lấy danh sách nhạc cụ đang active để Flutter hiển thị.
exports.app.use("/api/instruments", instrument_routes_1.instrumentRoutes);
// GET /api/vip
// Lấy danh sách gói VIP đang active và trạng thái gói VIP hiện tại của user.
exports.app.use("/api/vip", vip_routes_1.vipRoutes);
// POST /api/auth
// Đăng ký tài khoản mới, mã hóa password và trả access token.
exports.app.use("/api/auth", auth_routes_1.authRoutes);
// Payments API
exports.app.use("/api/payments", payment_routes_1.paymentRoutes);
// Chat API
exports.app.use("/api/chat", chat_routes_1.chatRoutes);
// Admin API
exports.app.use("/api/admin", admin_routes_1.adminRoutes);
// Middleware xử lý lỗi 404 khi không tìm thấy route.
exports.app.use(error_middleware_1.notFoundMiddleware);
// Global error handler
exports.app.use(error_middleware_1.errorMiddleware);
