import express from "express";
import "./types/express";
import cors from "cors";
import { prisma } from "./config/prisma";
import { instrumentRoutes } from "./modules/instruments/instrument.routes";
import { vipRoutes } from "./modules/vip/vip.routes";
import { authRoutes } from "./modules/auth/auth.routes";
import { errorMiddleware, notFoundMiddleware } from "./middlewares/error.middleware";
import { paymentRoutes } from "./modules/payments/payment.routes";
import { chatRoutes } from "./modules/chat/chat.routes";
import { adminRoutes } from "./modules/admin/admin.routes";
import { practiceSessionRoutes } from "./modules/practice-session/practice-session.routes";
import { practiceGoalRoutes } from "./modules/practice-goals/practice-goal.routes";
import { userInstrumentRoutes } from "./modules/user-instruments/user-instrument.routes";
import { lessonRoutes } from "./modules/lessons/lesson.routes";
import { userLessonProgressRoutes } from "./modules/user-lessons-progress/user-lesson-progress.routes";
import { scaleRoutes } from "./modules/scales/scale.routes";
import { uploadsDirectory } from "./config/avatar-upload";
import { userRoutes } from "./modules/users/user.routes";
import { chordRoutes } from "./modules/chords/chord.routes";


export const app = express();

app.use(cors());
app.use(express.json());
app.use("/uploads", express.static(uploadsDirectory));

// GET /health
// Kiểm tra server backend còn chạy hay không.
app.get("/health", async (req, res) => {
    res.status(200).json({ status: "ok", message: "Server is running"});
});

// GET /api/instruments
// Lấy danh sách nhạc cụ đang active để Flutter hiển thị.
app.use("/api/instruments", instrumentRoutes);

// GET /api/vip
// Lấy danh sách gói VIP đang active và trạng thái gói VIP hiện tại của user.
app.use("/api/vip", vipRoutes);

// POST /api/auth
// Đăng ký tài khoản mới, mã hóa password và trả access token.
app.use("/api/auth", authRoutes);

// Payments API
app.use("/api/payments", paymentRoutes);

// Chat API
app.use("/api/chat", chatRoutes);

// Admin API
app.use("/api/admin", adminRoutes);

// Practice session API
app.use("/api/practice-sessions", practiceSessionRoutes);

// Practice goals API
app.use("/api/practice-goals", practiceGoalRoutes);

// User's Instrument API
app.use("/api/user-instruments", userInstrumentRoutes);

// Lession API
app.use("/api/lessons", lessonRoutes);

// User Lesson Progress API
app.use("/api/user-lesson-progress", userLessonProgressRoutes);

// Scales API
app.use("/api/scales", scaleRoutes);

// Chords API
app.use("/api/chords", chordRoutes);

// Users API
app.use("/api/users", userRoutes);

// Middleware xử lý lỗi 404 khi không tìm thấy route.
app.use(notFoundMiddleware);

// Global error handler
app.use(errorMiddleware);

