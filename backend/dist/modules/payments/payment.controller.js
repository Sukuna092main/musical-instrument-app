"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.listPaymentHistory = exports.devSuccessPayment = void 0;
const asyncHandler_1 = require("../../utils/asyncHandler");
const payment_service_1 = require("./payment.service");
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
exports.listPaymentHistory = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
    }
    const payments = await (0, payment_service_1.getPaymentHistory)(req.user.id);
    res.status(200).json(payments);
});
