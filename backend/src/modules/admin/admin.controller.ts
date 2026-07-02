import { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { 
    getAdminDashboard,
    getUserForAdmin,
    listUsersForAdmin,
    updateUserStatusForAdmin,
} from "./admin.service";

export const showAdminDashboard = asyncHandler(
  async (_req: Request, res: Response) => {
    const dashboard = await getAdminDashboard();

    res.json({
      data: dashboard,
    });
  }
);

export const listAdminUsers = asyncHandler(async (req: Request, res: Response) => {
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 20);

    const result = await listUsersForAdmin({ 
        page, 
        limit,
        search: req.query.search as string | undefined,
        status: req.query.status as string | undefined,
        role: req.query.role as "user" | "admin" | undefined,
    });

    res.json(result);
})

export const showAdminUser = asyncHandler(async (req: Request, res: Response) => {
    const user = await getUserForAdmin(req.params.id as string);

    if (!user) {
        return res.status(404).json({ message: "User not found" });
    }

    res.json({ data: user });
});

export const updateAdminUserStatus = asyncHandler(async (req: Request, res: Response) => {
    const newStatus = req.body.status as "active" | "blocked" | "deleted";

    if (!newStatus || typeof newStatus !== "string" || !["active", "blocked", "deleted"].includes(newStatus)) {
        return res.status(400).json({ message: "Invalid status value" });
    }

    const result = await updateUserStatusForAdmin(req.params.id as string, newStatus);

    if ("error" in result) {
        const statusCode = result.error === "User not found" ? 404 : 400;
        return res.status(statusCode).json({ message: result.error });
    }

    res.json({ message: "User status updated successfully", data: result });
})