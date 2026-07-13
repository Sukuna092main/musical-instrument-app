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