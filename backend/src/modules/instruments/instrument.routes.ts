import { Router } from "express";
import {
  listInstruments,
  showInstrument,
} from "./instrument.controller";

export const instrumentRoutes = Router();

// GET /api/instruments
// Lấy danh sách nhạc cụ đang active để Flutter hiển thị.
instrumentRoutes.get("/", listInstruments);

// GET /api/instruments/:id
// Lấy chi tiết một nhạc cụ theo id.
instrumentRoutes.get("/:id", showInstrument);