import { Router } from "express";

import { avatarUpload } from "../../config/avatar-upload";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { uploadMyAvatar } from "./user.controller";

export const userRoutes = Router();

userRoutes.use(authMiddleware);

userRoutes.post("/me/avatar", avatarUpload.single("avatar"), uploadMyAvatar);
