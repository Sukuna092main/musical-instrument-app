import { prisma } from "../../config/prisma";

// ── Types ────────────────────────────────────────

type AddInstrumentInput = {
  instrumentId: string;
  skillLevel?: string;
  isPrimary?: boolean;
};

type UpdateInput = {
  skillLevel?: string;
  isPrimary?: boolean;
};

const allowedSkillLevels = ["beginner", "intermediate", "advanced"];

// ── Add instrument to user ───────────────────────

export async function addInstrument(userId: string, input: AddInstrumentInput) {
  if (input.skillLevel && !allowedSkillLevels.includes(input.skillLevel)) {
    throw new Error(
      `Invalid skill level. Allowed: ${allowedSkillLevels.join(", ")}`
    );
  }

  // Check instrument exists and is active
  const instrument = await prisma.instruments.findFirst({
    where: { id: input.instrumentId, status: "active" },
  });

  if (!instrument) {
    throw new Error("Instrument not found or not active.");
  }

  // Check if already added
  const existing = await prisma.user_instruments.findUnique({
    where: {
      user_id_instrument_id: {
        user_id: userId,
        instrument_id: input.instrumentId,
      },
    },
  });

  if (existing) {
    throw new Error("You already added this instrument.");
  }

  // If setting as primary, unset other primaries
  if (input.isPrimary) {
    await prisma.user_instruments.updateMany({
      where: { user_id: userId, is_primary: true },
      data: { is_primary: false },
    });
  }

  return prisma.user_instruments.create({
    data: {
      user_id: userId,
      instrument_id: input.instrumentId,
      skill_level: input.skillLevel || "beginner",
      is_primary: input.isPrimary || false,
    },
    include: {
      instruments: {
        select: { id: true, name: true, type: true, image_url: true },
      },
    },
  });
}

// ── Remove instrument from user ──────────────────

export async function removeInstrument(userId: string, instrumentId: string) {
  const existing = await prisma.user_instruments.findUnique({
    where: {
      user_id_instrument_id: {
        user_id: userId,
        instrument_id: instrumentId,
      },
    },
  });

  if (!existing) {
    throw new Error("Instrument not in your list.");
  }

  return prisma.user_instruments.delete({
    where: {
      user_id_instrument_id: {
        user_id: userId,
        instrument_id: instrumentId,
      },
    },
  });
}

// ── Update skill level / primary ─────────────────

export async function updateUserInstrument(
  userId: string,
  instrumentId: string,
  input: UpdateInput
) {
  const existing = await prisma.user_instruments.findUnique({
    where: {
      user_id_instrument_id: {
        user_id: userId,
        instrument_id: instrumentId,
      },
    },
  });

  if (!existing) {
    throw new Error("Instrument not in your list.");
  }

  if (input.skillLevel && !allowedSkillLevels.includes(input.skillLevel)) {
    throw new Error(
      `Invalid skill level. Allowed: ${allowedSkillLevels.join(", ")}`
    );
  }

  // If setting as primary, unset other primaries first
  if (input.isPrimary) {
    await prisma.user_instruments.updateMany({
      where: { user_id: userId, is_primary: true },
      data: { is_primary: false },
    });
  }

  return prisma.user_instruments.update({
    where: {
      user_id_instrument_id: {
        user_id: userId,
        instrument_id: instrumentId,
      },
    },
    data: {
      ...(input.skillLevel !== undefined && { skill_level: input.skillLevel }),
      ...(input.isPrimary !== undefined && { is_primary: input.isPrimary }),
    },
    include: {
      instruments: {
        select: { id: true, name: true, type: true, image_url: true },
      },
    },
  });
}

// ── List user's instruments ──────────────────────

export async function listUserInstruments(userId: string) {
  return prisma.user_instruments.findMany({
    where: { user_id: userId },
    orderBy: [{ is_primary: "desc" }, { created_at: "asc" }],
    include: {
      instruments: {
        select: {
          id: true,
          name: true,
          type: true,
          image_url: true,
          description: true,
        },
      },
    },
  });
}