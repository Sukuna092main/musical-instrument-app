import { Router } from "express";
import {
  createAdminChord,
  createAdminLesson,
  createAdminLessonCategory,
  createAdminScale,
  listAdminChords,
  listAdminLessonCategories,
  listAdminLessons,
  listAdminScales,
  showAdminChord,
  showAdminLesson,
  showAdminLessonCategory,
  showAdminScale,
  updateAdminChord,
  updateAdminChordStatus,
  updateAdminLesson,
  updateAdminLessonCategory,
  updateAdminLessonCategoryStatus,
  updateAdminLessonStatus,
  updateAdminScale,
  updateAdminScaleStatus,
} from "./admin-content.controller";

export const adminContentRoutes = Router();

adminContentRoutes.get("/lesson-categories", listAdminLessonCategories);
adminContentRoutes.get("/lesson-categories/:id", showAdminLessonCategory);
adminContentRoutes.post("/lesson-categories", createAdminLessonCategory);
adminContentRoutes.patch("/lesson-categories/:id", updateAdminLessonCategory);
adminContentRoutes.patch(
  "/lesson-categories/:id/status",
  updateAdminLessonCategoryStatus
);

adminContentRoutes.get("/lessons", listAdminLessons);
adminContentRoutes.get("/lessons/:id", showAdminLesson);
adminContentRoutes.post("/lessons", createAdminLesson);
adminContentRoutes.patch("/lessons/:id", updateAdminLesson);
adminContentRoutes.patch("/lessons/:id/status", updateAdminLessonStatus);

adminContentRoutes.get("/chords", listAdminChords);
adminContentRoutes.get("/chords/:id", showAdminChord);
adminContentRoutes.post("/chords", createAdminChord);
adminContentRoutes.patch("/chords/:id", updateAdminChord);
adminContentRoutes.patch("/chords/:id/status", updateAdminChordStatus);

adminContentRoutes.get("/scales", listAdminScales);
adminContentRoutes.get("/scales/:id", showAdminScale);
adminContentRoutes.post("/scales", createAdminScale);
adminContentRoutes.patch("/scales/:id", updateAdminScale);
adminContentRoutes.patch("/scales/:id/status", updateAdminScaleStatus);
