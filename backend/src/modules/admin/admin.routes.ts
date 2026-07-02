import { Router } from "express";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { adminMiddleware } from "../../middlewares/admin.middleware";
import { 
    showAdminDashboard,
    listAdminUsers,
    showAdminUser,
    updateAdminUserStatus
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