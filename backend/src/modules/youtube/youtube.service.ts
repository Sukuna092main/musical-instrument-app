type SearchYoutubeVideosOptions = {
  language?: string;
  regionCode?: string;
};

type YoutubeSearchItem = {
  id: {
    videoId?: string;
  };
  snippet: {
    title: string;
    description: string;
    channelTitle: string;
    thumbnails: {
      medium?: {
        url: string;
      };
      high?: {
        url: string;
      };
    };
    publishedAt: string;
  };
};

import { env } from "../../config/env";

export type YoutubeVideo = {
  videoId: string;
  title: string;
  description: string;
  channelTitle: string;
  thumbnailUrl?: string;
  publishedAt: string;
  url: string;
};

function decodeHtmlEntities(value: string) {
  return value
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">");
}

export async function searchYoutubeVideos(
  query: string,
  options: SearchYoutubeVideosOptions = {}
): Promise<YoutubeVideo[]> {
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
    key: env.youtubeApiKey,
  });

  if (options.language) {
    params.set("relevanceLanguage", options.language);
  }

  if (options.regionCode) {
    params.set("regionCode", options.regionCode);
  }

  const response = await fetch(
    `https://www.googleapis.com/youtube/v3/search?${params.toString()}`
  );

  const data = await response.json();

  if (!response.ok) {
    console.error("YouTube API error:", {
      status: response.status,
      data,
    });

    throw new Error(data.error?.message || "Failed to search YouTube videos");
  }

  return (data.items || [])
    .filter((item: YoutubeSearchItem) => Boolean(item.id.videoId))
    .map((item: YoutubeSearchItem) => ({
      videoId: item.id.videoId as string,
      title: decodeHtmlEntities(item.snippet.title),
      description: decodeHtmlEntities(item.snippet.description),
      channelTitle: decodeHtmlEntities(item.snippet.channelTitle),
      thumbnailUrl:
        item.snippet.thumbnails.high?.url || item.snippet.thumbnails.medium?.url,
      publishedAt: item.snippet.publishedAt,
      url: `https://www.youtube.com/watch?v=${item.id.videoId}`,
    }));
}
