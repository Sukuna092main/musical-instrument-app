"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.rejectAdminManualPayment = exports.approveAdminManualPayment = exports.listAdminManualPayments = exports.updateAdminSubscriptionStatus = exports.showAdminSubscription = exports.listAdminSubscriptions = exports.showAdminPayment = exports.listAdminPayments = exports.updateAdminVipPlan = exports.showAdminVipPlan = exports.listAdminVipPlans = exports.deleteAdminInstrument = exports.updateAdminInstrument = exports.createAdminInstrument = exports.showAdminInstrument = exports.listAdminInstruments = exports.updateAdminUserStatus = exports.showAdminUser = exports.listAdminUsers = exports.showAdminDashboard = void 0;
const asyncHandler_1 = require("../../utils/asyncHandler");
const admin_service_1 = require("./admin.service");
const manual_payment_service_1 = require("../payments/manual-payment.service");
exports.showAdminDashboard = (0, asyncHandler_1.asyncHandler)(async (_req, res) => {
    const dashboard = await (0, admin_service_1.getAdminDashboard)();
    res.json({
        data: dashboard,
    });
});
exports.listAdminUsers = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 20);
    const result = await (0, admin_service_1.listUsersForAdmin)({
        page,
        limit,
        search: req.query.search,
        status: req.query.status,
        role: req.query.role,
    });
    res.json(result);
});
exports.showAdminUser = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const user = await (0, admin_service_1.getUserForAdmin)(req.params.id);
    if (!user) {
        return res.status(404).json({ message: "User not found" });
    }
    res.json({ data: user });
});
exports.updateAdminUserStatus = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const newStatus = req.body.status;
    if (!newStatus || typeof newStatus !== "string" || !["active", "blocked", "deleted"].includes(newStatus)) {
        return res.status(400).json({ message: "Invalid status value" });
    }
    const result = await (0, admin_service_1.updateUserStatusForAdmin)(req.params.id, newStatus);
    if ("error" in result) {
        const statusCode = result.error === "User not found" ? 404 : 400;
        return res.status(statusCode).json({ message: result.error });
    }
    res.json({ message: "User status updated successfully", data: result });
});
exports.listAdminInstruments = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 20);
    const isVipQuery = req.query.isVip;
    const isVip = isVipQuery === "true" ? true : isVipQuery === "false" ? false : undefined;
    const result = await (0, admin_service_1.listInstrumentsForAdmin)({
        page,
        limit,
        search: req.query.search,
        status: req.query.status,
        type: req.query.type,
        isVip,
    });
    res.json({
        data: result,
    });
});
exports.showAdminInstrument = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const instrument = await (0, admin_service_1.getInstrumentForAdmin)(req.params.id);
    if (!instrument) {
        res.status(404).json({
            message: "Instrument not found",
        });
        return;
    }
    res.json({
        data: instrument,
    });
});
exports.createAdminInstrument = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const { name, type, description, imageUrl, audioSampleUrl, isVip, tags, status, } = req.body;
    if (!name || !type || !description || !imageUrl) {
        res.status(400).json({
            message: "name, type, description and imageUrl are required",
        });
        return;
    }
    if (typeof isVip !== "boolean") {
        res.status(400).json({
            message: "isVip must be boolean",
        });
        return;
    }
    if (tags !== undefined && !Array.isArray(tags)) {
        res.status(400).json({
            message: "tags must be an array",
        });
        return;
    }
    const result = await (0, admin_service_1.createInstrumentForAdmin)({
        name,
        type,
        description,
        imageUrl,
        audioSampleUrl,
        isVip,
        tags,
        status,
    });
    if ("error" in result) {
        res.status(400).json({
            message: result.error,
        });
        return;
    }
    res.status(201).json({
        data: result.instrument,
    });
});
exports.updateAdminInstrument = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const { tags, isVip } = req.body;
    if (tags !== undefined && !Array.isArray(tags)) {
        res.status(400).json({
            message: "tags must be an array",
        });
        return;
    }
    if (isVip !== undefined && typeof isVip !== "boolean") {
        res.status(400).json({
            message: "isVip must be boolean",
        });
        return;
    }
    const result = await (0, admin_service_1.updateInstrumentForAdmin)(req.params.id, req.body);
    if ("error" in result) {
        const statusCode = result.error === "Instrument not found" ? 404 : 400;
        res.status(statusCode).json({
            message: result.error,
        });
        return;
    }
    res.json({
        data: result.instrument,
    });
});
exports.deleteAdminInstrument = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const result = await (0, admin_service_1.hideInstrumentForAdmin)(req.params.id);
    if ("error" in result) {
        const statusCode = result.error === "Instrument not found" ? 404 : 400;
        res.status(statusCode).json({
            message: result.error,
        });
        return;
    }
    res.json({
        data: result.instrument,
    });
});
exports.listAdminVipPlans = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const result = await (0, admin_service_1.listVipPlansForAdmin)({
        status: req.query.status,
    });
    res.json({
        data: result,
    });
});
exports.showAdminVipPlan = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const plan = await (0, admin_service_1.getVipPlanForAdmin)(req.params.id);
    if (!plan) {
        return res.status(404).json({ message: "VIP plan not found" });
    }
    res.json({ data: plan });
});
exports.updateAdminVipPlan = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const forbiddenFields = ["code", "durationDays", "duration_days"];
    for (const field of forbiddenFields) {
        if (field in req.body) {
            return res.status(400).json({ message: `Field '${field}' cannot be updated` });
        }
    }
    const { price, features } = req.body;
    if (price !== undefined && typeof price !== "number") {
        return res.status(400).json({ message: "Field 'price' must be a number" });
    }
    if (features !== undefined && !Array.isArray(features)) {
        return res.status(400).json({ message: "Field 'features' must be an array" });
    }
    const result = await (0, admin_service_1.updateVipPlanForAdmin)(req.params.id, req.body);
    if ("error" in result) {
        const statusCode = result.error === "VIP plan not found" ? 404 : 400;
        return res.status(statusCode).json({ message: result.error });
    }
    res.json({ message: "VIP plan updated successfully", data: result });
});
exports.listAdminPayments = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 20);
    const result = await (0, admin_service_1.listPaymentsForAdmin)({
        page,
        limit,
        status: req.query.status,
        provider: req.query.provider,
        userId: req.query.userId,
    });
    res.json({
        data: result,
    });
});
exports.showAdminPayment = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const payment = await (0, admin_service_1.getPaymentForAdmin)(req.params.id);
    if (!payment) {
        return res.status(404).json({ message: "Payment not found" });
    }
    res.json({
        data: payment,
    });
});
exports.listAdminSubscriptions = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 20);
    const result = await (0, admin_service_1.listSubscriptionsForAdmin)({
        page,
        limit,
        status: req.query.status,
        userId: req.query.userId,
        planId: req.query.planId,
    });
    res.json({
        data: result,
    });
});
exports.showAdminSubscription = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const subscription = await (0, admin_service_1.getSubscriptionForAdmin)(req.params.id);
    if (!subscription) {
        res.status(404).json({
            message: "Subscription not found",
        });
        return;
    }
    res.json({
        data: subscription,
    });
});
exports.updateAdminSubscriptionStatus = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const { status } = req.body;
    if (!status || typeof status !== "string") {
        res.status(400).json({
            message: "status is required",
        });
        return;
    }
    const result = await (0, admin_service_1.updateSubscriptionStatusForAdmin)(req.params.id, status);
    if ("error" in result) {
        const statusCode = result.error === "Subscription not found" ? 404 : 400;
        res.status(statusCode).json({
            message: result.error,
        });
        return;
    }
    res.json({
        data: result.subscription,
    });
});
// GET /api/admin/manual-payments?status=pending
exports.listAdminManualPayments = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 20);
    const result = await (0, manual_payment_service_1.listManualRequestsForAdmin)({
        page,
        limit,
        status: req.query.status,
        userId: req.query.userId,
    });
    res.json({ data: result });
});
// POST /api/admin/manual-payments/:id/approve
exports.approveAdminManualPayment = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
    }
    const result = await (0, manual_payment_service_1.approveManualRequest)(req.params.id, req.user.id);
    if ("error" in result) {
        const code = result.error.includes("not found") ? 404 : 400;
        return res.status(code).json({ message: result.error });
    }
    res.json({ data: result });
});
// POST /api/admin/manual-payments/:id/reject
exports.rejectAdminManualPayment = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
    }
    const { reason } = req.body || {};
    const result = await (0, manual_payment_service_1.rejectManualRequest)(req.params.id, req.user.id, reason);
    if ("error" in result) {
        const code = result.error.includes("not found") ? 404 : 400;
        return res.status(code).json({ message: result.error });
    }
    res.json({ data: result });
});
