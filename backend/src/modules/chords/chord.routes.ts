import { Router } from "express";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { detail, list } from "./chord.controller";

export const chordRoutes = Router();

chordRoutes.use(authMiddleware);

// GET /api/chords
chordRoutes.get("/", list);

// GET /api/chords/:id
chordRoutes.get("/:id", detail);