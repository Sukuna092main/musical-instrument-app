"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.showInstrument = exports.listInstruments = void 0;
const instrument_service_1 = require("./instrument.service");
const asyncHandler_1 = require("../../utils/asyncHandler");
exports.listInstruments = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const instruments = await (0, instrument_service_1.getActiveInstruments)();
    res.status(200).json({ data: instruments });
});
exports.showInstrument = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const instrument = await (0, instrument_service_1.getInstrumentById)(req.params.id);
    if (!instrument) {
        res.status(404).json({ message: "Instrument not found" });
        return;
    }
    res.status(200).json({ data: instrument });
});
