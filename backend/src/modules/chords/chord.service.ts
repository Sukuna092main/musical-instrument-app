import { prisma } from "../../config/prisma";
import { userHasActiveVip } from "../vip/vip.service";

type ListChordsInput = {
  instrumentId?: string;
  category?: string;
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

// List active chords for app users.
export async function listChords(input: ListChordsInput) {
  const { page, limit, skip } = normalizePagination(input.page, input.limit);

  const where: any = { status: "active" };

  if (input.instrumentId) where.instrument_id = input.instrumentId;
  if (input.category) where.category = input.category;
  if (input.difficulty && allowedDifficulties.includes(input.difficulty)) {
    where.difficulty = input.difficulty;
  }
  if (input.isVip !== undefined) where.is_vip = input.isVip;

  const [items, total] = await Promise.all([
    prisma.chords.findMany({
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

// Get chord detail and hide premium fields if user is not VIP.
export async function getChordById(userId: string, chordId: string) {
  const chord = await prisma.chords.findUnique({
    where: { id: chordId },
    include: {
      instruments: {
        select: { id: true, name: true, type: true, image_url: true },
      },
    },
  });

  if (!chord || chord.status !== "active") return null;

  let canAccess = true;
  if (chord.is_vip) {
    canAccess = await userHasActiveVip(userId);
  }

  return {
    id: chord.id,
    instrumentId: chord.instrument_id,
    name: chord.name,
    symbol: chord.symbol,
    category: chord.category,
    difficulty: chord.difficulty,
    isVip: chord.is_vip,
    canAccess,
    diagramUrl: canAccess ? chord.diagram_url : null,
    audioUrl: canAccess ? chord.audio_url : null,
    description: canAccess ? chord.description : null,
    sortOrder: chord.sort_order,
    createdAt: chord.created_at,
    instrument: chord.instruments,
  };
}