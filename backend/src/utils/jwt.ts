import jwt from "jsonwebtoken";
import { env } from "../config/env";

type JwtPayload = {
    userId: string;
    role: string;
};

export function signAccessToken(payload: JwtPayload) {
    return jwt.sign(payload, env.jwtSecret, { expiresIn: "7d" });
}