import { prisma } from "../../config/prisma";

function sunAmount(result: { _sum: { amount: number | null } }) {
    return result._sum.amount || 0;
}

function startOfToday() {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth(), now.getDate());
}

function daysAgo(days: number) {
     const date = new Date();
    date.setDate(date.getDate() - days);
    return date;
}

function startOfCurrentMonth() {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth(), 1);
}

export async function getAdminDashboard() {
    const today = startOfToday();
    const last7Days = daysAgo(7);
    const last30Days = daysAgo(30);
    const currentMonth = startOfCurrentMonth();

    const [
        grossRevenue,
        refundedRevenue,
        todayRevenue,
        last7DaysRevenue,
        last30DaysRevenue,
        totalUsers,
        newUsersToday,
        newUsersLast7Days,
        blockedUsers,
        activeSubscriptions,
        newSubscriptionsThisMonth,
        expiredSubscriptions,
        cancelledSubscriptions,
        paymentStatusGroups,
        totalInstruments,
        freeInstruments,
        vipInstruments,
        activeInstruments,
        hiddenInstruments,
    ] = await Promise.all([
        prisma.payments.aggregate({
            where: { status: "success" },
            _sum: { amount: true },
        }),
        prisma.payments.aggregate({
            where: { status: "refunded" },
            _sum: { amount: true },
        }),
        prisma.payments.aggregate({
            where: { status: "success", created_at: { gte: today } },
            _sum: { amount: true },
        }),
        prisma.payments.aggregate({
            where: { status: "success", created_at: { gte: last7Days } },
            _sum: { amount: true },
        }),
        prisma.payments.aggregate({
            where: { status: "success", created_at: { gte: last30Days } },
            _sum: { amount: true },
        }),
        prisma.users.count(),
        prisma.users.count({ where: { created_at: { gte: today } } }),
        prisma.users.count({ where: { created_at: { gte: last7Days } } }),
        prisma.users.count({ where: { status: "blocked" } }),
        prisma.subscriptions.count({ where: 
            { 
                status: "active",
                expired_at: { gte: new Date() }
            }
        }),
        prisma.subscriptions.count({
            where: {created_at: { gte: currentMonth } }
        }),
        prisma.subscriptions.count({
            where: { status: "expired" }
        }),
        prisma.subscriptions.count({
            where: { status: "cancelled" }
        }),
        prisma.payments.groupBy({
            by: ["status"],
            _count: { status: true },
        }),
        prisma.instruments.count(),
        prisma.instruments.count({ where: { is_vip: false } }),
        prisma.instruments.count({ where: { is_vip: true } }),
        prisma.instruments.count({ where: { status: "active" } }),
        prisma.instruments.count({ where: { status: "hidden" } }),
    ]);

    const grossTotal = sunAmount(grossRevenue);
    const refundedTotal = sunAmount(refundedRevenue);

    const paymentCounts = {
        success: 0,
        pending: 0,
        refunded: 0,
        failed: 0,
    };

    for (const group of paymentStatusGroups) {
        if (group.status in paymentCounts) {
            paymentCounts[group.status as keyof typeof paymentCounts] = group._count.status;
        }
    }

    return {
        revenue: {
            grossTotal,
            refundedTotal,
            netTotal: grossTotal - refundedTotal,
            today: sunAmount(todayRevenue),
            last7Days: sunAmount(last7DaysRevenue),
            last30Days: sunAmount(last30DaysRevenue),
        },
        users: {
            total: totalUsers,
            newToday: newUsersToday,
            newLast7Days: newUsersLast7Days,
            blocked: blockedUsers,
        },
        subscriptions: {
            active: activeSubscriptions,
            newThisMonth: newSubscriptionsThisMonth,
            expired: expiredSubscriptions,
            cancelled: cancelledSubscriptions,
        },
        payments: paymentCounts,
        instruments: {
            total: totalInstruments,
            free: freeInstruments,
            vip: vipInstruments,
            active: activeInstruments,
            hidden: hiddenInstruments,
        },
    };
}

type ListAdminUsersInput = {
    page?: number;
    limit?: number;
    search?: string;
    status?: string;
    role?: "user" | "admin";
};

const allowUsersStatuses = ["active", "blocked", "deleted"];
const allowUsersRoles = ["user", "admin"];

function normalizePagination(page?: number, limit?: number) {
    const safePage = Number.isFinite(page) && page && page > 0 ? page : 1;
    const safeLimit = 
        Number.isFinite(limit) && limit && limit > 0 && limit <= 100 ? limit : 20;
    
    return {
        page: safePage,
        limit: safeLimit,
        skip: (safePage - 1) * safeLimit,
    };
}

export async function listUsersForAdmin(input: ListAdminUsersInput) {
    const { page, limit, skip } = normalizePagination(input.page, input.limit);

    const where: any = {};

    if (input.status && allowUsersStatuses.includes(input.status)) {
        where.status = input.status;
    }

    if (input.role && allowUsersRoles.includes(input.role)) {
        where.role = input.role;
    }

    if (input.search && input.search.trim() !== "") {
        const search = input.search.trim();
        where.OR = [
            {
                full_name: { contains: search, mode: "insensitive" },
            },
            {
                email: { contains: search, mode: "insensitive" },
            },
        ];
    }

    const [items, total] = await Promise.all([
        prisma.users.findMany({
            where,
            skip,
            take: limit,
            orderBy: { created_at: "desc" },
            select: {
                id: true,
                full_name: true,
                email: true,
                avatar_url: true,
                phone: true,
                role: true,
                status: true,
                created_at: true,
                updated_at: true,
            }
        }),
        prisma.users.count({ where }),
    ]);

    return {
        items,
        pagination: {
            page,
            limit,
            total,
            totalPages: Math.ceil(total / limit),
        }
    };
}

export async function getUserForAdmin(userId: string) {
    return prisma.users.findUnique({
        where: { id: userId },
        select: {
            id: true,
            full_name: true,
            email: true,
            avatar_url: true,
            phone: true,
            role: true,
            status: true,
            created_at: true,
            updated_at: true,
            subscriptions: {
                orderBy: { created_at: "desc" },
                take: 5,
                include: {
                    vip_plans: true,
                },
            },
            payments: {
                orderBy: { created_at: "desc" },
                take: 10,
                include: {
                    vip_plans: true,
                },
            }
        }
    });
}

export async function updateUserStatusForAdmin(userId: string, newStatus: "active" | "blocked" | "deleted") {
    if (!allowUsersStatuses.includes(newStatus)) {
        throw new Error(`Invalid status: ${newStatus}`);
    }

    const user = await prisma.users.findUnique({ where: { id: userId } });

    if (!user) {
        throw new Error(`User not found with id: ${userId}`);
    }

    const updatedUser = await prisma.users.update({
        where: { id: userId },
        data: { 
            status: newStatus,
            updated_at: new Date(),
        },
        select: {
            id: true,
            full_name: true,
            email: true,
            role: true,
            status: true,
            updated_at: true,
        }
    });

    return { user: updatedUser };
}