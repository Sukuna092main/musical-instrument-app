import { prisma } from "../../config/prisma";

export async function updateAvatarUrl(userId: string, avatarUrl: string) {
  const currentUser = await prisma.users.findUnique({
    where: { id: userId },
    select: { avatar_url: true },
  });

  if (!currentUser) {
    const error = Object.assign(new Error("User not found."), {
      statusCode: 404,
    });

    throw error;
  }

  const user = await prisma.users.update({
    where: { id: userId },
    data: {
      avatar_url: avatarUrl,
      updated_at: new Date(),
    },
    select: {
      avatar_url: true,
    },
  });

  return {
    avatarUrl: user.avatar_url!,
    previousAvatarUrl: currentUser.avatar_url,
  };
}

export async function getCurrentUser(userId: string) {
  const user = await prisma.users.findUnique({
    where: { id: userId },
    select: {
      id: true,
      full_name: true,
      email: true,
      avatar_url: true,
      phone: true,
      role: true,
      status: true,
    },
  });

  if (!user) {
    const error = Object.assign(new Error("User not found."), {
      statusCode: 404,
    });
    throw error;
  }

  return {
    id: user.id,
    full_name: user.full_name,
    email: user.email,
    avatar_url: user.avatar_url,
    phone: user.phone,
    role: user.role,
    status: user.status,
  };
}

type UpdateProfileInput = { fullName?: string; phone?: string };

export async function updateMyProfile(
  userId: string,
  input: UpdateProfileInput
) {
  const current = await prisma.users.findUnique({
    where: { id: userId },
    select: { id: true },
  });

  if (!current) {
    const error = Object.assign(new Error("User not found."), {
      statusCode: 404,
    });
    throw error;
  }

  const data: {
    full_name?: string;
    phone?: string | null;
    updated_at: Date;
  } = {
    updated_at: new Date(),
  };

  if (input.fullName !== undefined) {
    const trimmed = input.fullName.trim();
    if (trimmed.length === 0 || trimmed.length > 100) {
      const error = Object.assign(
        new Error("Full name must be 1–100 characters."),
        { statusCode: 400 }
      );
      throw error;
    }
    data.full_name = trimmed;
  }

  if (input.phone !== undefined) {
    const trimmed = input.phone.trim();
    if (trimmed.length > 30) {
      const error = Object.assign(
        new Error("Phone must be 30 characters or fewer."),
        { statusCode: 400 }
      );
      throw error;
    }
    data.phone = trimmed.length === 0 ? null : trimmed;
  }

  return prisma.users.update({
    where: { id: userId },
    data,
    select: {
      id: true,
      full_name: true,
      email: true,
      avatar_url: true,
      phone: true,
      role: true,
      status: true,
    },
  });
}