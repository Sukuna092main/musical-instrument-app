import { Request, Response } from "express";
import { loginUser, registerUser, getMe } from "./auth.service";
import { asyncHandler } from "../../utils/asyncHandler";
import { isValidEmail } from "../../utils/validators";

export const register = asyncHandler(async (req: Request, res: Response) => {
    const { fullName, email, password } = req.body;

    if (!fullName || !email || !password) {
        res.status(400).json({ message: "Missing required fields" });
        return;
    }

    if (!isValidEmail(email)) {
        return res.status(400).json({message: "Email is invalid"});
    }

    if (password.length < 6) {
        res.status(400).json({ message: "Password must be at least 6 characters long" });
        return;
    }

    const result = await registerUser({ fullName, email, password });

    if ("error" in result) {
        res.status(409).json({ message: result.error });
        return;
    }

    res.status(201).json(result);
});

export const login = asyncHandler(async (req: Request, res: Response) => {
    const { email, password } = req.body;

    if (!email || !password) {
        res.status(400).json({ message: "Missing required fields" });
        return;
    }

    if (!isValidEmail(email)) {
        return res.status(400).json({message: "Email is invalid"});
    }

    const result = await loginUser({ email, password });

    if (!result) {
        res.status(401).json({ message: "Invalid email or password" });
        return;
    }

    res.status(200).json(result);
});

export const me = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
        res.status(401).json({message: "Unauthorized"})
        return;
    }

    const user = await getMe(req.user.id);

    if (!user) {
        res.status(401).json({message:"User not found"})
        return;
    }

    res.json(user);
})