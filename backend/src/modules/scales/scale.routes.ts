import { Router } from "express";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { detail, list } from "./scale.controller";

export const scaleRoutes = Router();

scaleRoutes.use(authMiddleware);

// GET /api/scales
scaleRoutes.get("/", list);

// GET /api/scales/:id
scaleRoutes.get("/:id", detail);
