import { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import {
  createChordForAdmin,
  createLessonCategoryForAdmin,
  createLessonForAdmin,
  createScaleForAdmin,
  getChordForAdmin,
  getLessonCategoryForAdmin,
  getLessonForAdmin,
  getScaleForAdmin,
  listChordsForAdmin,
  listLessonCategoriesForAdmin,
  listLessonsForAdmin,
  listScalesForAdmin,
  updateChordForAdmin,
  updateChordStatusForAdmin,
  updateLessonCategoryForAdmin,
  updateLessonCategoryStatusForAdmin,
  updateLessonForAdmin,
  updateLessonStatusForAdmin,
  updateScaleForAdmin,
  updateScaleStatusForAdmin,
} from "./admin-content.service";

type ResultError = {
  error: string;
  statusCode?: number;
};

// Parse query string "true"/"false" to boolean for isVip filter.
function parseBoolean(value: unknown) {
  return value === "true" ? true : value === "false" ? false : undefined;
}

// Extract page/limit from query and let service normalize values.
function pagination(req: Request) {
  return {
    page: Number(req.query.page || 1),
    limit: Number(req.query.limit || 20),
  };
}

// Send service error response to client with appropriate status code.
function sendError(res: Response, result: ResultError) {
  res.status(result.statusCode || 400).json({ message: result.error });
}

// Validate required body.status for status-changing endpoints.
function getRequiredStatus(req: Request, res: Response) {
  const status = req.body.status;

  if (!status || typeof status !== "string") {
    res.status(400).json({ message: "status is required" });
    return null;
  }

  return status;
}

// Distinguish successful service result from error object.
function hasError(result: unknown): result is ResultError {
  return Boolean(result && typeof result === "object" && "error" in result);
}

// GET /api/admin/lesson-categories
export const listAdminLessonCategories = asyncHandler(
  async (req: Request, res: Response) => {
    const result = await listLessonCategoriesForAdmin({
      ...pagination(req),
      search: req.query.search as string | undefined,
      status: req.query.status as string | undefined,
    });

    res.json({ data: result });
  }
);

// GET /api/admin/lesson-categories/:id
export const showAdminLessonCategory = asyncHandler(
  async (req: Request, res: Response) => {
    const category = await getLessonCategoryForAdmin(req.params.id as string);

    if (!category) {
      res.status(404).json({ message: "Lesson category not found" });
      return;
    }

    res.json({ data: category });
  }
);

// POST /api/admin/lesson-categories
export const createAdminLessonCategory = asyncHandler(
  async (req: Request, res: Response) => {
    const result = await createLessonCategoryForAdmin(req.body);

    if (hasError(result)) {
      sendError(res, result);
      return;
    }

    res.status(201).json({ data: result.category });
  }
);

// PATCH /api/admin/lesson-categories/:id
export const updateAdminLessonCategory = asyncHandler(
  async (req: Request, res: Response) => {
    const result = await updateLessonCategoryForAdmin(
      req.params.id as string,
      req.body
    );

    if (hasError(result)) {
      sendError(res, result);
      return;
    }

    res.json({ data: result.category });
  }
);

// PATCH /api/admin/lesson-categories/:id/status
export const updateAdminLessonCategoryStatus = asyncHandler(
  async (req: Request, res: Response) => {
    const status = getRequiredStatus(req, res);
    if (!status) return;

    const result = await updateLessonCategoryStatusForAdmin(
      req.params.id as string,
      status
    );

    if (hasError(result)) {
      sendError(res, result);
      return;
    }

    res.json({ data: result.category });
  }
);

// GET /api/admin/lessons
export const listAdminLessons = asyncHandler(
  async (req: Request, res: Response) => {
    const result = await listLessonsForAdmin({
      ...pagination(req),
      search: req.query.search as string | undefined,
      status: req.query.status as string | undefined,
      categoryId: req.query.categoryId as string | undefined,
      instrumentId: req.query.instrumentId as string | undefined,
      difficulty: req.query.difficulty as string | undefined,
      isVip: parseBoolean(req.query.isVip),
    });

    res.json({ data: result });
  }
);

// GET /api/admin/lessons/:id
export const showAdminLesson = asyncHandler(
  async (req: Request, res: Response) => {
    const lesson = await getLessonForAdmin(req.params.id as string);

    if (!lesson) {
      res.status(404).json({ message: "Lesson not found" });
      return;
    }

    res.json({ data: lesson });
  }
);

// POST /api/admin/lessons
export const createAdminLesson = asyncHandler(
  async (req: Request, res: Response) => {
    const result = await createLessonForAdmin(req.body);

    if (hasError(result)) {
      sendError(res, result);
      return;
    }

    res.status(201).json({ data: result.lesson });
  }
);

// PATCH /api/admin/lessons/:id
export const updateAdminLesson = asyncHandler(
  async (req: Request, res: Response) => {
    const result = await updateLessonForAdmin(req.params.id as string, req.body);

    if (hasError(result)) {
      sendError(res, result);
      return;
    }

    res.json({ data: result.lesson });
  }
);

// PATCH /api/admin/lessons/:id/status
export const updateAdminLessonStatus = asyncHandler(
  async (req: Request, res: Response) => {
    const status = getRequiredStatus(req, res);
    if (!status) return;

    const result = await updateLessonStatusForAdmin(
      req.params.id as string,
      status
    );

    if (hasError(result)) {
      sendError(res, result);
      return;
    }

    res.json({ data: result.lesson });
  }
);

// GET /api/admin/chords
export const listAdminChords = asyncHandler(
  async (req: Request, res: Response) => {
    const result = await listChordsForAdmin({
      ...pagination(req),
      search: req.query.search as string | undefined,
      status: req.query.status as string | undefined,
      instrumentId: req.query.instrumentId as string | undefined,
      category: req.query.category as string | undefined,
      difficulty: req.query.difficulty as string | undefined,
      isVip: parseBoolean(req.query.isVip),
    });

    res.json({ data: result });
  }
);

// GET /api/admin/chords/:id
export const showAdminChord = asyncHandler(
  async (req: Request, res: Response) => {
    const chord = await getChordForAdmin(req.params.id as string);

    if (!chord) {
      res.status(404).json({ message: "Chord not found" });
      return;
    }

    res.json({ data: chord });
  }
);

// POST /api/admin/chords
export const createAdminChord = asyncHandler(
  async (req: Request, res: Response) => {
    const result = await createChordForAdmin(req.body);

    if (hasError(result)) {
      sendError(res, result);
      return;
    }

    res.status(201).json({ data: result.chord });
  }
);

// PATCH /api/admin/chords/:id
export const updateAdminChord = asyncHandler(
  async (req: Request, res: Response) => {
    const result = await updateChordForAdmin(req.params.id as string, req.body);

    if (hasError(result)) {
      sendError(res, result);
      return;
    }

    res.json({ data: result.chord });
  }
);

// PATCH /api/admin/chords/:id/status
export const updateAdminChordStatus = asyncHandler(
  async (req: Request, res: Response) => {
    const status = getRequiredStatus(req, res);
    if (!status) return;

    const result = await updateChordStatusForAdmin(
      req.params.id as string,
      status
    );

    if (hasError(result)) {
      sendError(res, result);
      return;
    }

    res.json({ data: result.chord });
  }
);

// GET /api/admin/scales
export const listAdminScales = asyncHandler(
  async (req: Request, res: Response) => {
    const result = await listScalesForAdmin({
      ...pagination(req),
      search: req.query.search as string | undefined,
      status: req.query.status as string | undefined,
      instrumentId: req.query.instrumentId as string | undefined,
      scaleType: req.query.scaleType as string | undefined,
      difficulty: req.query.difficulty as string | undefined,
      isVip: parseBoolean(req.query.isVip),
    });

    res.json({ data: result });
  }
);

// GET /api/admin/scales/:id
export const showAdminScale = asyncHandler(
  async (req: Request, res: Response) => {
    const scale = await getScaleForAdmin(req.params.id as string);

    if (!scale) {
      res.status(404).json({ message: "Scale not found" });
      return;
    }

    res.json({ data: scale });
  }
);

// POST /api/admin/scales
export const createAdminScale = asyncHandler(
  async (req: Request, res: Response) => {
    const result = await createScaleForAdmin(req.body);

    if (hasError(result)) {
      sendError(res, result);
      return;
    }

    res.status(201).json({ data: result.scale });
  }
);

// PATCH /api/admin/scales/:id
export const updateAdminScale = asyncHandler(
  async (req: Request, res: Response) => {
    const result = await updateScaleForAdmin(req.params.id as string, req.body);

    if (hasError(result)) {
      sendError(res, result);
      return;
    }

    res.json({ data: result.scale });
  }
);

// PATCH /api/admin/scales/:id/status
export const updateAdminScaleStatus = asyncHandler(
  async (req: Request, res: Response) => {
    const status = getRequiredStatus(req, res);
    if (!status) return;

    const result = await updateScaleStatusForAdmin(
      req.params.id as string,
      status
    );

    if (hasError(result)) {
      sendError(res, result);
      return;
    }

    res.json({ data: result.scale });
  }
);
