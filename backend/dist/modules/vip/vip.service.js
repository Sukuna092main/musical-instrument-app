"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getActiveVipsPlans = getActiveVipsPlans;
exports.getUserActiveSubscription = getUserActiveSubscription;
exports.userHasActiveVip = userHasActiveVip;
const prisma_1 = require("../../config/prisma");
const fixedVipPlanCodes = ["VIP_MONTHLY", "VIP_YEARLY"];
// Các status được tính là VIP: active (đã thanh toán) hoặc trial (đang chờ duyệt).
const VIP_STATUSES = ["active", "trial"];
async function getActiveVipsPlans() {
    return await prisma_1.prisma.vip_plans.findMany({
        where: {
            status: "active",
            code: { in: fixedVipPlanCodes },
        },
        orderBy: { duration_days: "asc" },
    });
}
async function getUserActiveSubscription(userId) {
    const now = new Date();
    return await prisma_1.prisma.subscriptions.findFirst({
        where: {
            user_id: userId,
            status: { in: VIP_STATUSES },
            expired_at: { gt: now }
        },
        include: {
            vip_plans: true,
        },
        orderBy: { expired_at: "desc" },
    });
}
async function userHasActiveVip(userId) {
    const subscription = await getUserActiveSubscription(userId);
    return Boolean(subscription);
}
