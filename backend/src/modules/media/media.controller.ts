import { Request, Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { 
    createYoutubeMedia,
    deleteMedia,
    getRecentMedia
 } from "./media.service";

 export const saveYoutubeMedia = asyncHandler(async (req:Request, res:Response) => {
    if (!req.user) {
        return res.status(401).json({message: 'Unauthorized'});
    }

    const {instrumentId, title, sourceUrl} = req.body;

    if (!instrumentId || !title || !sourceUrl) {
        res.status(400).json({message: "instrumentId, title and sourceUrl are required"});
        return;
    }

    const result = await createYoutubeMedia({
        userId: req.user.id,
        instrumentId,
        title,
        sourceUrl
    });

    if ("error" in result) {
        return res.status(400).json({message: result.error});
    }

    res.status(201).json(result);
 });

 export const listRecentMedia = asyncHandler(async (req:Request, res:Response) => {
    if (!req.user) {
        return res.status(401).json({message: 'Unauthorized'});
    }

    const mediaItems = await getRecentMedia(req.user.id);

    res.status(200).json(mediaItems);
 });

 export const removeMedia = asyncHandler(async (req:Request, res:Response) => {
    if (!req.user) {
        return res.status(401).json({message: 'Unauthorized'});
    }

    const result = await deleteMedia(req.user.id, req.params.id as string);

    if (result.count === 0) {
        return res.status(404).json({message: "Media item not found"});
    }

    res.status(200).json({message: "Media item deleted"});
 })