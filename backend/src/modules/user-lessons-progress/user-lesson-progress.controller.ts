import { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import {
  startLesson,
  completeLesson,
  resetLesson,
  listProgress,
} from "./user-lesson-progress.service";

// POST /api/user-lesson-progress/:lessonId/start
export const start = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const lessonId = req.params.lessonId as string;

  const result = await startLesson(userId, lessonId);
  res.status(201).json({ data: result });
});

// POST /api/user-lesson-progress/:lessonId/complete
export const complete = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const lessonId = req.params.lessonId as string;

  const result = await completeLesson(userId, lessonId);
  res.status(200).json({ data: result });
});

// POST /api/user-lesson-progress/:lessonId/reset
export const reset = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const lessonId = req.params.lessonId as string;

  const result = await resetLesson(userId, lessonId);
  res.status(200).json({ data: result });
});

// GET /api/user-lesson-progress
export const list = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;

  const result = await listProgress(userId, {
    status: req.query.status as string | undefined,
    categoryId: req.query.categoryId as string | undefined,
  });

  res.status(200).json(result);
});