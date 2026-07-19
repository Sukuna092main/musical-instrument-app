import { prisma } from "../../config/prisma";
import { env } from "../../config/env";

const ALLOWED_PLAN_CODES = ["VIP_MONTHLY", "VIP_YEARLY"];
const ALLOWED_PROVIDERS = ["bank_transfer", "momo_personal"];

// Trial: 0 = tắt; >0 = số giờ VIP trial khi tạo manual request.
const TRIAL_HOURS = Math.max(0, Number(env.manualTrialHours) || 0);

export type ManualRequestInput = {
  userId: string;
  planCode: string;
  provider?: string;
  transferCode?: string;
  note?: string;
};

export function getPaymentInfoForRequest(amount: number, transferRef: string, currency: string) {
  if (!env.bankTransferAccountNo || !env.bankTransferBankId) {
    return { configured: false as const };
  }
  const qrUrl = `https://img.vietqr.io/image/${env.bankTransferBankId}-${env.bankTransferAccountNo}-compact2.png?amount=${amount}&addInfo=${encodeURIComponent(transferRef)}&accountName=${encodeURIComponent(env.bankTransferAccountName)}`;
  return {
    configured: true as const,
    bankId: env.bankTransferBankId,
    accountNo: env.bankTransferAccountNo,
    accountName: env.bankTransferAccountName,
    amount,
    currency,
    transferRef,
    qrUrl,
  };
}

// Tạo request + cấp trial ngay lập tức (nếu bật trial).
export async function createManualRequest(input: ManualRequestInput) {
  if (!ALLOWED_PLAN_CODES.includes(input.planCode)) {
    return { error: "Invalid plan code" };
  }

  const plan = await prisma.vip_plans.findUnique({
    where: { code: input.planCode },
  });
  if (!plan || plan.status !== "active") {
    return { error: "VIP plan not found or inactive" };
  }

  // Chặn nếu user đã có sub active/trial còn hạn cho cùng plan.
  const existingActive = await prisma.subscriptions.findFirst({
    where: {
      user_id: input.userId,
      plan_id: plan.id,
      status: { in: ["active", "trial"] },
      expired_at: { gt: new Date() },
    },
    orderBy: { expired_at: "desc" },
  });
  if (existingActive) {
    return { error: "You already have an active VIP subscription for this plan" };
  }

  // Chặn nếu đã có request pending cho cùng plan.
  const existingPending = await prisma.manual_payment_requests.findFirst({
    where: { user_id: input.userId, plan_id: plan.id, status: "pending" },
  });
  if (existingPending) {
    return { error: "You already have a pending request for this plan" };
  }

  const provider =
    input.provider && ALLOWED_PROVIDERS.includes(input.provider) ? input.provider : "bank_transfer";
  const transferRef = `${env.bankTransferDescriptionPrefix}-${input.userId.slice(0, 8)}-${plan.code}`;
  const now = new Date();

  const result = await prisma.$transaction(async (tx) => {
    const request = await tx.manual_payment_requests.create({
      data: {
        user_id: input.userId,
        plan_id: plan.id,
        amount: plan.price,
        currency: plan.currency,
        provider,
        transfer_code: input.transferCode?.trim() || null,
        note: input.note?.trim() || null,
        status: "pending",
      },
    });

    // Cấp trial ngay lập tức nếu bật.
    let trial = null;
    if (TRIAL_HOURS > 0) {
      const expiredAt = new Date(now.getTime() + TRIAL_HOURS * 3600_000);
      trial = await tx.subscriptions.create({
        data: {
          user_id: input.userId,
          plan_id: plan.id,
          status: "trial",
          started_at: now,
          expired_at: expiredAt,
        },
      });
    }

    return { request, trial };
  });

  return {
    request: result.request,
    trial: result.trial,
    trialHours: TRIAL_HOURS,
    paymentInfo: getPaymentInfoForRequest(plan.price, transferRef, plan.currency),
  };
}

export async function listMyManualRequests(userId: string) {
  return prisma.manual_payment_requests.findMany({
    where: { user_id: userId },
    include: {
      vip_plans: { select: { id: true, code: true, name: true, duration_days: true } },
    },
    orderBy: { created_at: "desc" },
  });
}

export async function listManualRequestsForAdmin(input: {
  page?: number;
  limit?: number;
  status?: string;
  userId?: string;
}) {
  const page = input.page && input.page > 0 ? input.page : 1;
  const limit = input.limit && input.limit > 0 && input.limit <= 100 ? input.limit : 20;
  const skip = (page - 1) * limit;

  const where: any = {};
  if (input.status && ["pending", "approved", "rejected"].includes(input.status)) {
    where.status = input.status;
  }
  if (input.userId) where.user_id = input.userId;

  const [items, total] = await Promise.all([
    prisma.manual_payment_requests.findMany({
      where,
      skip,
      take: limit,
      orderBy: { created_at: "desc" },
      include: {
        users: { select: { id: true, full_name: true, email: true } },
        vip_plans: { select: { id: true, code: true, name: true, duration_days: true } },
      },
    }),
    prisma.manual_payment_requests.count({ where }),
  ]);

  return {
    items,
    pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
  };
}

