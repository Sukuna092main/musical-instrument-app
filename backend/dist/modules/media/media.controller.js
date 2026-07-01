"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.removeMedia = exports.listRecentMedia = exports.saveYoutubeMedia = void 0;
const asyncHandler_1 = require("../../utils/asyncHandler");
const media_service_1 = require("./media.service");
exports.saveYoutubeMedia = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    if (!req.user) {
        return res.status(401).json({ message: 'Unauthorized' });
    }
    const { instrumentId, title, sourceUrl } = req.body;
    if (!instrumentId || !title || !sourceUrl) {
        res.status(400).json({ message: "instrumentId, title and sourceUrl are required" });
        return;
    }
    const result = await (0, media_service_1.createYoutubeMedia)({
        userId: req.user.id,
        instrumentId,
        title,
        sourceUrl
    });
    if ("error" in result) {
        return res.status(400).json({ message: result.error });
    }
    res.status(201).json(result);
});
exports.listRecentMedia = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    if (!req.user) {
        return res.status(401).json({ message: 'Unauthorized' });
    }
    const mediaItems = await (0, media_service_1.getRecentMedia)(req.user.id);
    res.status(200).json(mediaItems);
});
exports.removeMedia = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    if (!req.user) {
        return res.status(401).json({ message: 'Unauthorized' });
    }
    const result = await (0, media_service_1.deleteMedia)(req.user.id, req.params.id);
    if (result.count === 0) {
        return res.status(404).json({ message: "Media item not found" });
    }
    res.status(200).json({ message: "Media item deleted" });
});
