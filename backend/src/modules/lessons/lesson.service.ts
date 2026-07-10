import { prisma } from "../../config/prisma";
import { userHasActiveVip } from "../vip/vip.service";

// ── List Categories ──────────────────────────────

export async function listCategories() {
  return prisma.lesson_categories.findMany({
    where: { status: "active" },
    orderBy: { sort_order: "asc" },
    include: {
      _count: {
        select: { lessons: { where: { status: "active" } } },
      },
    },
  });
}

// ── Get Category by slug ─────────────────────────

export async function getCategoryBySlug(slug: string) {
  return prisma.lesson_categories.findUnique({
    where: { slug, status: "active" },
  });
}

// ── List Lessons ─────────────────────────────────

type ListLessonsInput = {
  categoryId?: string;
  instrumentId?: string;
  difficulty?: string;
  isVip?: boolean;
  page?: number;
  limit?: number;
};

const allowedDifficulties = ["beginner", "intermediate", "advanced"];

function normalizePagination(page?: number, limit?: number) {
  const p = typeof page === "number" && page > 0 ? page : 1;
  const l = typeof limit === "number" && limit > 0 && limit <= 100 ? limit : 20;
  return { page: p, limit: l, skip: (p - 1) * l };
}

export async function listLessons(userId: string, input: ListLessonsInput) {
  const { page, limit, skip } = normalizePagination(input.page, input.limit);

  const where: any = { status: "active" };

  if (input.categoryId) {
    where.category_id = input.categoryId;
  }

  if (input.instrumentId) {
    where.instrument_id = input.instrumentId;
  }

  if (input.difficulty && allowedDifficulties.includes(input.difficulty)) {
    where.difficulty = input.difficulty;
  }

  if (input.isVip !== undefined) {
    where.is_vip = input.isVip;
  }

  const [items, total] = await Promise.all([
    prisma.lessons.findMany({
      where,
      skip,
      take: limit,
      orderBy: { sort_order: "asc" },
      select: {
        id: true,
        title: true,
        slug: true,
        difficulty: true,
        is_vip: true,
        sort_order: true,
        created_at: true,
        lesson_categories: {
          select: { id: true, name: true, slug: true },
        },
        instruments: {
          select: { id: true, name: true, type: true },
        },
        // Check if user has progress on this lesson
        user_lesson_progress: {
          where: { user_id: userId },
          select: { status: true, completed_at: true },
          take: 1,
        },
      },
    }),
    prisma.lessons.count({ where }),
  ]);

  // Flatten progress
  const result = items.map((item) => ({
    ...item,
    userProgress: item.user_lesson_progress[0] || null,
    user_lesson_progress: undefined,
  }));

  return {
    items: result,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  };
}

// ── Get Lesson Detail ────────────────────────────
// VIP lessons: nếu user không phải VIP → trả metadata nhưng KHÔNG trả content

export async function getLessonBySlug(userId: string, slug: string) {
  const lesson = await prisma.lessons.findUnique({
    where: { slug },
    include: {
      lesson_categories: {
        select: { id: true, name: true, slug: true },
      },
      instruments: {
        select: { id: true, name: true, type: true, image_url: true },
      },
      user_lesson_progress: {
        where: { user_id: userId },
        select: { status: true, completed_at: true },
        take: 1,
      },
    },
  });

  if (!lesson || lesson.status !== "active") {
    return null;
  }

  // VIP check
  let canAccess = true;
  if (lesson.is_vip) {
    canAccess = await userHasActiveVip(userId);
  }

  return {
    id: lesson.id,
    title: lesson.title,
    slug: lesson.slug,
    difficulty: lesson.difficulty,
    is_vip: lesson.is_vip,
    canAccess,
    content: canAccess ? lesson.content : null, // chặn content nếu không VIP
    sort_order: lesson.sort_order,
    created_at: lesson.created_at,
    category: lesson.lesson_categories,
    instrument: lesson.instruments,
    userProgress: lesson.user_lesson_progress[0] || null,
  };
}