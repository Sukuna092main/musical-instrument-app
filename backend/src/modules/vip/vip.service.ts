import { prisma } from "../../config/prisma";

export async function getActiveVipsPlans() {
    return await prisma.vip_plans.findMany({
        where: { status: "active" },
        orderBy: { price: "asc" },
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