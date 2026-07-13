"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.adminRoutes = void 0;
const express_1 = require("express");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const admin_middleware_1 = require("../../middlewares/admin.middleware");
const admin_content_routes_1 = require("../admin-content/admin-content.routes");
const admin_controller_1 = require("./admin.controller");
exports.adminRoutes = (0, express_1.Router)();
exports.adminRoutes.use(auth_middleware_1.authMiddleware, admin_middleware_1.adminMiddleware);
exports.adminRoutes.use("/", admin_content_routes_1.adminContentRoutes);
// GET /api/admin/dashboard
// Return revenue and operational summary for admin dashboard.
exports.adminRoutes.get("/dashboard", admin_controller_1.showAdminDashboard);
// GET /api/admin/users
// List users with pagination, search, role, and status filters.
exports.adminRoutes.get("/users", admin_controller_1.listAdminUsers);
// GET /api/admin/users/:id
// Return one user detail for admin.
exports.adminRoutes.get("/users/:id", admin_controller_1.showAdminUser);
// PATCH /api/admin/users/:id/status
// Update user account status: active, blocked, or deleted.
exports.adminRoutes.patch("/users/:id/status", admin_controller_1.updateAdminUserStatus);
// GET /api/admin/instruments
// List instruments with pagination and filters.
exports.adminRoutes.get("/instruments", admin_controller_1.listAdminInstruments);
// GET /api/admin/instruments/:id
// Return one instrument detail.
exports.adminRoutes.get("/instruments/:id", admin_controller_1.showAdminInstrument);
// POST /api/admin/instruments
// Create a new instrument.
exports.adminRoutes.post("/instruments", admin_controller_1.createAdminInstrument);
// PATCH /api/admin/instruments/:id
// Update an instrument.
exports.adminRoutes.patch("/instruments/:id", admin_controller_1.updateAdminInstrument);
// PATCH /api/admin/instruments/:id/status
// Delete an instrument temporarily.
exports.adminRoutes.patch("/instruments/:id/status", admin_controller_1.deleteAdminInstrument);
// GET /api/admin/vip-plans
// List fixed VIP billing plans: monthly and yearly.
exports.adminRoutes.get("/vip-plans", admin_controller_1.listAdminVipPlans);
// GET /api/admin/vip-plans/:id
// Return one VIP billing plan detail.
exports.adminRoutes.get("/vip-plans/:id", admin_controller_1.showAdminVipPlan);
// PATCH /api/admin/vip-plans/:id
// Update display/pricing fields of a fixed VIP billing plan.
exports.adminRoutes.patch("/vip-plans/:id", admin_controller_1.updateAdminVipPlan);
// GET /api/admin/payments
// List payments with pagination and filters.
exports.adminRoutes.get("/payments", admin_controller_1.listAdminPayments);
// GET /api/admin/payments/:id
// Return one payment detail.
exports.adminRoutes.get("/payments/:id", admin_controller_1.showAdminPayment);
// GET /api/admin/subscriptions
// List subscriptions with pagination and filters.
exports.adminRoutes.get("/subscriptions", admin_controller_1.listAdminSubscriptions);
// GET /api/admin/subscriptions/:id
// Return one subscription detail.
exports.adminRoutes.get("/subscriptions/:id", admin_controller_1.showAdminSubscription);
// PATCH /api/admin/subscriptions/:id/status
// Update subscription status.
exports.adminRoutes.patch("/subscriptions/:id/status", admin_controller_1.updateAdminSubscriptionStatus);
