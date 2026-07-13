import { prisma } from "../../config/prisma";

type PaginationInput = {
  page?: number;
  limit?: number;
};

type ServiceError = {
  error: string;
  statusCode?: number;
};

type ListCategoriesInput = PaginationInput & {
  search?: string;
  status?: string;
};

type CreateCategoryInput = {
  name: string;
  slug?: string;
  description?: string | null;
  imageUrl?: string | null;
  sortOrder?: number;
  status?: string;
};

type UpdateCategoryInput = Partial<CreateCategoryInput>;

type ListLessonsInput = PaginationInput & {
  search?: string;
  status?: string;
  categoryId?: string;
  instrumentId?: string;
  difficulty?: string;
  isVip?: boolean;
};

type CreateLessonInput = {
  categoryId: string;
  instrumentId?: string | null;
  title: string;
  slug?: string;
  content: string;
  difficulty?: string;
  isVip?: boolean;
  sortOrder?: number;
  status?: string;
};

type UpdateLessonInput = Partial<CreateLessonInput>;

type ListChordsInput = PaginationInput & {
  search?: string;
  status?: string;
  instrumentId?: string;
  category?: string;
  difficulty?: string;
  isVip?: boolean;
};

type CreateChordInput = {
  instrumentId?: string | null;
  name: string;
  symbol?: string | null;
  category: string;
  diagramUrl?: string | null;
  audioUrl?: string | null;
  description?: string | null;
  difficulty?: string;
  isVip?: boolean;
  sortOrder?: number;
  status?: string;
};

type UpdateChordInput = Partial<CreateChordInput>;

type ListScalesInput = PaginationInput & {
  search?: string;
  status?: string;
  instrumentId?: string;
  scaleType?: string;
  difficulty?: string;
  isVip?: boolean;
};

type CreateScaleInput = {
  instrumentId?: string | null;
  name: string;
  key?: string | null;
  scaleType: string;
  diagramUrl?: string | null;
  audioUrl?: string | null;
  description?: string | null;
  difficulty?: string;
  isVip?: boolean;
  sortOrder?: number;
  status?: string;
};

type UpdateScaleInput = Partial<CreateScaleInput>;

const categoryStatuses = ["active", "hidden"];
const contentStatuses = ["active", "hidden", "draft"];
const difficulties = ["beginner", "intermediate", "advanced"];

// Normalize page/limit so all admin lists have consistent pagination.
function normalizePagination(page?: number, limit?: number) {
  const p = typeof page === "number" && page > 0 ? page : 1;
  const l = typeof limit === "number" && limit > 0 && limit <= 100 ? limit : 20;
  return { page: p, limit: l, skip: (p - 1) * l };
}

// Generate slug from name/title when admin does not provide a custom slug.
function toSlug(value: string) {
  return value
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/\u0111/g, "d")
    .replace(/\u0110/g, "d")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

// Validate non-negative integer for sortOrder fields.
function isPositiveOrZeroInteger(value: number) {
  return Number.isInteger(value) && value >= 0;
}

// Create validation error when value is not in the allowed list.
function invalidChoice(field: string, value: string, allowed: string[]): ServiceError | null {
  if (!allowed.includes(value)) {
    return {
      error: `Invalid ${field}. Allowed: ${allowed.join(", ")}`,
      statusCode: 400,
    };
  }

  return null;
}

// Create a consistent not-found error for the service.
function notFound(name: string): ServiceError {
  return { error: `${name} not found`, statusCode: 404 };
}

// Trim whitespace and convert empty strings to null for cleaner DB storage.
function trimOrNull(value?: string | null) {
  if (value === undefined) return undefined;
  if (value === null) return null;

  const trimmed = value.trim();
  return trimmed === "" ? null : trimmed;
}

// Ensure lesson category exists before assigning lesson to category.
async function ensureCategoryExists(categoryId: string) {
  const category = await prisma.lesson_categories.findUnique({
    where: { id: categoryId },
    select: { id: true },
  });

  return Boolean(category);
}

