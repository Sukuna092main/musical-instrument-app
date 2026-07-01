"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.me = exports.login = exports.register = void 0;
const auth_service_1 = require("./auth.service");
const asyncHandler_1 = require("../../utils/asyncHandler");
const validators_1 = require("../../utils/validators");
exports.register = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const { fullName, email, password } = req.body;
    if (!fullName || !email || !password) {
        res.status(400).json({ message: "Missing required fields" });
        return;
    }
    if (!(0, validators_1.isValidEmail)(email)) {
        return res.status(400).json({ message: "Email is invalid" });
    }
    if (password.length < 6) {
        res.status(400).json({ message: "Password must be at least 6 characters long" });
        return;
    }
    const result = await (0, auth_service_1.registerUser)({ fullName, email, password });
    if ("error" in result) {
        res.status(409).json({ message: result.error });
        return;
    }
    res.status(201).json(result);
});
exports.login = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    const { email, password } = req.body;
    if (!email || !password) {
        res.status(400).json({ message: "Missing required fields" });
        return;
    }
    if (!(0, validators_1.isValidEmail)(email)) {
        return res.status(400).json({ message: "Email is invalid" });
    }
    const result = await (0, auth_service_1.loginUser)({ email, password });
    if (!result) {
        res.status(401).json({ message: "Invalid email or password" });
        return;
    }
    res.status(200).json(result);
});
exports.me = (0, asyncHandler_1.asyncHandler)(async (req, res) => {
    if (!req.user) {
        res.status(401).json({ message: "Unauthorized" });
        return;
    }
    const user = await (0, auth_service_1.getMe)(req.user.id);
    if (!user) {
        res.status(401).json({ message: "User not found" });
        return;
    }
    res.json(user);
});
