import  dotenv  from "dotenv";

dotenv.config();

export const env = {
    port: process.env.PORT || "5000",
    databaseUrl: process.env.DATABASE_URL || "",
    jwtSecret: process.env.JWT_SECRET || "",
};

if (!env.databaseUrl) {
    throw new Error("DATABASE_URL is missing in .env");
}

if (!env.jwtSecret) {
    throw new Error("JWT_SECRET is missing in .env");
}