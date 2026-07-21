"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateAvatarUrl = updateAvatarUrl;
exports.getCurrentUser = getCurrentUser;
exports.updateMyProfile = updateMyProfile;
exports.changeMyPassword = changeMyPassword;
const prisma_1 = require("../../config/prisma");
const password_1 = require("../../utils/password");
async function updateAvatarUrl(userId, avatarUrl) {
    const currentUser = await prisma_1.prisma.users.findUnique({
        where: { id: userId },
        select: { avatar_url: true },
    });
    if (!currentUser) {
        const error = Object.assign(new Error("User not found."), {
            statusCode: 404,
        });
        throw error;
    }
    const user = await prisma_1.prisma.users.update({
        where: { id: userId },
        data: {
            avatar_url: avatarUrl,
            updated_at: new Date(),
        },
        select: {
            avatar_url: true,
        },
    });
    return {
        avatarUrl: user.avatar_url,
        previousAvatarUrl: currentUser.avatar_url,
    };
}
async function getCurrentUser(userId) {
    const user = await prisma_1.prisma.users.findUnique({
        where: { id: userId },
        select: {
            id: true,
            full_name: true,
            email: true,
            avatar_url: true,
            phone: true,
            role: true,
            status: true,
        },
    });
    if (!user) {
        const error = Object.assign(new Error("User not found."), {
            statusCode: 404,
        });
        throw error;
    }
    return {
        id: user.id,
        full_name: user.full_name,
        email: user.email,
        avatar_url: user.avatar_url,
        phone: user.phone,
        role: user.role,
        status: user.status,
    };
}
async function updateMyProfile(userId, input) {
    const current = await prisma_1.prisma.users.findUnique({
        where: { id: userId },
        select: { id: true },
    });
    if (!current) {
        const error = Object.assign(new Error("User not found."), {
            statusCode: 404,
        });
        throw error;
    }
    const data = {
        updated_at: new Date(),
    };
    if (input.fullName !== undefined) {
        const trimmed = input.fullName.trim();
        if (trimmed.length === 0 || trimmed.length > 100) {
            const error = Object.assign(new Error("Full name must be 1–100 characters."), { statusCode: 400 });
            throw error;
        }
        data.full_name = trimmed;
    }
    if (input.phone !== undefined) {
        const trimmed = input.phone.trim();
        if (trimmed.length > 30) {
            const error = Object.assign(new Error("Phone must be 30 characters or fewer."), { statusCode: 400 });
            throw error;
        }
        data.phone = trimmed.length === 0 ? null : trimmed;
    }
    return prisma_1.prisma.users.update({
        where: { id: userId },
        data,
        select: {
            id: true,
            full_name: true,
            email: true,
            avatar_url: true,
            phone: true,
            role: true,
            status: true,
        },
    });
}
async function changeMyPassword(userId, input) {
    if (!input.oldPassword || !input.newPassword) {
        const error = Object.assign(new Error("Old password and new password are required."), {
            statusCode: 400,
        });
        throw error;
    }
    if (input.newPassword.length < 6) {
        const error = Object.assign(new Error("New password must be at least 6 characters long."), {
            statusCode: 400,
        });
        throw error;
    }
    const currentUser = await prisma_1.prisma.users.findUnique({
        where: { id: userId },
        select: { password_hash: true },
    });
    if (!currentUser) {
        const error = Object.assign(new Error("User not found."), {
            statusCode: 404,
        });
        throw error;
    }
    const isOldPasswordCorrect = await (0, password_1.comparePassword)(input.oldPassword, currentUser.password_hash);
    if (!isOldPasswordCorrect) {
        const error = Object.assign(new Error("Incorrect old password."), {
            statusCode: 400,
        });
        throw error;
    }
    const newPasswordHash = await (0, password_1.hashPassword)(input.newPassword);
    await prisma_1.prisma.users.update({
        where: { id: userId },
        data: {
            password_hash: newPasswordHash,
            updated_at: new Date(),
        },
    });
    return { success: true };
}
