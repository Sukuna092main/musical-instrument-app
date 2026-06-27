import { Request, Response } from "express";
import { getActiveInstruments, getInstrumentById } from "./instrument.service";

export async function listInstruments(req: Request, res: Response) {
    const instruments = await getActiveInstruments();
    res.status(200).json({ data: instruments });
}

export async function showInstrument(req: Request<{ id: string }>, res: Response) {
    const instrument = await getInstrumentById(req.params.id);

    if (!instrument) {
        return res.status(404).json({ message: "Instrument not found" });
    }

    res.status(200).json({ data: instrument });
}