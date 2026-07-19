import { Router } from "express";
import { authMiddleware } from "../../middlewares/auth.middleware";
import {
  devSuccessPayment,
  listPaymentHistory,
  requestManualVip,
  listMyManualRequestsHandler
} from "./payment.controller";

export const paymentRoutes = Router();

// POST /api/payments/dev-success
// Tạo thanh toán giả lập thành công để test luồng VIP trong môi trường dev.
paymentRoutes.post("/dev-success", authMiddleware, devSuccessPayment);

// POST /api/payments/manual/request
// User gửi yêu cầu mua VIP qua chuyển khoản, được cấp trial 24h ngay.
paymentRoutes.post("/manual/request", authMiddleware, requestManualVip);

// GET /api/payments/manual/my-requests
// User xem danh sách yêu cầu chuyển khoản của mình.
paymentRoutes.get("/manual/my-requests", authMiddleware, listMyManualRequestsHandler);

// GET /api/payments/history
// Lấy lịch sử thanh toán của user hiện tại.
paymentRoutes.get("/history", authMiddleware, listPaymentHistory);