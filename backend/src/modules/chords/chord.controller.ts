import { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { getChordById, listChords } from "./chord.service";

// GET /api/chords
export const list = asyncHandler(async (req: Request, res: Response) => {
  const result = await listChords({
    instrumentId: req.query.instrumentId as string | undefined,
    category: req.query.category as string | undefined,
    difficulty: req.query.difficulty as string | undefined,
    isVip:
      req.query.isVip === "true"
        ? true
        : req.query.isVip === "false"
          ? false
          : undefined,
    page: Number(req.query.page) || undefined,
    limit: Number(req.query.limit) || undefined,
  });

  res.status(200).json(result);
});

// GET /api/chords/:id
export const detail = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const chord = await getChordById(userId, req.params.id as string);

  if (!chord) {
    res.status(404).json({ message: "Chord not found" });
    return;
  }

  res.status(200).json({ data: chord });
});