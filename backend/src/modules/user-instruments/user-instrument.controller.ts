import { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import {
  addInstrument,
  removeInstrument,
  updateUserInstrument,
  listUserInstruments,
} from "./user-instrument.service";

// POST /api/user-instruments
export const add = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const { instrumentId, skillLevel, isPrimary } = req.body;

  if (!instrumentId) {
    res.status(400).json({ message: "instrumentId is required" });
    return;
  }

  const result = await addInstrument(userId, {
    instrumentId,
    skillLevel,
    isPrimary,
  });
  res.status(201).json({ data: result });
});

// DELETE /api/user-instruments/:instrumentId
export const remove = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const instrumentId = req.params.instrumentId as string;

  await removeInstrument(userId, instrumentId);
  res.status(200).json({ message: "Instrument removed" });
});

// PUT /api/user-instruments/:instrumentId
export const update = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const instrumentId = req.params.instrumentId as string;
  const { skillLevel, isPrimary } = req.body;

  const result = await updateUserInstrument(userId, instrumentId, {
    skillLevel,
    isPrimary,
  });
  res.status(200).json({ data: result });
});

// GET /api/user-instruments
export const list = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;

  const items = await listUserInstruments(userId);
  res.status(200).json({ data: items });
});