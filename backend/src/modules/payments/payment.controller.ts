import { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { getPaymentHistory, createDevSuccessfulPayment } from "./payment.service";
import { createManualRequest, listMyManualRequests } from "./manual-payment.service";

export const devSuccessPayment = asyncHandler(async (req:Request,res:Response) => {
    if (!req.user) {
        return res.status(401).json({message:"Unauthorized"})
    }

    const {planCode} = req.body;

    if (!planCode) {
        return res.status(400).json({message:"Plan code is required"});
    }

    const result = await createDevSuccessfulPayment(req.user.id, planCode);

    if ("error" in result) {
        return res.status(404).json({message: result.error});
    }

    res.status(201).json(result);
});

// POST /api/payments/manual/request
// User gửi yêu cầu mua VIP qua chuyển khoản. Backend cấp trial 24h ngay lập tức.
export const requestManualVip = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
    }

    const { planCode, provider, transferCode, note } = req.body || {};
    if (!planCode) {
        return res.status(400).json({ message: "planCode is required" });
    }

    const result = await createManualRequest({
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
export const listMyManualRequestsHandler = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
    }
    const items = await listMyManualRequests(req.user.id);
    res.status(200).json({ items });
});

export const listPaymentHistory = asyncHandler(async (req:Request, res:Response) => {
    if (!req.user) {
        return res.status(401).json({message: "Unauthorized"});
    }

    const payments = await getPaymentHistory(req.user.id);

    res.status(200).json(payments);
})