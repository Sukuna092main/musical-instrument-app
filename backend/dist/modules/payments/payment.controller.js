"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.listPaymentHistory = exports.listMyManualRequestsHandler = exports.requestManualVip = exports.devSuccessPayment = void 0;
const asyncHandler_1 = require("../../utils/asyncHandler");
const payment_service_1 = require("./payment.service");
const manual_payment_service_1 = require("./manual-payment.service");
exports.devSuccessPayment = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
    }
    const { planCode } = req.body;
    if (!planCode) {
        return res.status(400).json({ message: "Plan code is required" });
    }
    const result = await (0, payment_service_1.createDevSuccessfulPayment)(req.user.id, planCode);
    if ("error" in result) {
        return res.status(404).json({ message: result.error });
    }
    res.status(201).json(result);
});
// POST /api/payments/manual/request
// User gửi yêu cầu mua VIP qua chuyển khoản. Backend cấp trial 24h ngay lập tức.
exports.requestManualVip = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
    }
    const { planCode, provider, transferCode, note } = req.body || {};
    if (!planCode) {
        return res.status(400).json({ message: "planCode is required" });
    }
    const result = await (0, manual_payment_service_1.createManualRequest)({
        userId: req.user.id,
        planCode,
        provider,
        transferCode,
        note,
    });
    if ("error" in result) {
        return res.status(400).json({ message: result.error });
    }
    res.status(201).json(result);
});
// GET /api/payments/manual/my-requests
exports.listMyManualRequestsHandler = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
    }
    const items = await (0, manual_payment_service_1.listMyManualRequests)(req.user.id);
    res.status(200).json({ items });
});
exports.listPaymentHistory = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
    }
    const payments = await (0, payment_service_1.getPaymentHistory)(req.user.id);
    res.status(200).json(payments);
});
