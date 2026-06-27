"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.listInstruments = listInstruments;
exports.showInstrument = showInstrument;
const instrument_service_1 = require("./instrument.service");
async function listInstruments(req, res) {
    const instruments = await (0, instrument_service_1.getActiveInstruments)();
    res.status(200).json({ data: instruments });
}
async function showInstrument(req, res) {
    const instrument = await (0, instrument_service_1.getInstrumentById)(req.params.id);
    if (!instrument) {
        return res.status(404).json({ message: "Instrument not found" });
    }
    res.status(200).json({ data: instrument });
}
