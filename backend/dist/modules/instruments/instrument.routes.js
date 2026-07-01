"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.instrumentRoutes = void 0;
const express_1 = require("express");
const instrument_controller_1 = require("./instrument.controller");
exports.instrumentRoutes = (0, express_1.Router)();
// GET /api/instruments
// Lấy danh sách nhạc cụ đang active để Flutter hiển thị.
exports.instrumentRoutes.get("/", instrument_controller_1.listInstruments);
// GET /api/instruments/:id
// Lấy chi tiết một nhạc cụ theo id.
exports.instrumentRoutes.get("/:id", instrument_controller_1.showInstrument);
