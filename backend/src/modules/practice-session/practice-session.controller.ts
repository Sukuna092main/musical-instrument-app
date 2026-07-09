import { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import {
  startSession,
  endSession,
  cancelSession,
  getActiveSession,
  listSessions,
  getStats,
  getStreak,
} from "./practice-session.service";

// POST /api/practice-sessions/start
export const start = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const { instrumentId } = req.body;

  if (!instrumentId) {
    res.status(400).json({ message: "instrumentId is required" });
    return;
  }

  const session = await startSession(userId, instrumentId);
  res.status(201).json({ data: session });
});

// POST /api/practice-sessions/:id/end
export const end = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const sessionId = req.params.id as string;
  const { notes, mood } = req.body;

  const session = await endSession(userId, sessionId, { note: notes, mood });
  res.status(200).json({ data: session });
});

// POST /api/practice-sessions/:id/cancel
export const cancel = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const sessionId = req.params.id as string;

  const session = await cancelSession(userId, sessionId);
  res.status(200).json({ data: session });
});

// GET /api/practice-sessions/active
export const active = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;

  const session = await getActiveSession(userId);
  res.status(200).json({ data: session });
});

// GET /api/practice-sessions
export const list = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;

  const result = await listSessions(userId, {
    page: Number(req.query.page) || undefined,
    limit: Number(req.query.limit) || undefined,
    instrumentId: req.query.instrumentId as string | undefined,
  });

  res.status(200).json(result);
});

// GET /api/practice-sessions/stats
export const stats = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const instrumentId = req.query.instrumentId as string | undefined;

  const result = await getStats(userId, instrumentId);
  res.status(200).json({ data: result });
});

// GET /api/practice-sessions/streak
export const streak = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;

  const result = await getStreak(userId);
  res.status(200).json({ data: result });
});