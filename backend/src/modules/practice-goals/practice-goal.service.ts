import { prisma } from "../../config/prisma";

// ── Types ────────────────────────────────────────

type CreateGoalInput = {
  instrumentId?: string;
  goalType: string;
  targetValue: number;
};

type UpdateGoalInput = {
  goalType?: string;
  targetValue?: number;
  isActive?: boolean;
};

const allowedGoalTypes = [
  "daily_minutes",
  "weekly_minutes",
  "weekly_days",
  "streak_days",
];

// ── Create a goal ────────────────────────────────

export async function createGoal(userId: string, input: CreateGoalInput) {
  if (!allowedGoalTypes.includes(input.goalType)) {
    throw new Error(
      `Invalid goal type. Allowed: ${allowedGoalTypes.join(", ")}`
    );
  }

  if (!Number.isInteger(input.targetValue) || input.targetValue <= 0) {
    throw new Error("targetValue must be a positive integer.");
  }

  // Prevent duplicate active goal of same type for same instrument
  const existing = await prisma.practice_goals.findFirst({
    where: {
      user_id: userId,
      instrument_id: input.instrumentId || null,
      goal_type: input.goalType,
      is_active: true,
    },
  });

  if (existing) {
    throw new Error(
      "You already have an active goal of this type for this instrument. Deactivate it first or update it."
    );
  }

  return prisma.practice_goals.create({
    data: {
      user_id: userId,
      instrument_id: input.instrumentId || null,
      goal_type: input.goalType,
      target_value: input.targetValue,
      is_active: true,
    },
    include: {
      instruments: {
        select: { id: true, name: true, type: true, image_url: true },
      },
    },
  });
}

// ── Update a goal ────────────────────────────────

export async function updateGoal(
  userId: string,
  goalId: string,
  input: UpdateGoalInput
) {
  const goal = await prisma.practice_goals.findFirst({
    where: { id: goalId, user_id: userId },
  });

  if (!goal) {
    throw new Error("Goal not found.");
  }

  if (input.goalType && !allowedGoalTypes.includes(input.goalType)) {
    throw new Error(
      `Invalid goal type. Allowed: ${allowedGoalTypes.join(", ")}`
    );
  }

  if (
    input.targetValue !== undefined &&
    (!Number.isInteger(input.targetValue) || input.targetValue <= 0)
  ) {
    throw new Error("targetValue must be a positive integer.");
  }

  return prisma.practice_goals.update({
    where: { id: goalId },
    data: {
      ...(input.goalType !== undefined && { goal_type: input.goalType }),
      ...(input.targetValue !== undefined && {
        target_value: input.targetValue,
      }),
      ...(input.isActive !== undefined && { is_active: input.isActive }),
      updated_at: new Date(),
    },
    include: {
      instruments: {
        select: { id: true, name: true, type: true, image_url: true },
      },
    },
  });
}

// ── Delete a goal ────────────────────────────────

export async function deleteGoal(userId: string, goalId: string) {
  const goal = await prisma.practice_goals.findFirst({
    where: { id: goalId, user_id: userId },
  });

  if (!goal) {
    throw new Error("Goal not found.");
  }

  return prisma.practice_goals.delete({
    where: { id: goalId },
  });
}

// ── List user goals ──────────────────────────────

type ListGoalsInput = {
  instrumentId?: string;
  isActive?: boolean;
};

export async function listGoals(userId: string, input: ListGoalsInput) {
  const where: any = { user_id: userId };

  if (input.instrumentId) {
    where.instrument_id = input.instrumentId;
  }

  if (input.isActive !== undefined) {
    where.is_active = input.isActive;
  }

  return prisma.practice_goals.findMany({
    where,
    orderBy: { created_at: "desc" },
    include: {
      instruments: {
        select: { id: true, name: true, type: true, image_url: true },
      },
    },
  });
}

// ── Get goal progress ────────────────────────────
// Tính tiến trình thực tế so với mục tiêu

export async function getGoalProgress(userId: string) {
  const activeGoals = await prisma.practice_goals.findMany({
    where: { user_id: userId, is_active: true },
    include: {
      instruments: {
        select: { id: true, name: true, type: true, image_url: true },
      },
    },
  });

  if (activeGoals.length === 0) {
    return [];
  }

  const now = new Date();
  const startOfToday = new Date(
    now.getFullYear(),
    now.getMonth(),
    now.getDate()
  );

  const startOfWeek = new Date(startOfToday);
  startOfWeek.setDate(startOfWeek.getDate() - startOfWeek.getDay() + 1); // Monday

  const results = await Promise.all(
    activeGoals.map(async (goal) => {
      const baseWhere: any = {
        user_id: userId,
        status: "completed",
      };

      if (goal.instrument_id) {
        baseWhere.instrument_id = goal.instrument_id;
      }

      let currentValue = 0;
      let period = "";

      switch (goal.goal_type) {
        case "daily_minutes": {
          const agg = await prisma.practice_sessions.aggregate({
            where: { ...baseWhere, started_at: { gte: startOfToday } },
            _sum: { duration_mins: true },
          });
          currentValue = agg._sum.duration_mins || 0;
          period = "today";
          break;
        }
        case "weekly_minutes": {
          const agg = await prisma.practice_sessions.aggregate({
            where: { ...baseWhere, started_at: { gte: startOfWeek } },
            _sum: { duration_mins: true },
          });
          currentValue = agg._sum.duration_mins || 0;
          period = "this_week";
          break;
        }
        case "weekly_days": {
          const sessions = await prisma.practice_sessions.findMany({
            where: { ...baseWhere, started_at: { gte: startOfWeek } },
            select: { started_at: true },
          });
          const uniqueDays = new Set(
            sessions.map((s) => {
              const d = s.started_at;
              return `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
            })
          );
          currentValue = uniqueDays.size;
          period = "this_week";
          break;
        }
        case "streak_days": {
          // Reuse streak logic — count consecutive days from today/yesterday
          const allSessions = await prisma.practice_sessions.findMany({
            where: { ...baseWhere },
            select: { started_at: true },
            orderBy: { started_at: "desc" },
          });

          const uniqueDates = [
            ...new Set(
              allSessions.map((s) => {
                const d = s.started_at;
                return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
              })
            ),
          ];

          const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`;
          const yesterday = new Date(now);
          yesterday.setDate(yesterday.getDate() - 1);
          const yesterdayStr = `${yesterday.getFullYear()}-${String(yesterday.getMonth() + 1).padStart(2, "0")}-${String(yesterday.getDate()).padStart(2, "0")}`;

          if (
            uniqueDates.length > 0 &&
            (uniqueDates[0] === todayStr || uniqueDates[0] === yesterdayStr)
          ) {
            let streak = 1;
            for (let i = 1; i < uniqueDates.length; i++) {
              const prev = new Date(uniqueDates[i - 1]);
              const curr = new Date(uniqueDates[i]);
              const diff = Math.round(
                (prev.getTime() - curr.getTime()) / 86400000
              );
              if (diff === 1) streak++;
              else break;
            }
            currentValue = streak;
          }
          period = "current_streak";
          break;
        }
      }

      const progress = Math.min(
        Math.round((currentValue / goal.target_value) * 100),
        100
      );

      return {
        goal: {
          id: goal.id,
          goalType: goal.goal_type,
          targetValue: goal.target_value,
          instrumentId: goal.instrument_id,
          instrument: goal.instruments,
        },
        currentValue,
        targetValue: goal.target_value,
        progress,
        completed: currentValue >= goal.target_value,
        period,
      };
    })
  );

  return results;
}