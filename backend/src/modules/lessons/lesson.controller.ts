import { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import {
  listCategories,
  getCategoryBySlug,
  listLessons,
  getLessonBySlug,
} from "./lesson.service";

// GET /api/lessons/categories
export const categories = asyncHandler(async (req: Request, res: Response) => {
  const items = await listCategories();
  res.status(200).json({ data: items });
});

// GET /api/lessons/categories/:slug
export const categoryDetail = asyncHandler(async (req: Request, res: Response) => {
  const slug = req.params.slug as string;
  const category = await getCategoryBySlug(slug);

  if (!category) {
    res.status(404).json({ message: "Category not found" });
    return;
  }

  res.status(200).json({ data: category });
});

// GET /api/lessons
export const list = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;

  const result = await listLessons(userId, {
    categoryId: req.query.categoryId as string | undefined,
    instrumentId: req.query.instrumentId as string | undefined,
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

// GET /api/lessons/:slug
export const detail = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const slug = req.params.slug as string;

  const lesson = await getLessonBySlug(userId, slug);

  if (!lesson) {
    res.status(404).json({ message: "Lesson not found" });
    return;
  }

  res.status(200).json({ data: lesson });
});