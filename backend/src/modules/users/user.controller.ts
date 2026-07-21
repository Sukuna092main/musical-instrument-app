import { rm } from "node:fs/promises";
import path from "node:path";
import { Request, Response } from "express";

import { avatarDirectory } from "../../config/avatar-upload";
import { asyncHandler } from "../../utils/asyncHandler";
import { updateAvatarUrl, getCurrentUser, updateMyProfile as updateMyProfileService, changeMyPassword as changeMyPasswordService } from "./user.service";

function getLocalAvatarFilename(avatarUrl: string | null) {
  if (!avatarUrl) {
    return null;
  }

  try {
    const pathname = new URL(avatarUrl).pathname;
    const prefix = "/uploads/avatars/";

    if (!pathname.startsWith(prefix)) {
      return null;
    }

    const filename = path.basename(pathname);

    return pathname === `${prefix}${filename}` ? filename : null;
  } catch (_) {
    return null;
  }
}

async function removePreviousAvatar(avatarUrl: string | null) {
  const filename = getLocalAvatarFilename(avatarUrl);

  if (filename == null) {
    return;
  }

  try {
    await rm(path.join(avatarDirectory, filename), { force: true });
  } catch (_) {
    // Do not fail a successful avatar update just because old-file cleanup failed.
  }
}

// GET /api/users/me
// Lấy thông tin user hiện tại từ JWT.
export const getMe = asyncHandler(async (req: Request, res: Response) => {
  const user = await getCurrentUser(req.user!.id);
  res.status(200).json({ data: { user } });
});

// PATCH /api/users/me
// Cập nhật full_name / phone của user hiện tại.
export const updateMyProfile = asyncHandler(async (req: Request, res: Response) => {
  const { fullName, phone } = req.body ?? {};

  if (fullName !== undefined && typeof fullName !== "string") {
    res.status(400).json({ message: "fullName must be a string." });
    return;
  }

  if (phone !== undefined && typeof phone !== "string") {
    res.status(400).json({ message: "phone must be a string." });
    return;
  }

  const user = await updateMyProfileService(req.user!.id, { fullName, phone });
  res.status(200).json({ message: "Profile updated successfully", data: { user } });
});

// PATCH /api/users/me/password
// Đổi mật khẩu
export const changeMyPassword = asyncHandler(async (req: Request, res: Response) => {
  const { oldPassword, newPassword } = req.body ?? {};
  
  await changeMyPasswordService(req.user!.id, { oldPassword, newPassword });
  
  res.status(200).json({ message: "Password updated successfully" });
});

export const uploadMyAvatar = asyncHandler(
  async (req: Request, res: Response) => {
    const file = req.file;

    if (!file) {
      res.status(400).json({ message: "Avatar file is required." });
      return;
    }

    const requestBaseUrl = req.get("host")
      ? `${req.protocol}://${req.get("host")}`
      : "";

    const publicBaseUrl =
      process.env.PUBLIC_API_BASE_URL ?? requestBaseUrl;

    if (!publicBaseUrl) {
      await rm(file.path, { force: true });

      const error = Object.assign(
        new Error("Could not determine the public API URL."),
        { statusCode: 500 },
      );

      throw error;
    }

    const avatarUrl =
      `${publicBaseUrl.replace(/\/$/, "")}/uploads/avatars/${file.filename}`;

    try {
      const result = await updateAvatarUrl(req.user!.id, avatarUrl);

      await removePreviousAvatar(result.previousAvatarUrl);

      res.status(200).json({
        data: {
          avatarUrl: result.avatarUrl,
        },
      });
    } catch (error) {
      await rm(file.path, { force: true });
      throw error;
    }
  },
);