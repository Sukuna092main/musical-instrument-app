"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.searchYoutubeVideos = searchYoutubeVideos;
const env_1 = require("../../config/env");
function decodeHtmlEntities(value) {
    return value
        .replace(/&amp;/g, "&")
        .replace(/&quot;/g, '"')
        .replace(/&#39;/g, "'")
        .replace(/&lt;/g, "<")
        .replace(/&gt;/g, ">");
}
async function searchYoutubeVideos(query, options = {}) {
    const cleanQuery = query.trim();
    if (!cleanQuery) {
        return [];
    }
    const params = new URLSearchParams({
        part: "snippet",
        q: cleanQuery,
        type: "video",
        maxResults: "5",
        videoEmbeddable: "true",
        videoCategoryId: "10",
        order: "relevance",
        safeSearch: "moderate",
        key: env_1.env.youtubeApiKey,
    });
    if (options.language) {
        params.set("relevanceLanguage", options.language);
    }
    if (options.regionCode) {
        params.set("regionCode", options.regionCode);
    }
    const response = await fetch(`https://www.googleapis.com/youtube/v3/search?${params.toString()}`);
    const data = await response.json();
    if (!response.ok) {
        console.error("YouTube API error:", {
            status: response.status,
            data,
        });
        throw new Error(data.error?.message || "Failed to search YouTube videos");
    }
    return (data.items || [])
        .filter((item) => Boolean(item.id.videoId))
        .map((item) => ({
        videoId: item.id.videoId,
        title: decodeHtmlEntities(item.snippet.title),
        description: decodeHtmlEntities(item.snippet.description),
        channelTitle: decodeHtmlEntities(item.snippet.channelTitle),
        thumbnailUrl: item.snippet.thumbnails.high?.url || item.snippet.thumbnails.medium?.url,
        publishedAt: item.snippet.publishedAt,
        url: `https://www.youtube.com/watch?v=${item.id.videoId}`,
    }));
}
