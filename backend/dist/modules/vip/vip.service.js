"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getActiveVipsPlans = getActiveVipsPlans;
exports.getUserActiveSubscription = getUserActiveSubscription;
const prisma_1 = require("../../config/prisma");
async function getActiveVipsPlans() {
    return await prisma_1.prisma.vip_plans.findMany({
        where: { status: "active" },
        orderBy: { price: "asc" },
    });
}
async function getUserActiveSubscription(userId) {
    const now = new Date();
    return await prisma_1.prisma.subscriptions.findFirst({
        where: {
            user_id: userId,
            status: "active",
            expired_at: { gt: now }
        },
        include: {
            vip_plans: true,
        },
        orderBy: { expired_at: "desc" },
    });
}
