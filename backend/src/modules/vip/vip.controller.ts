import { Request, Response } from "express";
import { getActiveVipsPlans, getUserActiveSubscription} from "./vip.service";
import { asyncHandler } from "../../utils/asyncHandler";

export const listVipPlans = asyncHandler(async (req: Request, res: Response) => {
    const plans = await getActiveVipsPlans();
    res.status(200).json(plans);
});

// Tạm thời nhận userId qua query để test.
// Sau này có JWT rồi sẽ lấy từ req.user.
export const showMySubscription = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
        res.status(401).json({message: "Unauthorized"});
        return;
    }

    const subscription = await getUserActiveSubscription(req.user.id);

    res.status(200).json(subscription);
});