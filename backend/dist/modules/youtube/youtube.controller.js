"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.searchVideos = void 0;
const asyncHandler_1 = require("../../utils/asyncHandler");
const youtube_service_1 = require("./youtube.service");
exports.searchVideos = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const query = req.query.q;
    const language = typeof req.query.language === "string" ? req.query.language : undefined;
    const regionCode = typeof req.query.regionCode === "string" ? req.query.regionCode : undefined;
    if (!query || typeof query !== "string" || !query.trim()) {
        return res.status(400).json({ message: "q is required" });
    }
    const videos = await (0, youtube_service_1.searchYoutubeVideos)(query.trim(), {
        language,
        regionCode,
    });
    res.json({ data: videos });
});
