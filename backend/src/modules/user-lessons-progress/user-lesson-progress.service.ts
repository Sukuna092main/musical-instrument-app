import { prisma } from "../../config/prisma";
import { userHasActiveVip } from "../vip/vip.service";

// ── Start a lesson (mark in_progress) ────────────

export async function startLesson(userId: string, lessonId: string) {
  // Check lesson exists and is active
  const lesson = await prisma.lessons.findFirst({
    where: { id: lessonId, status: "active" },
  });

  if (!lesson) {
    throw new Error("Lesson not found.");
  }

  // VIP check
  if (lesson.is_vip) {
    const isVip = await userHasActiveVip(userId);
    if (!isVip) {
      throw new Error("This lesson requires VIP access.");
    }
  }

  // Upsert — if already exists, just return it
  return prisma.user_lesson_progress.upsert({
    where: {
      user_id_lesson_id: {
        user_id: userId,
        lesson_id: lessonId,
      },
    },
    create: {
      user_id: userId,
      lesson_id: lessonId,
      status: "in_progress",
    },
    update: {},
    include: {
      lessons: {
        select: {
          id: true,
          title: true,
          slug: true,
          difficulty: true,
          is_vip: true,
          lesson_categories: {
            select: { id: true, name: true },
          },
        },
      },
    },
  });
}

// ── Complete a lesson ────────────────────────────

export async function completeLesson(userId: string, lessonId: string) {
  const progress = await prisma.user_lesson_progress.findUnique({
    where: {
      user_id_lesson_id: {
        user_id: userId,
        lesson_id: lessonId,
      },
    },
  });

  if (!progress) {
    throw new Error("You haven't started this lesson yet.");
  }

  if (progress.status === "completed") {
    throw new Error("Lesson already completed.");
  }

  return prisma.user_lesson_progress.update({
    where: {
      user_id_lesson_id: {
        user_id: userId,
        lesson_id: lessonId,
      },
    },
    data: {
      status: "completed",
      completed_at: new Date(),
      updated_at: new Date(),
    },
    include: {
      lessons: {
        select: {
          id: true,
          title: true,
          slug: true,
          difficulty: true,
          is_vip: true,
        },
      },
    },
  });
}

// ── Reset lesson (back to in_progress) ───────────

export async function resetLesson(userId: string, lessonId: string) {
  const progress = await prisma.user_lesson_progress.findUnique({
    where: {
      user_id_lesson_id: {
        user_id: userId,
        lesson_id: lessonId,
      },
    },
  });

  if (!progress) {
    throw new Error("You haven't started this lesson yet.");
  }

  return prisma.user_lesson_progress.update({
    where: {
      user_id_lesson_id: {
        user_id: userId,
        lesson_id: lessonId,
      },
    },
    data: {
      status: "in_progress",
      completed_at: null,
      updated_at: new Date(),
    },
    include: {
      lessons: {
        select: {
          id: true,
          title: true,
          slug: true,
          difficulty: true,
          is_vip: true,
        },
      },
    },
  });
}

// ── List user progress ───────────────────────────

type ListProgressInput = {
  status?: string;
  categoryId?: string;
};

const allowedStatuses = ["in_progress", "completed"];

export async function listProgress(userId: string, input: ListProgressInput) {
  const where: any = { user_id: userId };

  if (input.status && allowedStatuses.includes(input.status)) {
    where.status = input.status;
  }

  if (input.categoryId) {
    where.lessons = { category_id: input.categoryId };
  }

  const items = await prisma.user_lesson_progress.findMany({
    where,
    orderBy: { updated_at: "desc" },
    include: {
      lessons: {
        select: {
          id: true,
          title: true,
          slug: true,
          difficulty: true,
          is_vip: true,
          lesson_categories: {
            select: { id: true, name: true, slug: true },
          },
          instruments: {
            select: { id: true, name: true, type: true },
          },
        },
      },
    },
  });

  // Summary counts
  const total = items.length;
  const completed = items.filter((i) => i.status === "completed").length;
  const inProgress = total - completed;

  return {
    items,
    summary: { total, completed, inProgress },
  };
}