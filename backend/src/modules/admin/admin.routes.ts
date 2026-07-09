import { Router } from "express";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { adminMiddleware } from "../../middlewares/admin.middleware";
import { 
    showAdminDashboard,
    listAdminUsers,
    showAdminUser,
    updateAdminUserStatus,
    createAdminInstrument,
    showAdminInstrument,
    listAdminInstruments,
    updateAdminInstrument,
    deleteAdminInstrument,
    listAdminVipPlans,
    showAdminVipPlan,
    updateAdminVipPlan,
    listAdminPayments,
    showAdminPayment
 } from "./admin.controller";

export const adminRoutes = Router();

adminRoutes.use(authMiddleware, adminMiddleware);

// GET /api/admin/dashboard
// Return revenue and operational summary for admin dashboard.
adminRoutes.get("/dashboard", showAdminDashboard);

// GET /api/admin/users
// List users with pagination, search, role, and status filters.
adminRoutes.get("/users", listAdminUsers);

// GET /api/admin/users/:id
// Return one user detail for admin.
adminRoutes.get("/users/:id", showAdminUser);

// PATCH /api/admin/users/:id/status
// Update user account status: active, blocked, or deleted.
adminRoutes.patch("/users/:id/status", updateAdminUserStatus);

// GET /api/admin/instruments
// List instruments with pagination and filters.
adminRoutes.get("/instruments", listAdminInstruments);

// GET /api/admin/instruments/:id
// Return one instrument detail.
adminRoutes.get("/instruments/:id", showAdminInstrument);

// POST /api/admin/instruments
// Create a new instrument.
adminRoutes.post("/instruments", createAdminInstrument);

// PATCH /api/admin/instruments/:id
// Update an instrument.
adminRoutes.patch("/instruments/:id", updateAdminInstrument);

// PATCH /api/admin/instruments/:id/status
// Delete an instrument temporarily.
adminRoutes.patch("/instruments/:id/status", deleteAdminInstrument);

// GET /api/admin/vip-plans
// List fixed VIP billing plans: monthly and yearly.
adminRoutes.get("/vip-plans", listAdminVipPlans);

// GET /api/admin/vip-plans/:id
// Return one VIP billing plan detail.
adminRoutes.get("/vip-plans/:id", showAdminVipPlan);

// PATCH /api/admin/vip-plans/:id
// Update display/pricing fields of a fixed VIP billing plan.
adminRoutes.patch("/vip-plans/:id", updateAdminVipPlan);

// GET /api/admin/payments
// List payments with pagination and filters.
adminRoutes.get("/payments", listAdminPayments);

// GET /api/admin/payments/:id
// Return one payment detail.
adminRoutes.get("/payments/:id", showAdminPayment);