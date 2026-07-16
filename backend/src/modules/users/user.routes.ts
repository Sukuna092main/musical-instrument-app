import { Router } from "express";

import { avatarUpload } from "../../config/avatar-upload";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { uploadMyAvatar, getMe, updateMyProfile } from "./user.controller";

export const userRoutes = Router();

userRoutes.use(authMiddleware);

userRoutes.get("/me", getMe);
userRoutes.post("/me/avatar", avatarUpload.single("avatar"), uploadMyAvatar);
userRoutes.patch("/me", updateMyProfile);
