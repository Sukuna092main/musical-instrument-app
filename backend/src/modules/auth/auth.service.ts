import { prisma } from "../../config/prisma";
import { hashPassword, comparePassword } from "../../utils/password";
import { signAccessToken } from "../../utils/jwt";

type RegisterInput = {
    fullName: string;
    email: string;
    password: string;
};

type LoginInput = {
    email: string;
    password: string;
};

function toSafeUser(user: {
    id: string;
    full_name: string;
    email: string;
    avatar_url: string | null;
    phone: string | null;
    role: string;
    status: string;
    created_at: Date;
    updated_at: Date;
}) {
    return user;
}

export async function registerUser(input: RegisterInput) {
    const email = input.email.toLowerCase();
    const existingUser = await prisma.users.findUnique({ where: { email } });

    if (existingUser) {
        return { error: "Email already exists" };
    }

    const hashedPassword = await hashPassword(input.password);

    const user = await prisma.users.create({
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

    const accessToken = signAccessToken({ userId: user.id, role: user.role });

    return { user: toSafeUser(user), accessToken };
}

export async function loginUser(input: LoginInput) {
    const email = input.email.toLowerCase();
    const user = await prisma.users.findUnique({ where: { email } });

    if (!user || user.status !== "active") {
        return null;
    }

    const isPasswordValid = await comparePassword(input.password, user.password_hash);

    if (!isPasswordValid) {
        throw new Error("Invalid email or password");
    }

    const accessToken = signAccessToken({ userId: user.id, role: user.role });

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
export async function getMe(userId:string) {
    return prisma.users.findUnique({
        where: {id: userId},
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

