import { prisma } from "../../config/prisma";
import { getYoutubeVideoId } from "../../utils/youtube";

type CreateYoutubeMediaInput = {
    userId: string,
    instrumentId: string,
    title: string,
    sourceUrl: string
}

export async function createYoutubeMedia(input: CreateYoutubeMediaInput) {
    const youtubeVideoId = getYoutubeVideoId(input.sourceUrl);

    if (!youtubeVideoId) {
        return {error: "Invalid Youtube URL"};
    }

    const instrument = await prisma.instruments.findUnique({
        where: {id: input.instrumentId}
    });

    if (!instrument || instrument.status !== "active") {
        return {error: "Instrument not found!"};
    }

    const media = await prisma.media_items.create({
        data: {
            user_id: input.userId,
            instrument_id: input.instrumentId,
            type: 'youtube',
            title: input.title.trim(),
            source_url: input.sourceUrl.trim(),
            youtube_video_id: youtubeVideoId,
            file_url: null
        },
        include: {instruments: true}
    });

    return media;
}

export async function getRecentMedia(userId:string) {
    return prisma.media_items.findMany({
        where: {user_id:userId},
        include: {instruments:true},
        orderBy: {created_at:"desc"},
        take:20
    });
}

export async function deleteMedia(userId:string, mediaId:string) {
    return prisma.media_items.deleteMany({
        where:{
            id: mediaId,
            user_id: userId
        }
    });
}

