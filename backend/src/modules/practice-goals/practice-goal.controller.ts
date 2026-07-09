import { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import {
  createGoal,
  updateGoal,
  deleteGoal,
  listGoals,
  getGoalProgress,
} from "./practice-goal.service";

// POST /api/practice-goals
export const create = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const { instrumentId, goalType, targetValue } = req.body;

  if (!goalType || targetValue === undefined) {
    res
      .status(400)
      .json({ message: "goalType and targetValue are required" });
    return;
  }

  const goal = await createGoal(userId, {
    instrumentId,
    goalType,
    targetValue,
  });
  res.status(201).json({ data: goal });
});

// PUT /api/practice-goals/:id
export const update = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const goalId = req.params.id as string;
  const { goalType, targetValue, isActive } = req.body;

  const goal = await updateGoal(userId, goalId, {
    goalType,
    targetValue,
    isActive,
  });
  res.status(200).json({ data: goal });
});

// DELETE /api/practice-goals/:id
export const remove = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const goalId = req.params.id as string;

  await deleteGoal(userId, goalId);
  res.status(200).json({ message: "Goal deleted" });
});

// GET /api/practice-goals
export const list = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;

  const items = await listGoals(userId, {
    instrumentId: req.query.instrumentId as string | undefined,
    isActive:
      req.query.isActive === "true"
        ? true
        : req.query.isActive === "false"
          ? false
          : undefined,
  });

  res.status(200).json({ data: items });
});

// GET /api/practice-goals/progress
export const progress = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;

  const result = await getGoalProgress(userId);
  res.status(200).json({ data: result });
});