// Approve: chuyển trial → active, expired = now + duration_days (KHÔNG cộng dồn trial).
// Nếu không có trial, cộng dồn vào sub active hiện có (nếu còn hạn).
export async function approveManualRequest(requestId: string, adminId: string) {
  const req = await prisma.manual_payment_requests.findUnique({
    where: { id: requestId },
    include: { vip_plans: true },
  });
  if (!req) return { error: "Request not found" };
  if (req.status === "approved") return { error: "Request already approved" };
  if (req.status === "rejected") return { error: "Request was rejected" };

  const now = new Date();
  const expiredAt = new Date(now.getTime() + req.vip_plans.duration_days * 86400000);
  const transactionId = `MANUAL-${req.id.slice(0, 8)}-${Date.now()}`;

  const result = await prisma.$transaction(async (tx) => {
    // Tìm sub trial còn hạn để chuyển sang active.
    const trialSub = await tx.subscriptions.findFirst({
      where: {
        user_id: req.user_id,
        plan_id: req.plan_id,
        status: "trial",
        expired_at: { gt: now },
      },
      orderBy: { expired_at: "desc" },
    });

    let subscription;
    if (trialSub) {
      // Trial → active, ghi đè expired = now + duration_days thật.
      subscription = await tx.subscriptions.update({
        where: { id: trialSub.id },
        data: {
          status: "active",
          started_at: now,
          expired_at: expiredAt,
          updated_at: now,
        },
        include: { vip_plans: true },
      });
    } else {
      // Không có trial: kiểm tra sub active hiện có để cộng dồn.
      const currentActive = await tx.subscriptions.findFirst({
        where: {
          user_id: req.user_id,
          status: "active",
          plan_id: req.plan_id,
          expired_at: { gt: now },
        },
        orderBy: { expired_at: "desc" },
      });

      if (currentActive) {
        const extendedExpiry = new Date(
          currentActive.expired_at.getTime() + req.vip_plans.duration_days * 86400000
        );
        subscription = await tx.subscriptions.update({
          where: { id: currentActive.id },
          data: { expired_at: extendedExpiry, updated_at: now },
          include: { vip_plans: true },
        });
      } else {
        subscription = await tx.subscriptions.create({
          data: {
            user_id: req.user_id,
            plan_id: req.plan_id,
            status: "active",
            started_at: now,
            expired_at: expiredAt,
          },
          include: { vip_plans: true },
        });
      }
    }

    const payment = await tx.payments.create({
      data: {
        user_id: req.user_id,
        plan_id: req.plan_id,
        amount: req.amount,
        currency: req.currency,
        provider: req.provider,
        status: "success",
        transaction_id: transactionId,
        raw_response: {
          manualRequestId: req.id,
          transferCode: req.transfer_code,
          reviewedBy: adminId,
        },
      },
    });

    const updated = await tx.manual_payment_requests.update({
      where: { id: requestId },
      data: {
        status: "approved",
        reviewed_by: adminId,
        reviewed_at: now,
        payment_id: payment.id,
        updated_at: now,
      },
    });

    return { request: updated, payment, subscription };
  });

  return result;
}

// Reject: thu hồi trial ngay lập tức (nếu còn hạn).
export async function rejectManualRequest(requestId: string, adminId: string, reason?: string) {
  const req = await prisma.manual_payment_requests.findUnique({ where: { id: requestId } });
  if (!req) return { error: "Request not found" };
  if (req.status !== "pending") return { error: "Request is not pending" };

  const now = new Date();
  const result = await prisma.$transaction(async (tx) => {
    // Thu hồi trial ngay lập tức.
    const trialSub = await tx.subscriptions.findFirst({
      where: {
        user_id: req.user_id,
        plan_id: req.plan_id,
        status: "trial",
        expired_at: { gt: now },
      },
      orderBy: { expired_at: "desc" },
    });
    if (trialSub) {
      await tx.subscriptions.update({
        where: { id: trialSub.id },
        data: {
          status: "expired",
          cancelled_at: now,
          updated_at: now,
        },
      });
    }

    const updated = await tx.manual_payment_requests.update({
      where: { id: requestId },
      data: {
        status: "rejected",
        reviewed_by: adminId,
        reviewed_at: now,
        updated_at: now,
        note: reason ? `${req.note ?? ""}\n[Reject reason]: ${reason}`.trim() : req.note,
      },
    });
    return { request: updated };
  });

  return result;
}