"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getYoutubeVideoId = getYoutubeVideoId;
function getYoutubeVideoId(input) {
    try {
        const url = new URL(input);
        if (url.hostname.includes("youtu.be")) {
            return url.pathname.replace("/", "") || null;
        }
        if (url.hostname.includes("youtube.com")) {
            const watchId = url.searchParams.get("v");
            if (watchId) {
                return watchId;
            }
            const paths = url.pathname.split("/").filter(Boolean);
            if (paths[0] === "shorts" || paths[0] === "embed") {
                return paths[1] || null;
            }
        }
        return null;
    }
    catch (error) {
        return null;
    }
}
