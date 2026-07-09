import { prisma } from "../../config/prisma";

// Start a new practice session
export async function startSession(userId: string, instrumentId: string) {
    // Check if the user has an active session
    const activeSession = await prisma.practice_sessions.findFirst({
        where: {user_id: userId, status: "active"}
    });

    if (activeSession) {
        throw new Error("You already have an active session. End it before starting a new one.");
    }

    return prisma.practice_sessions.create({
        data: {
            user_id: userId,
            instrument_id: instrumentId,
            status: "active",
            started_at: new Date(),
        },
        include: {
            instruments: {
                select: {id: true, name: true, type: true, image_url: true},
            },
        }
    });
}

// End a practice session
type EndSessionInput = {
    note?: string;
    mood?: string;
};

const allowedMoods = ["great", "good", "okay", "bad"];

export async function endSession(userId: string, sessionId: string, input: EndSessionInput) {
    const session = await prisma.practice_sessions.findFirst({
        where: {id: sessionId, user_id: userId, status: "active"}
    });

    if (!session) {
        throw new Error("Session not found or not active.");
    }

    if (input.mood && !allowedMoods.includes(input.mood)) {
        throw new Error(`Invalid mood. Allowed: ${allowedMoods.join(", ")}`);
    }

    const now = new Date();
    const durationMins = Math.round(
        (now.getTime() - session.started_at.getTime()) / (1000 * 60)
    );

    return prisma.practice_sessions.update({
        where: {id: sessionId},
        data: {
            status: "completed",
            ended_at: now,
            duration_mins: durationMins,
            notes: input.note?.trim() || null,
            mood: input.mood || null,
        },
        include: {
            instruments: {
                select: {id: true, name: true, type: true, image_url: true},
            },
        }
    });
}

// Cancel a practice session
export async function cancelSession(userId: string, sessionId: string) {
    const session = await prisma.practice_sessions.findFirst({
        where: {id: sessionId, user_id: userId, status: "active"}
    });

    if (!session) {
        throw new Error("Active session not found.");
    }

    return prisma.practice_sessions.update({
        where: {id: sessionId},
        data: {
            status: "cancelled",
            ended_at: new Date(),
            updated_at: new Date(),
        }
    });
}

// Get active session for a user
export async function getActiveSession(userId: string) {
    return prisma.practice_sessions.findFirst({
        where: {user_id: userId, status: "active"},
        include: {
            instruments: {
                select: {id: true, name: true, type: true, image_url: true},
            },
        }
    });
}

// List history for a user
type ListSessionInput = {
    page?: number;
    limit?: number;
    instrumentId?: string;
};

function normalizePagination(page?: number, limit?: number) {
    const p = typeof page === "number" && page > 0 ? page : 1;
    const l = typeof limit === "number" && limit > 0 && limit <= 100 ? limit : 20;
    return { page: p, limit: l, skip: (p - 1) * l };
}

export async function listSessions(userId: string, input: ListSessionInput) {
    const { page, limit, skip } = normalizePagination(input.page, input.limit);

    const where: any = {
        user_id: userId,
        status: "completed",
    }

    if (input.instrumentId) {
        where.instrument_id = input.instrumentId;
    }
    const [items, total] = await Promise.all([
        prisma.practice_sessions.findMany({
          where,
          skip,
          take: limit,
          orderBy: { started_at: "desc" },
          include: {
            instruments: {
              select: { id: true, name: true, type: true, image_url: true },
            },
          },
        }),
        prisma.practice_sessions.count({ where }),
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

// Stats: daily, weekly, monthly totals
export async function getStats(userId: string, instrumentId?: string) {
    const now = new Date();

    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    const startOfWeek = new Date(startOfToday);
    startOfWeek.setDate(startOfWeek.getDate() - startOfWeek.getDay() + 1); // Monday

    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const baseWhere: any = {
      user_id: userId,
      status: "completed",
    };

    if (instrumentId) {
      baseWhere.instrument_id = instrumentId;
    }

    const [todayAgg, weekAgg, monthAgg, totalSessions] = await Promise.all([
      prisma.practice_sessions.aggregate({
        where: { ...baseWhere, started_at: { gte: startOfToday } },
        _sum: { duration_mins: true },
        _count: true,
      }),
      prisma.practice_sessions.aggregate({
        where: { ...baseWhere, started_at: { gte: startOfWeek } },
        _sum: { duration_mins: true },
        _count: true,
      }),
      prisma.practice_sessions.aggregate({
        where: { ...baseWhere, started_at: { gte: startOfMonth } },
        _sum: { duration_mins: true },
        _count: true,
      }),
      prisma.practice_sessions.count({ where: baseWhere }),
    ]);

    return {
      today: {
        totalMins: todayAgg._sum.duration_mins || 0,
        sessions: todayAgg._count,
      },
      thisWeek: {
        totalMins: weekAgg._sum.duration_mins || 0,
        sessions: weekAgg._count,
      },
      thisMonth: {
        totalMins: monthAgg._sum.duration_mins || 0,
        sessions: monthAgg._count,
      },
      allTime: {
        sessions: totalSessions,
      },
    };
}

// ── Streak ────────────────────────────────────────
export async function getStreak(userId: string) {
    // Get all distinct practice dates (completed), ordered desc
    const sessions = await prisma.practice_sessions.findMany({
      where: { user_id: userId, status: "completed" },
      select: { started_at: true },
      orderBy: { started_at: "desc" },
    });

    if (sessions.length === 0) {
      return { currentStreak: 0, longestStreak: 0 };
    }

    // Extract unique dates (YYYY-MM-DD)
    const uniqueDates = [
      ...new Set(
        sessions.map((s) => {
          const d = s.started_at;
          return `${d.getFullYear()}-${String(d.getMonth() + 1)
            .padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
        })
      ),
    ];

    // Calculate current streak
    const today = new Date();
    const todayStr = `${today.getFullYear()}-${String(today.getMonth() + 1)
        .padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`;
    
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = `${yesterday.getFullYear()}-${String(yesterday.getMonth() + 1)
        .padStart(2, "0")}-${String(yesterday.getDate()).padStart(2, "0")}`;

    // Streak only counts if user practiced today or yesterday
    if (uniqueDates[0] !== todayStr && uniqueDates[0] !== yesterdayStr) {
      return { currentStreak: 0, longestStreak: calcLongestStreak(uniqueDates) };
    }

    let currentStreak = 1;

    for (let i = 1; i < uniqueDates.length; i++) {
      const prev = new Date(uniqueDates[i - 1]);
      const curr = new Date(uniqueDates[i]);
      const diffDays = Math.round((prev.getTime() - curr.getTime()) / 86400000);

      if (diffDays === 1) {
        currentStreak++;
      } else {
        break;
      }
    }

    return {
      currentStreak,
      longestStreak: calcLongestStreak(uniqueDates),
    };
}

function calcLongestStreak(sortedDatesDesc: string[]) {
    if (sortedDatesDesc.length === 0) return 0;

    let longest = 1;
    let current = 1;

    for (let i = 1; i < sortedDatesDesc.length; i++) {
      const prev = new Date(sortedDatesDesc[i - 1]);
      const curr = new Date(sortedDatesDesc[i]);
      const diffDays = Math.round((prev.getTime() - curr.getTime()) / 86400000);

      if (diffDays === 1) {
        current++;
        longest = Math.max(longest, current);
      } else {
        current = 1;
      }
    }

    return longest;
}