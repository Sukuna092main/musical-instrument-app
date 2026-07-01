import { Request, Response } from "express";
import { getActiveInstruments, getInstrumentById } from "./instrument.service";
import { asyncHandler } from "../../utils/asyncHandler";

export const listInstruments = asyncHandler(async (req: Request, res: Response) => {
    const instruments = await getActiveInstruments();
    res.status(200).json({ data: instruments });
});

export const showInstrument = asyncHandler(async (req: Request<{ id: string }>, res: Response) => {
    const instrument = await getInstrumentById(req.params.id as string);

    if (!instrument) {
        res.status(404).json({ message: "Instrument not found" });
        return;
    }

    res.status(200).json({ data: instrument });
});