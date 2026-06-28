import { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { getPaymentHistory, createDevSuccessfulPayment } from "./payment.service";

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

export const listPaymentHistory = asyncHandler(async (req:Request, res:Response) => {
    if (!req.user) {
        return res.status(401).json({message: "Unauthorized"});
    }

    const payments = await getPaymentHistory(req.user.id);

    res.status(201).json(payments);
})