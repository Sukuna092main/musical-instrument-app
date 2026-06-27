"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getActiveInstruments = getActiveInstruments;
exports.getInstrumentById = getInstrumentById;
const prisma_1 = require("../../config/prisma");
async function getActiveInstruments() {
    return prisma_1.prisma.instruments.findMany({
        where: { status: "active" },
        orderBy: { created_at: "desc" },
    });
}
async function getInstrumentById(id) {
    return prisma_1.prisma.instruments.findUnique({
        where: { id },
    });
}
