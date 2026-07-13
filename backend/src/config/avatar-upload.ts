import { randomUUID } from "node:crypto";
import { mkdirSync } from "node:fs";
import path from "node:path";
import multer from "multer";

export const uploadsDirectory = path.resolve(process.cwd(), "uploads");
export const avatarDirectory = path.join(uploadsDirectory, "avatars");

mkdirSync(avatarDirectory, { recursive: true });

const extensionsByMimeType: Record<string, string> = {
  "image/jpeg": ".jpg",
  "image/png": ".png",
  "image/webp": ".webp",
};

const storage = multer.diskStorage({
  destination: (_req, _file, callback) => {
    callback(null, avatarDirectory);
  },
  filename: (_req, file, callback) => {
    const extension = extensionsByMimeType[file.mimetype] ?? ".bin";
    callback(null, `avatar-${Date.now()}-${randomUUID()}${extension}`);
  },
});

export const avatarUpload = multer({
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024,
    files: 1,
  },
  fileFilter: (_req, file, callback) => {
    if (!extensionsByMimeType[file.mimetype]) {
      const error = Object.assign(
        new Error("Avatar must be a JPEG, PNG, or WebP image."),
        { statusCode: 400 },
      );

      callback(error);
      return;
    }

    callback(null, true);
  },
});