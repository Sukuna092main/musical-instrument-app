import { prisma } from "../../config/prisma";

export async function getActiveInstruments() {
    return prisma.instruments.findMany({
        where: { status: "active" },
        orderBy: { created_at: "desc" },
    });
}

export async function getInstrumentById(id: string) {
    return prisma.instruments.findUnique({
        where: { id },
    });
}