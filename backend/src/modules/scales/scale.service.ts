import { prisma } from "../../config/prisma";
import { userHasActiveVip } from "../vip/vip.service";

type ListScalesInput = {
  instrumentId?: string;
  scaleType?: string;
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

// List active scales for app users.
export async function listScales(input: ListScalesInput) {
  const { page, limit, skip } = normalizePagination(input.page, input.limit);

  const where: any = { status: "active" };

  if (input.instrumentId) where.instrument_id = input.instrumentId;
  if (input.scaleType) where.scale_type = input.scaleType;
  if (input.difficulty && allowedDifficulties.includes(input.difficulty)) {
    where.difficulty = input.difficulty;
  }
  if (input.isVip !== undefined) where.is_vip = input.isVip;

  const [items, total] = await Promise.all([
    prisma.scales.findMany({
      where,
      skip,
      take: limit,
      orderBy: { sort_order: "asc" },
      include: {
        instruments: {
          select: { id: true, name: true, type: true, image_url: true },
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

// Get scale detail and hide premium fields if user is not VIP.
export async function getScaleById(userId: string, scaleId: string) {
  const scale = await prisma.scales.findUnique({
    where: { id: scaleId },
    include: {
      instruments: {
        select: { id: true, name: true, type: true, image_url: true },
      },
    },
  });

  if (!scale || scale.status !== "active") return null;

  let canAccess = true;
  if (scale.is_vip) {
    canAccess = await userHasActiveVip(userId);
  }

  return {
    id: scale.id,
    instrumentId: scale.instrument_id,
    name: scale.name,
    key: scale.key,
    scaleType: scale.scale_type,
    difficulty: scale.difficulty,
    isVip: scale.is_vip,
    canAccess,
    diagramUrl: canAccess ? scale.diagram_url : null,
    audioUrl: canAccess ? scale.audio_url : null,
    description: canAccess ? scale.description : null,
    sortOrder: scale.sort_order,
    createdAt: scale.created_at,
    instrument: scale.instruments,
  };
}
