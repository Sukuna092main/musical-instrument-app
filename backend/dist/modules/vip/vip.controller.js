"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.showMySubscription = exports.listVipPlans = void 0;
const vip_service_1 = require("./vip.service");
const asyncHandler_1 = require("../../utils/asyncHandler");
exports.listVipPlans = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const plans = await (0, vip_service_1.getActiveVipsPlans)();
    res.status(200).json(plans);
});
// Tạm thời nhận userId qua query để test.
// Sau này có JWT rồi sẽ lấy từ req.user.
exports.showMySubscription = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    if (!req.user) {
        res.status(401).json({ message: "Unauthorized" });
        return;
    }
    const subscription = await (0, vip_service_1.getUserActiveSubscription)(req.user.id);
    res.status(200).json(subscription);
});
