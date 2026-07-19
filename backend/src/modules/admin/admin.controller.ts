import { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { 
    getAdminDashboard,
    getUserForAdmin,
    listUsersForAdmin,
    updateUserStatusForAdmin,
    createInstrumentForAdmin,
    getInstrumentForAdmin,
    listInstrumentsForAdmin,
    updateInstrumentForAdmin,
    hideInstrumentForAdmin,
    getVipPlanForAdmin,
    listVipPlansForAdmin,
    updateVipPlanForAdmin,
    getPaymentForAdmin,
    listPaymentsForAdmin,
    getSubscriptionForAdmin,
    listSubscriptionsForAdmin,
    updateSubscriptionStatusForAdmin
} from "./admin.service";
import {
  listManualRequestsForAdmin,
  approveManualRequest,
  rejectManualRequest,
} from "../payments/manual-payment.service";

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

export const listAdminInstruments = asyncHandler(
  async (req: Request, res: Response) => {
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 20);

    const isVipQuery = req.query.isVip;
    const isVip =
      isVipQuery === "true" ? true : isVipQuery === "false" ? false : undefined;

    const result = await listInstrumentsForAdmin({
      page,
      limit,
      search: req.query.search as string | undefined,
      status: req.query.status as "active" | "hidden" | "deleted" | undefined,
      type: req.query.type as string | undefined,
      isVip,
    });

    res.json({
      data: result,
    });
  }
);

export const showAdminInstrument = asyncHandler(
  async (req: Request, res: Response) => {
    const instrument = await getInstrumentForAdmin(req.params.id as string);

    if (!instrument) {
      res.status(404).json({
        message: "Instrument not found",
      });
      return;
    }

    res.json({
      data: instrument,
    });
  }
);

export const createAdminInstrument = asyncHandler(
  async (req: Request, res: Response) => {
    const {
      name,
      type,
      description,
      imageUrl,
      audioSampleUrl,
      isVip,
      tags,
      status,
    } = req.body;

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

    const result = await createInstrumentForAdmin({
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
  }
);

export const updateAdminInstrument = asyncHandler(
  async (req: Request, res: Response) => {
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

    const result = await updateInstrumentForAdmin(req.params.id as string, req.body);

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
  }
);

export const deleteAdminInstrument = asyncHandler(
  async (req: Request, res: Response) => {
    const result = await hideInstrumentForAdmin(req.params.id as string);

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
  }
);

export const listAdminVipPlans = asyncHandler(async (req: Request, res: Response) => {
    const result = await listVipPlansForAdmin({
        status: req.query.status as "active" | "inactive" | undefined,
    });

    res.json({
        data: result,
    });
})

export const showAdminVipPlan = asyncHandler(async (req: Request, res: Response) => {
    const plan = await getVipPlanForAdmin(req.params.id as string);

    if (!plan) {
        return res.status(404).json({ message: "VIP plan not found" });
    }

    res.json({ data: plan });
})

export const updateAdminVipPlan = asyncHandler(async (req: Request, res: Response) => {
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

    const result = await updateVipPlanForAdmin(req.params.id as string, req.body);

    if ("error" in result) {
        const statusCode = result.error === "VIP plan not found" ? 404 : 400;
        return res.status(statusCode).json({ message: result.error });
    }

    res.json({ message: "VIP plan updated successfully", data: result });
})

export const listAdminPayments = asyncHandler(
  async (req: Request, res: Response) => {
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 20);

    const result = await listPaymentsForAdmin({
      page,
      limit,
      status: req.query.status as string | undefined,
      provider: req.query.provider as string | undefined,
      userId: req.query.userId as string | undefined,
    });

    res.json({
      data: result,
    });
  }
);

export const showAdminPayment = asyncHandler(
  async (req: Request, res: Response) => {
    const payment = await getPaymentForAdmin(req.params.id as string);

    if (!payment) {
      return res.status(404).json({message: "Payment not found"});
    }

    res.json({
      data: payment,
    });
  }
);

export const listAdminSubscriptions = asyncHandler(
  async (req: Request, res: Response) => {
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 20);

    const result = await listSubscriptionsForAdmin({
      page,
      limit,
      status: req.query.status as string | undefined,
      userId: req.query.userId as string | undefined,
      planId: req.query.planId as string | undefined,
    });

    res.json({
      data: result,
    });
  }
);

export const showAdminSubscription = asyncHandler(
  async (req: Request, res: Response) => {
    const subscription = await getSubscriptionForAdmin(req.params.id as string);

    if (!subscription) {
      res.status(404).json({
        message: "Subscription not found",
      });
      return;
    }

    res.json({
      data: subscription,
    });
  }
);

export const updateAdminSubscriptionStatus = asyncHandler(
  async (req: Request, res: Response) => {
    const { status } = req.body;

    if (!status || typeof status !== "string") {
      res.status(400).json({
        message: "status is required",
      });
      return;
    }

    const result = await updateSubscriptionStatusForAdmin(
      req.params.id as string,
      status
    );

    if ("error" in result) {
      const statusCode =
        result.error === "Subscription not found" ? 404 : 400;

      res.status(statusCode).json({
        message: result.error,
      });
      return;
    }

    res.json({
      data: result.subscription,
    });
  }
);

// GET /api/admin/manual-payments?status=pending
export const listAdminManualPayments = asyncHandler(async (req: Request, res: Response) => {
  const page = Number(req.query.page || 1);
  const limit = Number(req.query.limit || 20);
  const result = await listManualRequestsForAdmin({
    page,
    limit,
    status: req.query.status as string | undefined,
    userId: req.query.userId as string | undefined,
  });
  res.json({ data: result });
});

// POST /api/admin/manual-payments/:id/approve
export const approveAdminManualPayment = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    return res.status(401).json({ message: "Unauthorized" });
  }
  const result = await approveManualRequest(req.params.id as string, req.user.id);
  if ("error" in result) {
    const code = result.error.includes("not found") ? 404 : 400;
    return res.status(code).json({ message: result.error });
  }
  res.json({ data: result });
});

// POST /api/admin/manual-payments/:id/reject
export const rejectAdminManualPayment = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    return res.status(401).json({ message: "Unauthorized" });
  }
  const { reason } = req.body || {};
  const result = await rejectManualRequest(req.params.id as string, req.user.id, reason);
  if ("error" in result) {
    const code = result.error.includes("not found") ? 404 : 400;
    return res.status(code).json({ message: result.error });
  }
  res.json({ data: result });
});