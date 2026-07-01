import { Request,Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { searchYoutubeVideos } from "./youtube.service";

export const searchVideos = asyncHandler(async (req:Request,res:Response) => {
    const query = req.query.q;
    const language = typeof req.query.language === "string" ? req.query.language : undefined;
    const regionCode =
        typeof req.query.regionCode === "string" ? req.query.regionCode : undefined;

    if (!query || typeof query !== "string" || !query.trim()) {
        return res.status(400).json({message: "q is required"});
    }

    const videos = await searchYoutubeVideos(query.trim(), {
        language,
        regionCode,
    });

    res.json({ data: videos });
})
