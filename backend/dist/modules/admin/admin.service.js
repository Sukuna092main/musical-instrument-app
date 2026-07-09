"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getAdminDashboard = getAdminDashboard;
exports.listUsersForAdmin = listUsersForAdmin;
exports.getUserForAdmin = getUserForAdmin;
exports.updateUserStatusForAdmin = updateUserStatusForAdmin;
exports.listInstrumentsForAdmin = listInstrumentsForAdmin;
exports.getInstrumentForAdmin = getInstrumentForAdmin;
exports.createInstrumentForAdmin = createInstrumentForAdmin;
exports.updateInstrumentForAdmin = updateInstrumentForAdmin;
exports.hideInstrumentForAdmin = hideInstrumentForAdmin;
exports.listVipPlansForAdmin = listVipPlansForAdmin;
exports.getVipPlanForAdmin = getVipPlanForAdmin;
exports.updateVipPlanForAdmin = updateVipPlanForAdmin;
exports.listPaymentsForAdmin = listPaymentsForAdmin;
exports.getPaymentForAdmin = getPaymentForAdmin;
exports.listSubscriptionsForAdmin = listSubscriptionsForAdmin;
exports.getSubscriptionForAdmin = getSubscriptionForAdmin;
exports.updateSubscriptionStatusForAdmin = updateSubscriptionStatusForAdmin;
const prisma_1 = require("../../config/prisma");
function sunAmount(result) {
    return result._sum.amount || 0;
}
function startOfToday() {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth(), now.getDate());
}
function daysAgo(days) {
    const date = new Date();
    date.setDate(date.getDate() - days);
    return date;
}
function startOfCurrentMonth() {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth(), 1);
}
async function getAdminDashboard() {
    const today = startOfToday();
    const last7Days = daysAgo(7);
    const last30Days = daysAgo(30);
    const currentMonth = startOfCurrentMonth();
    const [grossRevenue, refundedRevenue, todayRevenue, last7DaysRevenue, last30DaysRevenue, totalUsers, newUsersToday, newUsersLast7Days, blockedUsers, activeSubscriptions, newSubscriptionsThisMonth, expiredSubscriptions, cancelledSubscriptions, paymentStatusGroups, totalInstruments, freeInstruments, vipInstruments, activeInstruments, hiddenInstruments,] = await Promise.all([
        prisma_1.prisma.payments.aggregate({
            where: { status: "success" },
            _sum: { amount: true },
        }),
        prisma_1.prisma.payments.aggregate({
            where: { status: "refunded" },
            _sum: { amount: true },
        }),
        prisma_1.prisma.payments.aggregate({
            where: { status: "success", created_at: { gte: today } },
            _sum: { amount: true },
        }),
        prisma_1.prisma.payments.aggregate({
            where: { status: "success", created_at: { gte: last7Days } },
            _sum: { amount: true },
        }),
        prisma_1.prisma.payments.aggregate({
            where: { status: "success", created_at: { gte: last30Days } },
            _sum: { amount: true },
        }),
        prisma_1.prisma.users.count(),
        prisma_1.prisma.users.count({ where: { created_at: { gte: today } } }),
        prisma_1.prisma.users.count({ where: { created_at: { gte: last7Days } } }),
        prisma_1.prisma.users.count({ where: { status: "blocked" } }),
        prisma_1.prisma.subscriptions.count({ where: {
                status: "active",
                expired_at: { gte: new Date() }
            }
        }),
        prisma_1.prisma.subscriptions.count({
            where: { created_at: { gte: currentMonth } }
        }),
        prisma_1.prisma.subscriptions.count({
            where: { status: "expired" }
        }),
        prisma_1.prisma.subscriptions.count({
            where: { status: "cancelled" }
        }),
        prisma_1.prisma.payments.groupBy({
            by: ["status"],
            _count: { status: true },
        }),
        prisma_1.prisma.instruments.count(),
        prisma_1.prisma.instruments.count({ where: { is_vip: false } }),
        prisma_1.prisma.instruments.count({ where: { is_vip: true } }),
        prisma_1.prisma.instruments.count({ where: { status: "active" } }),
        prisma_1.prisma.instruments.count({ where: { status: "hidden" } }),
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
            paymentCounts[group.status] = group._count.status;
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
const allowUsersStatuses = ["active", "blocked", "deleted"];
const allowUsersRoles = ["user", "admin"];
function normalizePagination(page, limit) {
    const p = typeof page === 'number' && page > 0 ? page : 1;
    const l = typeof limit === 'number' && limit > 0 && limit <= 100 ? limit : 20;
    return { page: p, limit: l, skip: (p - 1) * l };
}
async function listUsersForAdmin(input) {
    const { page, limit, skip } = normalizePagination(input.page, input.limit);
    const where = {};
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
        prisma_1.prisma.users.findMany({
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
        prisma_1.prisma.users.count({ where }),
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
async function getUserForAdmin(userId) {
    return prisma_1.prisma.users.findUnique({
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
async function updateUserStatusForAdmin(userId, newStatus) {
    if (!allowUsersStatuses.includes(newStatus)) {
        throw new Error(`Invalid status: ${newStatus}`);
    }
    const user = await prisma_1.prisma.users.findUnique({ where: { id: userId } });
    if (!user) {
        throw new Error(`User not found with id: ${userId}`);
    }
    const updatedUser = await prisma_1.prisma.users.update({
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
const allowedInstrumentTypes = [
    "guitar",
    "piano",
    "drum",
    "violin",
    "saxophone",
    "flute",
    "other",
];
const allowedInstrumentStatuses = ["active", "hidden", "deleted"];
function validateInstrumentType(type) {
    return allowedInstrumentTypes.includes(type);
}
function validateInstrumentStatus(status) {
    return allowedInstrumentStatuses.includes(status);
}
async function listInstrumentsForAdmin(input) {
    const { page, limit, skip } = normalizePagination(input.page, input.limit);
    const where = {};
    if (input.status && validateInstrumentStatus(input.status)) {
        where.status = input.status;
    }
    if (input.type && validateInstrumentType(input.type)) {
        where.type = input.type;
    }
    if (typeof input.isVip === "boolean") {
        where.is_vip = input.isVip;
    }
    if (input.search && input.search.trim() !== "") {
        const search = input.search.trim();
        where.OR = [
            {
                name: { contains: search, mode: "insensitive" },
            },
            {
                description: { contains: search, mode: "insensitive" },
            },
        ];
    }
    const [items, total] = await Promise.all([
        prisma_1.prisma.instruments.findMany({
            where,
            skip,
            take: limit,
            orderBy: { created_at: "desc" },
        }),
        prisma_1.prisma.instruments.count({ where }),
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
async function getInstrumentForAdmin(instrumentId) {
    return prisma_1.prisma.instruments.findUnique({
        where: { id: instrumentId },
    });
}
async function createInstrumentForAdmin(input) {
    if (!validateInstrumentType(input.type)) {
        throw new Error(`Invalid instrument type: ${input.type}`);
    }
    const status = input.status || "active";
    if (!validateInstrumentStatus(status)) {
        throw new Error(`Invalid instrument status: ${status}`);
    }
    const newInstrument = await prisma_1.prisma.instruments.create({
        data: {
            name: input.name.trim(),
            type: input.type,
            description: input.description ?? '',
            image_url: input.imageUrl ?? '',
            audio_sample_url: input.audioSampleUrl,
            tags: input.tags ?? [],
            is_vip: input.isVip,
            status: status,
            updated_at: new Date(),
        }
    });
    return { instrument: newInstrument };
}
async function updateInstrumentForAdmin(instrumentId, input) {
    const existingInstrument = await prisma_1.prisma.instruments.findUnique({
        where: { id: instrumentId }
    });
    if (!existingInstrument) {
        throw new Error(`Instrument not found with id: ${instrumentId}`);
    }
    if (input.type && !validateInstrumentType(input.type)) {
        throw new Error(`Invalid instrument type: ${input.type}`);
    }
    if (input.status && !validateInstrumentStatus(input.status)) {
        throw new Error(`Invalid instrument status: ${input.status}`);
    }
    const updatedInstrument = await prisma_1.prisma.instruments.update({
        where: { id: instrumentId },
        data: {
            ...(input.name !== undefined && { name: input.name.trim() }),
            ...(input.type !== undefined && { type: input.type }),
            ...(input.description !== undefined && { description: input.description.trim() }),
            ...(input.imageUrl !== undefined && { image_url: input.imageUrl.trim() }),
            ...(input.audioSampleUrl !== undefined && { audio_sample_url: input.audioSampleUrl }),
            ...(input.tags !== undefined && { tags: input.tags }),
            ...(input.isVip !== undefined && { is_vip: input.isVip }),
            ...(input.tags !== undefined && { tags: input.tags }),
            ...(input.status !== undefined && { status: input.status }),
            updated_at: new Date(),
        },
    });
    return { instrument: updatedInstrument };
}
async function hideInstrumentForAdmin(instrumentId) {
    const existingInstrument = await prisma_1.prisma.instruments.findUnique({
        where: { id: instrumentId }
    });
    if (!existingInstrument) {
        throw new Error(`Instrument not found with id: ${instrumentId}`);
    }
    const updatedInstrument = await prisma_1.prisma.instruments.update({
        where: { id: instrumentId },
        data: {
            status: "hidden",
            updated_at: new Date(),
        },
    });
    return { instrument: updatedInstrument };
}
const fixedVipPlanCodes = ["VIP_MONTHLY", "VIP_YEARLY"];
const allowedVipPlanStatuses = ["active", "inactive"];
const allowedVipPlanCurrencies = ["USD", "EUR", "VND"];
async function listVipPlansForAdmin(input) {
    const where = {
        code: { in: fixedVipPlanCodes },
    };
    if (input.status && allowedVipPlanStatuses.includes(input.status)) {
        where.status = input.status;
    }
    const items = await prisma_1.prisma.vip_plans.findMany({
        where,
        orderBy: { duration_days: "asc" },
    });
    return {
        items,
        meta: {
            mode: "fixed_vip_plans",
            editableFields: ["name", "description", "price", "currency", "features", "status"],
            lockedFields: ["code", "duration_days"],
        },
    };
}
async function getVipPlanForAdmin(planId) {
    const vipPlan = await prisma_1.prisma.vip_plans.findUnique({
        where: { id: planId },
    });
    if (!vipPlan || !fixedVipPlanCodes.includes(vipPlan.code)) {
        throw new Error(`VIP plan not found with id: ${planId}`);
    }
    return { vipPlan };
}
async function updateVipPlanForAdmin(planId, input) {
    const existingPlan = await prisma_1.prisma.vip_plans.findUnique({
        where: { id: planId },
    });
    if (!existingPlan || !fixedVipPlanCodes.includes(existingPlan.code)) {
        throw new Error(`VIP plan not found with id: ${planId}`);
    }
    if (input.currency && !allowedVipPlanCurrencies.includes(input.currency)) {
        throw new Error(`Invalid currency: ${input.currency}`);
    }
    if (input.status && !allowedVipPlanStatuses.includes(input.status)) {
        throw new Error(`Invalid status: ${input.status}`);
    }
    if (input.price !== undefined && input.price < 0) {
        throw new Error(`Price cannot be negative: ${input.price}`);
    }
    const plan = await prisma_1.prisma.vip_plans.update({
        where: { id: planId },
        data: {
            ...(input.name !== undefined && { name: input.name.trim() }),
            ...(input.description !== undefined && { description: input.description }),
            ...(input.price !== undefined && { price: input.price }),
            ...(input.currency !== undefined && { currency: input.currency }),
            ...(input.features !== undefined && { features: input.features }),
            ...(input.status !== undefined && { status: input.status }),
            updated_at: new Date(),
        },
    });
    return { vipPlan: plan };
}
const allowedPaymentStatuses = ["success", "pending", "refunded", "failed", "cancelled"];
const allowedPaymentProviders = [
    "google_play",
    "apple_app_store",
    "momo",
    "zalopay",
    "vnpay",
    "manual",
];
async function listPaymentsForAdmin(input) {
    const { page, limit, skip } = normalizePagination(input.page, input.limit);
    const where = {};
    if (!input.status || allowedPaymentStatuses.includes(input.status)) {
        where.status = input.status;
    }
    if (!input.provider || allowedPaymentProviders.includes(input.provider)) {
        where.provider = input.provider;
    }
    if (input.userId) {
        where.user_id = input.userId;
    }
    const [items, total] = await Promise.all([
        prisma_1.prisma.payments.findMany({
            where,
            skip,
            take: limit,
            orderBy: { created_at: "desc" },
            include: {
                users: {
                    select: {
                        id: true,
                        full_name: true,
                        email: true,
                        role: true,
                        status: true
                    }
                },
                vip_plans: {
                    select: {
                        id: true,
                        code: true,
                        name: true,
                        duration_days: true
                    }
                }
            }
        }),
        prisma_1.prisma.payments.count({ where })
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
async function getPaymentForAdmin(id) {
    return prisma_1.prisma.payments.findUnique({
        where: { id },
        include: {
            users: {
                select: {
                    id: true,
                    full_name: true,
                    email: true,
                    role: true,
                    status: true,
                },
            },
            vip_plans: true,
        },
    });
}
const allowedSubscriptionStatuses = [
    "active",
    "expired",
    "cancelled",
    "pending",
];
async function listSubscriptionsForAdmin(input) {
    const { page, limit, skip } = normalizePagination(input.page, input.limit);
    const where = {};
    if (input.status && allowedSubscriptionStatuses.includes(input.status)) {
        where.status = input.status;
    }
    if (input.userId) {
        where.user_id = input.userId;
    }
    if (input.planId) {
        where.plan_id = input.planId;
    }
    const [items, total] = await Promise.all([
        prisma_1.prisma.subscriptions.findMany({
            where,
            skip,
            take: limit,
            orderBy: {
                created_at: "desc",
            },
            include: {
                users: {
                    select: {
                        id: true,
                        full_name: true,
                        email: true,
                        role: true,
                        status: true,
                    },
                },
                vip_plans: {
                    select: {
                        id: true,
                        code: true,
                        name: true,
                        duration_days: true,
                    },
                },
            },
        }),
        prisma_1.prisma.subscriptions.count({ where }),
    ]);
    return {
        items,
        pagination: {
            page,
            limit,
            total,
            totalPages: Math.ceil(total / limit),
        },
    };
}
async function getSubscriptionForAdmin(id) {
    return prisma_1.prisma.subscriptions.findUnique({
        where: {
            id,
        },
        include: {
            users: {
                select: {
                    id: true,
                    full_name: true,
                    email: true,
                    role: true,
                    status: true,
                },
            },
            vip_plans: true,
        },
    });
}
async function updateSubscriptionStatusForAdmin(id, status) {
    if (!allowedSubscriptionStatuses.includes(status)) {
        return {
            error: "Invalid subscription status",
        };
    }
    const existingSubscription = await prisma_1.prisma.subscriptions.findUnique({
        where: {
            id,
        },
    });
    if (!existingSubscription) {
        return {
            error: "Subscription not found",
        };
    }
    const subscription = await prisma_1.prisma.subscriptions.update({
        where: {
            id,
        },
        data: {
            status,
            cancelled_at: status === "cancelled" ? new Date() : null,
            updated_at: new Date(),
        },
        include: {
            users: {
                select: {
                    id: true,
                    full_name: true,
                    email: true,
                    role: true,
                    status: true,
                },
            },
            vip_plans: true,
        },
    });
    return {
        subscription,
    };
}
