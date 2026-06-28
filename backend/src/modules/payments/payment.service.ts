import { error } from "node:console";
import { prisma } from "../../config/prisma";

export async function createDevSuccessfulPayment(userId:string, planCode:string) {
    const plan = await prisma.vip_plans.findUnique({
        where: {code:planCode}
    });

    if (!plan || plan.status !== 'active') {
        return { error: "VIP plan not found" }
    }

    const now = new Date();
    const expiredAt = new Date(now);
    expiredAt.setDate(expiredAt.getDate() + plan.duration_days);

    const transactionId = `DEV-${userId}-${plan.code}-${Date.now()}`;

    const result = await prisma.$transaction(async (tx) => {
        const payment = await tx.payments.create({
            data: {
                user_id: userId,
                plan_id: plan.id,
                amount: plan.price,
                currency: plan.currency,
                provider: "manual",
                status: "success",
                transaction_id: transactionId,
                raw_response: {
                    mode: "development"
                },
            },
        });

        const subscription = await tx.subscriptions.create({
            data: {
                user_id: userId,
                plan_id: plan.id,
                status: "active",
                started_at: now,
                expired_at: expiredAt,
            },
            include: {vip_plans: true}
        });

        return {payment, subscription};
    });
    
    return result;
}

export async function getPaymentHistory(userId:string) {
    return prisma.payments.findMany({
        where: {user_id:userId},
        include: {vip_plans:true},
        orderBy: {created_at: 'desc'}
    });
}