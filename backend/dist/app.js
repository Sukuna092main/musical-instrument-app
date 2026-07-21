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
const practice_session_routes_1 = require("./modules/practice-session/practice-session.routes");
const practice_goal_routes_1 = require("./modules/practice-goals/practice-goal.routes");
const user_instrument_routes_1 = require("./modules/user-instruments/user-instrument.routes");
const lesson_routes_1 = require("./modules/lessons/lesson.routes");
const user_lesson_progress_routes_1 = require("./modules/user-lessons-progress/user-lesson-progress.routes");
const scale_routes_1 = require("./modules/scales/scale.routes");
const avatar_upload_1 = require("./config/avatar-upload");
const user_routes_1 = require("./modules/users/user.routes");
const chord_routes_1 = require("./modules/chords/chord.routes");
exports.app = (0, express_1.default)();
exports.app.use((0, cors_1.default)());
exports.app.use(express_1.default.json());
exports.app.use("/uploads", express_1.default.static(avatar_upload_1.uploadsDirectory));
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
// Practice session API
exports.app.use("/api/practice-sessions", practice_session_routes_1.practiceSessionRoutes);
// Practice goals API
exports.app.use("/api/practice-goals", practice_goal_routes_1.practiceGoalRoutes);
// User's Instrument API
exports.app.use("/api/user-instruments", user_instrument_routes_1.userInstrumentRoutes);
// Lession API
exports.app.use("/api/lessons", lesson_routes_1.lessonRoutes);
// User Lesson Progress API
exports.app.use("/api/user-lesson-progress", user_lesson_progress_routes_1.userLessonProgressRoutes);
// Scales API
exports.app.use("/api/scales", scale_routes_1.scaleRoutes);
// Chords API
exports.app.use("/api/chords", chord_routes_1.chordRoutes);
// Users API
exports.app.use("/api/users", user_routes_1.userRoutes);
// Middleware xử lý lỗi 404 khi không tìm thấy route.
exports.app.use(error_middleware_1.notFoundMiddleware);
// Global error handler
exports.app.use(error_middleware_1.errorMiddleware);
