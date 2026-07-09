import { Router } from "express";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { add, remove, update, list } from "./user-instrument.controller";

export const userInstrumentRoutes = Router();

userInstrumentRoutes.use(authMiddleware);

// GET    /api/user-instruments                    — danh sách nhạc cụ user đang luyện
userInstrumentRoutes.get("/", list);

// POST   /api/user-instruments                    — thêm nhạc cụ vào danh sách
userInstrumentRoutes.post("/", add);

// PUT    /api/user-instruments/:instrumentId      — cập nhật skill level / set primary
userInstrumentRoutes.put("/:instrumentId", update);

// DELETE /api/user-instruments/:instrumentId      — bỏ nhạc cụ khỏi danh sách
userInstrumentRoutes.delete("/:instrumentId", remove);