// Ensure instrument exists; null/undefined means instrument-agnostic content.
async function ensureInstrumentExists(instrumentId?: string | null) {
  if (!instrumentId) return true;

  const instrument = await prisma.instruments.findUnique({
    where: { id: instrumentId },
    select: { id: true },
  });

  return Boolean(instrument);
}

// Validate sortOrder for category, lesson, chord and scale.
function validateSortOrder(sortOrder?: number) {
  if (sortOrder !== undefined && !isPositiveOrZeroInteger(sortOrder)) {
    return { error: "sortOrder must be a non-negative integer", statusCode: 400 };
  }

  return null;
}

// Validate common fields of lesson/chord/scale.
function validateContentFields(input: {
  status?: string;
  difficulty?: string;
  sortOrder?: number;
}) {
  if (input.status) {
    const statusError = invalidChoice("status", input.status, contentStatuses);
    if (statusError) return statusError;
  }

  if (input.difficulty) {
    const difficultyError = invalidChoice("difficulty", input.difficulty, difficulties);
    if (difficultyError) return difficultyError;
  }

  return validateSortOrder(input.sortOrder);
}

// List lesson categories for admin with search/filter/pagination.
export async function listLessonCategoriesForAdmin(input: ListCategoriesInput) {
  const { page, limit, skip } = normalizePagination(input.page, input.limit);
  const where: any = {};

  if (input.status && categoryStatuses.includes(input.status)) {
    where.status = input.status;
  }

  if (input.search && input.search.trim() !== "") {
    const search = input.search.trim();
    where.OR = [
      { name: { contains: search, mode: "insensitive" } },
      { slug: { contains: search, mode: "insensitive" } },
    ];
  }

  const [items, total] = await Promise.all([
    prisma.lesson_categories.findMany({
      where,
      skip,
      take: limit,
      orderBy: [{ sort_order: "asc" }, { created_at: "desc" }],
      include: {
        _count: {
          select: { lessons: true },
        },
      },
    }),
    prisma.lesson_categories.count({ where }),
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

// Get lesson category detail including lesson count.
export async function getLessonCategoryForAdmin(categoryId: string) {
  return prisma.lesson_categories.findUnique({
    where: { id: categoryId },
    include: {
      _count: {
        select: { lessons: true },
      },
    },
  });
}

// Create a new lesson category for the lesson library.
export async function createLessonCategoryForAdmin(input: CreateCategoryInput) {
  if (!input.name || input.name.trim() === "") {
    return { error: "name is required", statusCode: 400 };
  }

  if (input.status) {
    const statusError = invalidChoice("status", input.status, categoryStatuses);
    if (statusError) return statusError;
  }

  const sortOrderError = validateSortOrder(input.sortOrder);
  if (sortOrderError) return sortOrderError;

  const slug = input.slug?.trim() || toSlug(input.name);
  if (!slug) {
    return { error: "slug is required", statusCode: 400 };
  }

  const category = await prisma.lesson_categories.create({
    data: {
      name: input.name.trim(),
      slug,
      description: trimOrNull(input.description),
      image_url: trimOrNull(input.imageUrl),
      sort_order: input.sortOrder ?? 0,
      status: input.status ?? "active",
      updated_at: new Date(),
    },
  });

  return { category };
}

// Update lesson category info by id.
export async function updateLessonCategoryForAdmin(
  categoryId: string,
  input: UpdateCategoryInput
) {
  const existing = await prisma.lesson_categories.findUnique({
    where: { id: categoryId },
  });

  if (!existing) return notFound("Lesson category");

  if (input.status) {
    const statusError = invalidChoice("status", input.status, categoryStatuses);
    if (statusError) return statusError;
  }

  const sortOrderError = validateSortOrder(input.sortOrder);
  if (sortOrderError) return sortOrderError;

  if (input.name !== undefined && input.name.trim() === "") {
    return { error: "name cannot be empty", statusCode: 400 };
  }

  if (input.slug !== undefined && input.slug.trim() === "") {
    return { error: "slug cannot be empty", statusCode: 400 };
  }

  const category = await prisma.lesson_categories.update({
    where: { id: categoryId },
    data: {
      ...(input.name !== undefined && { name: input.name.trim() }),
      ...(input.slug !== undefined && { slug: input.slug.trim() }),
      ...(input.description !== undefined && {
        description: trimOrNull(input.description),
      }),
      ...(input.imageUrl !== undefined && { image_url: trimOrNull(input.imageUrl) }),
      ...(input.sortOrder !== undefined && { sort_order: input.sortOrder }),
      ...(input.status !== undefined && { status: input.status }),
      updated_at: new Date(),
    },
  });

  return { category };
}

// Change lesson category status, e.g. active/hidden.
export async function updateLessonCategoryStatusForAdmin(
  categoryId: string,
  status: string
) {
  return updateLessonCategoryForAdmin(categoryId, { status });
}

// List lessons for admin with category/instrument/VIP filters.
export async function listLessonsForAdmin(input: ListLessonsInput) {
  const { page, limit, skip } = normalizePagination(input.page, input.limit);
  const where: any = {};

  if (input.status && contentStatuses.includes(input.status)) {
    where.status = input.status;
  }

  if (input.categoryId) where.category_id = input.categoryId;
  if (input.instrumentId) where.instrument_id = input.instrumentId;
  if (input.difficulty && difficulties.includes(input.difficulty)) {
    where.difficulty = input.difficulty;
  }
  if (typeof input.isVip === "boolean") where.is_vip = input.isVip;

  if (input.search && input.search.trim() !== "") {
    const search = input.search.trim();
    where.OR = [
      { title: { contains: search, mode: "insensitive" } },
      { slug: { contains: search, mode: "insensitive" } },
    ];
  }

  const [items, total] = await Promise.all([
    prisma.lessons.findMany({
      where,
      skip,
      take: limit,
      orderBy: [{ sort_order: "asc" }, { created_at: "desc" }],
      include: {
        lesson_categories: {
          select: { id: true, name: true, slug: true },
        },
        instruments: {
          select: { id: true, name: true, type: true },
        },
      },
    }),
    prisma.lessons.count({ where }),
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

// Get lesson detail for admin including category, instrument and progress count.
export async function getLessonForAdmin(lessonId: string) {
  return prisma.lessons.findUnique({
    where: { id: lessonId },
    include: {
      lesson_categories: {
        select: { id: true, name: true, slug: true },
      },
      instruments: {
        select: { id: true, name: true, type: true },
      },
      _count: {
        select: { user_lesson_progress: true },
      },
    },
  });
}

// Create a new lesson with category, instrument and content field validation.
export async function createLessonForAdmin(input: CreateLessonInput) {
  if (!input.categoryId) return { error: "categoryId is required", statusCode: 400 };
  if (!input.title || input.title.trim() === "") {
    return { error: "title is required", statusCode: 400 };
  }
  if (!input.content || input.content.trim() === "") {
    return { error: "content is required", statusCode: 400 };
  }

  const contentError = validateContentFields(input);
  if (contentError) return contentError;

  const [categoryExists, instrumentExists] = await Promise.all([
    ensureCategoryExists(input.categoryId),
    ensureInstrumentExists(input.instrumentId),
  ]);

  if (!categoryExists) return notFound("Lesson category");
  if (!instrumentExists) return notFound("Instrument");

  const slug = input.slug?.trim() || toSlug(input.title);
  if (!slug) return { error: "slug is required", statusCode: 400 };

  const lesson = await prisma.lessons.create({
    data: {
      category_id: input.categoryId,
      instrument_id: input.instrumentId || null,
      title: input.title.trim(),
      slug,
      content: input.content,
      difficulty: input.difficulty ?? "beginner",
      is_vip: input.isVip ?? false,
      sort_order: input.sortOrder ?? 0,
      status: input.status ?? "active",
      updated_at: new Date(),
    },
    include: {
      lesson_categories: {
        select: { id: true, name: true, slug: true },
      },
      instruments: {
        select: { id: true, name: true, type: true },
      },
    },
  });

  return { lesson };
}

// Update lesson by id.
export async function updateLessonForAdmin(lessonId: string, input: UpdateLessonInput) {
  const existing = await prisma.lessons.findUnique({ where: { id: lessonId } });
  if (!existing) return notFound("Lesson");

  if (input.title !== undefined && input.title.trim() === "") {
    return { error: "title cannot be empty", statusCode: 400 };
  }
  if (input.slug !== undefined && input.slug.trim() === "") {
    return { error: "slug cannot be empty", statusCode: 400 };
  }
  if (input.content !== undefined && input.content.trim() === "") {
    return { error: "content cannot be empty", statusCode: 400 };
  }

  const contentError = validateContentFields(input);
  if (contentError) return contentError;

  const [categoryExists, instrumentExists] = await Promise.all([
    input.categoryId ? ensureCategoryExists(input.categoryId) : Promise.resolve(true),
    input.instrumentId !== undefined
      ? ensureInstrumentExists(input.instrumentId)
      : Promise.resolve(true),
  ]);

  if (!categoryExists) return notFound("Lesson category");
  if (!instrumentExists) return notFound("Instrument");

  const lesson = await prisma.lessons.update({
    where: { id: lessonId },
    data: {
      ...(input.categoryId !== undefined && { category_id: input.categoryId }),
      ...(input.instrumentId !== undefined && { instrument_id: input.instrumentId || null }),
      ...(input.title !== undefined && { title: input.title.trim() }),
      ...(input.slug !== undefined && { slug: input.slug.trim() }),
      ...(input.content !== undefined && { content: input.content }),
      ...(input.difficulty !== undefined && { difficulty: input.difficulty }),
      ...(input.isVip !== undefined && { is_vip: input.isVip }),
      ...(input.sortOrder !== undefined && { sort_order: input.sortOrder }),
      ...(input.status !== undefined && { status: input.status }),
      updated_at: new Date(),
    },
    include: {
      lesson_categories: {
        select: { id: true, name: true, slug: true },
      },
      instruments: {
        select: { id: true, name: true, type: true },
      },
    },
  });

  return { lesson };
}

// Change lesson status, e.g. active/hidden/draft.
export async function updateLessonStatusForAdmin(lessonId: string, status: string) {
  return updateLessonForAdmin(lessonId, { status });
}

// List chords for admin with instrument/category/VIP filters.
export async function listChordsForAdmin(input: ListChordsInput) {
  const { page, limit, skip } = normalizePagination(input.page, input.limit);
  const where: any = {};

  if (input.status && contentStatuses.includes(input.status)) where.status = input.status;
  if (input.instrumentId) where.instrument_id = input.instrumentId;
  if (input.category) where.category = input.category;
  if (input.difficulty && difficulties.includes(input.difficulty)) {
    where.difficulty = input.difficulty;
  }
  if (typeof input.isVip === "boolean") where.is_vip = input.isVip;

  if (input.search && input.search.trim() !== "") {
    const search = input.search.trim();
    where.OR = [
      { name: { contains: search, mode: "insensitive" } },
      { symbol: { contains: search, mode: "insensitive" } },
    ];
  }

  const [items, total] = await Promise.all([
    prisma.chords.findMany({
      where,
      skip,
      take: limit,
      orderBy: [{ sort_order: "asc" }, { created_at: "desc" }],
      include: {
        instruments: {
          select: { id: true, name: true, type: true },
        },
      },
    }),
    prisma.chords.count({ where }),
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

// Get chord detail for admin.
export async function getChordForAdmin(chordId: string) {
  return prisma.chords.findUnique({
    where: { id: chordId },
    include: {
      instruments: {
        select: { id: true, name: true, type: true },
      },
    },
  });
}

// Create a new chord for the chord library.
export async function createChordForAdmin(input: CreateChordInput) {
  if (!input.name || input.name.trim() === "") {
    return { error: "name is required", statusCode: 400 };
  }
  if (!input.category || input.category.trim() === "") {
    return { error: "category is required", statusCode: 400 };
  }

  const contentError = validateContentFields(input);
  if (contentError) return contentError;

  const instrumentExists = await ensureInstrumentExists(input.instrumentId);
  if (!instrumentExists) return notFound("Instrument");

  const chord = await prisma.chords.create({
    data: {
      instrument_id: input.instrumentId || null,
      name: input.name.trim(),
      symbol: trimOrNull(input.symbol),
      category: input.category.trim(),
      diagram_url: trimOrNull(input.diagramUrl),
      audio_url: trimOrNull(input.audioUrl),
      description: trimOrNull(input.description),
      difficulty: input.difficulty ?? "beginner",
      is_vip: input.isVip ?? false,
      sort_order: input.sortOrder ?? 0,
      status: input.status ?? "active",
      updated_at: new Date(),
    },
    include: {
      instruments: {
        select: { id: true, name: true, type: true },
      },
    },
  });

  return { chord };
}

// Update chord by id.
export async function updateChordForAdmin(chordId: string, input: UpdateChordInput) {
  const existing = await prisma.chords.findUnique({ where: { id: chordId } });
  if (!existing) return notFound("Chord");

  if (input.name !== undefined && input.name.trim() === "") {
    return { error: "name cannot be empty", statusCode: 400 };
  }
  if (input.category !== undefined && input.category.trim() === "") {
    return { error: "category cannot be empty", statusCode: 400 };
  }

  const contentError = validateContentFields(input);
  if (contentError) return contentError;

  const instrumentExists =
    input.instrumentId !== undefined
      ? await ensureInstrumentExists(input.instrumentId)
      : true;
  if (!instrumentExists) return notFound("Instrument");

  const chord = await prisma.chords.update({
    where: { id: chordId },
    data: {
      ...(input.instrumentId !== undefined && { instrument_id: input.instrumentId || null }),
      ...(input.name !== undefined && { name: input.name.trim() }),
      ...(input.symbol !== undefined && { symbol: trimOrNull(input.symbol) }),
      ...(input.category !== undefined && { category: input.category.trim() }),
      ...(input.diagramUrl !== undefined && { diagram_url: trimOrNull(input.diagramUrl) }),
      ...(input.audioUrl !== undefined && { audio_url: trimOrNull(input.audioUrl) }),
      ...(input.description !== undefined && {
        description: trimOrNull(input.description),
      }),
      ...(input.difficulty !== undefined && { difficulty: input.difficulty }),
      ...(input.isVip !== undefined && { is_vip: input.isVip }),
      ...(input.sortOrder !== undefined && { sort_order: input.sortOrder }),
      ...(input.status !== undefined && { status: input.status }),
      updated_at: new Date(),
    },
    include: {
      instruments: {
        select: { id: true, name: true, type: true },
      },
    },
  });

  return { chord };
}

// Change chord status, e.g. active/hidden/draft.
export async function updateChordStatusForAdmin(chordId: string, status: string) {
  return updateChordForAdmin(chordId, { status });
}

// List scales for admin with instrument/type/VIP filters.
export async function listScalesForAdmin(input: ListScalesInput) {
  const { page, limit, skip } = normalizePagination(input.page, input.limit);
  const where: any = {};

  if (input.status && contentStatuses.includes(input.status)) where.status = input.status;
  if (input.instrumentId) where.instrument_id = input.instrumentId;
  if (input.scaleType) where.scale_type = input.scaleType;
  if (input.difficulty && difficulties.includes(input.difficulty)) {
    where.difficulty = input.difficulty;
  }
  if (typeof input.isVip === "boolean") where.is_vip = input.isVip;

  if (input.search && input.search.trim() !== "") {
    const search = input.search.trim();
    where.OR = [
      { name: { contains: search, mode: "insensitive" } },
      { key: { contains: search, mode: "insensitive" } },
      { scale_type: { contains: search, mode: "insensitive" } },
    ];
  }

  const [items, total] = await Promise.all([
    prisma.scales.findMany({
      where,
      skip,
      take: limit,
      orderBy: [{ sort_order: "asc" }, { created_at: "desc" }],
      include: {
        instruments: {
          select: { id: true, name: true, type: true },
        },
      },
    }),
    prisma.scales.count({ where }),
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

// Get scale detail for admin.
export async function getScaleForAdmin(scaleId: string) {
  return prisma.scales.findUnique({
    where: { id: scaleId },
    include: {
      instruments: {
        select: { id: true, name: true, type: true },
      },
    },
  });
}

// Create a new scale for the scale library.
export async function createScaleForAdmin(input: CreateScaleInput) {
  if (!input.name || input.name.trim() === "") {
    return { error: "name is required", statusCode: 400 };
  }
  if (!input.scaleType || input.scaleType.trim() === "") {
    return { error: "scaleType is required", statusCode: 400 };
  }

  const contentError = validateContentFields(input);
  if (contentError) return contentError;

  const instrumentExists = await ensureInstrumentExists(input.instrumentId);
  if (!instrumentExists) return notFound("Instrument");

  const scale = await prisma.scales.create({
    data: {
      instrument_id: input.instrumentId || null,
      name: input.name.trim(),
      key: trimOrNull(input.key),
      scale_type: input.scaleType.trim(),
      diagram_url: trimOrNull(input.diagramUrl),
      audio_url: trimOrNull(input.audioUrl),
      description: trimOrNull(input.description),
      difficulty: input.difficulty ?? "beginner",
      is_vip: input.isVip ?? false,
      sort_order: input.sortOrder ?? 0,
      status: input.status ?? "active",
      updated_at: new Date(),
    },
    include: {
      instruments: {
        select: { id: true, name: true, type: true },
      },
    },
  });

  return { scale };
}

// Update scale by id.
export async function updateScaleForAdmin(scaleId: string, input: UpdateScaleInput) {
  const existing = await prisma.scales.findUnique({ where: { id: scaleId } });
  if (!existing) return notFound("Scale");

  if (input.name !== undefined && input.name.trim() === "") {
    return { error: "name cannot be empty", statusCode: 400 };
  }
  if (input.scaleType !== undefined && input.scaleType.trim() === "") {
    return { error: "scaleType cannot be empty", statusCode: 400 };
  }

  const contentError = validateContentFields(input);
  if (contentError) return contentError;

  const instrumentExists =
    input.instrumentId !== undefined
      ? await ensureInstrumentExists(input.instrumentId)
      : true;
  if (!instrumentExists) return notFound("Instrument");

  const scale = await prisma.scales.update({
    where: { id: scaleId },
    data: {
      ...(input.instrumentId !== undefined && { instrument_id: input.instrumentId || null }),
      ...(input.name !== undefined && { name: input.name.trim() }),
      ...(input.key !== undefined && { key: trimOrNull(input.key) }),
      ...(input.scaleType !== undefined && { scale_type: input.scaleType.trim() }),
      ...(input.diagramUrl !== undefined && { diagram_url: trimOrNull(input.diagramUrl) }),
      ...(input.audioUrl !== undefined && { audio_url: trimOrNull(input.audioUrl) }),
      ...(input.description !== undefined && {
        description: trimOrNull(input.description),
      }),
      ...(input.difficulty !== undefined && { difficulty: input.difficulty }),
      ...(input.isVip !== undefined && { is_vip: input.isVip }),
      ...(input.sortOrder !== undefined && { sort_order: input.sortOrder }),
      ...(input.status !== undefined && { status: input.status }),
      updated_at: new Date(),
    },
    include: {
      instruments: {
        select: { id: true, name: true, type: true },
      },
    },
  });

  return { scale };
}

// Change scale status, e.g. active/hidden/draft.
export async function updateScaleStatusForAdmin(scaleId: string, status: string) {
  return updateScaleForAdmin(scaleId, { status });
}
