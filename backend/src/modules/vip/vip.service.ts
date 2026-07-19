import { prisma } from "../../config/prisma";

const fixedVipPlanCodes = ["VIP_MONTHLY", "VIP_YEARLY"];

// Các status được tính là VIP: active (đã thanh toán) hoặc trial (đang chờ duyệt).
const VIP_STATUSES = ["active", "trial"];

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
            status: { in: VIP_STATUSES },
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