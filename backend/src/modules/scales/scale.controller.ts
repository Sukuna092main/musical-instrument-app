import { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { getScaleById, listScales } from "./scale.service";

// GET /api/scales
export const list = asyncHandler(async (req: Request, res: Response) => {
  const result = await listScales({
    instrumentId: req.query.instrumentId as string | undefined,
    scaleType: req.query.scaleType as string | undefined,
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

// GET /api/scales/:id
export const detail = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const scale = await getScaleById(userId, req.params.id as string);

  if (!scale) {
    res.status(404).json({ message: "Scale not found" });
    return;
  }

  res.status(200).json({ data: scale });
});
