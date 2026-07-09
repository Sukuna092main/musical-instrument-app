import { prisma } from "../../config/prisma";

const fixedVipPlanCodes = ["VIP_MONTHLY", "VIP_YEARLY"];

export async function getActiveVipsPlans() {
    return await prisma.vip_plans.findMany({
        where: { 
            status: "active",
            code: { in: fixedVipPlanCodes },
        },
        orderBy: { duration_days: "asc" },
    });
}

export async function getUserActiveSubscription(userId: string) {
    const now = new Date();
    return await prisma.subscriptions.findFirst({
        where: {
            user_id: userId,
            status: "active",
            expired_at: {gt: now}
        },
        include: {
            vip_plans: true,
        },
        orderBy: { expired_at: "desc" },
    });
}

export async function userHasActiveVip(userId: string) {
  const subscription = await getUserActiveSubscription(userId);

  return Boolean(subscription);
}