"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createYoutubeMedia = createYoutubeMedia;
exports.getRecentMedia = getRecentMedia;
exports.deleteMedia = deleteMedia;
const prisma_1 = require("../../config/prisma");
const youtube_1 = require("../../utils/youtube");
async function createYoutubeMedia(input) {
    const youtubeVideoId = (0, youtube_1.getYoutubeVideoId)(input.sourceUrl);
    if (!youtubeVideoId) {
        return { error: "Invalid Youtube URL" };
    }
    const instrument = await prisma_1.prisma.instruments.findUnique({
        where: { id: input.instrumentId }
    });
    if (!instrument || instrument.status !== "active") {
        return { error: "Instrument not found!" };
    }
    const media = await prisma_1.prisma.media_items.create({
        data: {
            user_id: input.userId,
            instrument_id: input.instrumentId,
            type: 'youtube',
            title: input.title.trim(),
            source_url: input.sourceUrl.trim(),
            youtube_video_id: youtubeVideoId,
            file_url: null
        },
        include: { instruments: true }
    });
    return media;
}
async function getRecentMedia(userId) {
    return prisma_1.prisma.media_items.findMany({
        where: { user_id: userId },
        include: { instruments: true },
        orderBy: { created_at: "desc" },
        take: 20
    });
}
async function deleteMedia(userId, mediaId) {
    return prisma_1.prisma.media_items.deleteMany({
        where: {
            id: mediaId,
            user_id: userId
        }
    });
}
