"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.registerUser = registerUser;
exports.loginUser = loginUser;
exports.getMe = getMe;
const prisma_1 = require("../../config/prisma");
const password_1 = require("../../utils/password");
const jwt_1 = require("../../utils/jwt");
function toSafeUser(user) {
    return user;
}
async function registerUser(input) {
    const email = input.email.toLowerCase();
    const existingUser = await prisma_1.prisma.users.findUnique({ where: { email } });
    if (existingUser) {
        return { error: "Email already exists" };
    }
    const hashedPassword = await (0, password_1.hashPassword)(input.password);
    const user = await prisma_1.prisma.users.create({
        data: {
            full_name: input.fullName,
            email,
            password_hash: hashedPassword,
            role: "user",
            status: "active",
        },
        select: {
            id: true,
            full_name: true,
            email: true,
            avatar_url: true,
            phone: true,
            role: true,
            status: true,
            created_at: true,
            updated_at: true,
        },
    });
    const accessToken = (0, jwt_1.signAccessToken)({ userId: user.id, role: user.role });
    return { user: toSafeUser(user), accessToken };
}
async function loginUser(input) {
    const email = input.email.toLowerCase();
    const user = await prisma_1.prisma.users.findUnique({ where: { email } });
    if (!user || user.status !== "active") {
        return null;
    }
    const isPasswordValid = await (0, password_1.comparePassword)(input.password, user.password_hash);
    if (!isPasswordValid) {
        throw new Error("Invalid email or password");
    }
    const accessToken = (0, jwt_1.signAccessToken)({ userId: user.id, role: user.role });
    return { user: {
            id: user.id,
            full_name: user.full_name,
            email: user.email,
            avatar_url: user.avatar_url,
            phone: user.phone,
            role: user.role,
            status: user.status,
            created_at: user.created_at,
            updated_at: user.updated_at,
        }, accessToken };
}
//GET /api/auth/me
async function getMe(userId) {
    return prisma_1.prisma.users.findUnique({
        where: { id: userId },
        select: {
            id: true,
            full_name: true,
            email: true,
            avatar_url: true,
            phone: true,
            role: true,
            status: true,
            created_at: true,
            updated_at: true
        }
    });
}
