import { Router } from "express";
import { authMiddleware } from "../../middlewares/auth.middleware";
import {
  devSuccessPayment,
  listPaymentHistory,
} from "./payment.controller";

export const paymentRoutes = Router();

// POST /api/payments/dev-success
// Tạo thanh toán giả lập thành công để test luồng VIP trong môi trường dev.
paymentRoutes.post("/dev-success", authMiddleware, devSuccessPayment);

// GET /api/payments/history
// Lấy lịch sử thanh toán của user hiện tại.
paymentRoutes.get("/history", authMiddleware, listPaymentHistory);