"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createChatMessage = createChatMessage;
exports.getChatMessages = getChatMessages;
const prisma_1 = require("../../config/prisma");
function normalizeText(value) {
    return value
        .toLowerCase()
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g, "");
}
function detectLanguage(message) {
    const hasVietnameseCharacters = /[ăâđêôơưáàảãạắằẳẵặấầẩẫậéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ]/i.test(message);
    const normalized = normalizeText(message);
    const hasVietnameseWords = /\b(toi|ban|giup|tim|nhac|bai|dang nhap|thanh toan|goi vip|nhac cu|luyen tap|bai hoc)\b/.test(normalized);
    return hasVietnameseCharacters || hasVietnameseWords ? "vi" : "en";
}
function includesAny(text, keywords) {
    return keywords.some((keyword) => text.includes(keyword));
}
function getSupportReply(language, message) {
    const text = normalizeText(message);
    if (includesAny(text, ["vip", "premium", "goi", "subscription", "subscribe"])) {
        return language === "vi"
            ? "Gói VIP mở khóa bài học, hợp âm và gam cao cấp. User Free vẫn dùng được nội dung miễn phí; khi nâng cấp VIP, app sẽ mở thêm nội dung premium."
            : "VIP unlocks premium lessons, chords and scales. Free users can still access free content; VIP users get access to premium learning materials.";
    }
    if (includesAny(text, ["payment", "pay", "thanh toan", "mua", "billing"])) {
        return language === "vi"
            ? "Thanh toán VIP sẽ được xử lý qua hệ thống thanh toán phù hợp với nền tảng phát hành. Với app mobile, gói VIP thường đi qua Apple In-App Purchase hoặc Google Play Billing."
            : "VIP payment is handled through the correct payment system for the release platform. For mobile apps, VIP packages usually use Apple In-App Purchase or Google Play Billing.";
    }
    if (includesAny(text, [
        "practice",
        "luyen tap",
        "tap luyen",
        "session",
        "timer",
        "gio tap",
    ])) {
        return language === "vi"
            ? "Bạn có thể bắt đầu buổi tập bằng cách chọn nhạc cụ và nhấn nút Start. App sẽ đếm thời gian và lưu lịch sử tập luyện của bạn."
            : "You can start a practice session by selecting an instrument and pressing Start. The app will track your time and save your practice history.";
    }
    if (includesAny(text, [
        "goal",
        "muc tieu",
        "target",
        "streak",
        "chuoi",
    ])) {
        return language === "vi"
            ? "Bạn có thể đặt mục tiêu luyện tập như 30 phút/ngày hoặc 5 ngày/tuần. App sẽ theo dõi streak (chuỗi ngày tập liên tục) để giữ động lực."
            : "You can set practice goals like 30 minutes/day or 5 days/week. The app tracks your streaks (consecutive practice days) to keep you motivated.";
    }
    if (includesAny(text, [
        "lesson",
        "bai hoc",
        "learn",
        "hoc",
        "chord",
        "hop am",
        "scale",
        "gam",
    ])) {
        return language === "vi"
            ? "App có thư viện bài học, hợp âm và gam cho từng nhạc cụ. Nội dung chia thành Free và VIP. Bạn có thể theo dõi tiến trình học của mình."
            : "The app has a library of lessons, chords and scales for each instrument. Content is divided into Free and VIP. You can track your learning progress.";
    }
    if (includesAny(text, [
        "instrument",
        "nhac cu",
        "guitar",
        "piano",
        "drum",
        "violin",
    ])) {
        return language === "vi"
            ? "App hỗ trợ nhiều nhạc cụ. Bạn có thể chọn nhạc cụ đang luyện tập, xem bài học và hợp âm riêng cho từng loại."
            : "The app supports multiple instruments. You can select the instruments you're practicing and view lessons and chords specific to each one.";
    }
    if (includesAny(text, [
        "login",
        "register",
        "dang nhap",
        "dang ky",
        "account",
        "tai khoan",
    ])) {
        return language === "vi"
            ? "Bạn có thể đăng ký hoặc đăng nhập để lưu lịch sử luyện tập, theo dõi streak và dùng các tính năng cá nhân hóa."
            : "You can register or log in to save practice history, track streaks, and use personalized features.";
    }
    if (includesAny(text, ["hello", "hi", "xin chao", "chao"])) {
        return language === "vi"
            ? "Chào bạn! Mình có thể hỗ trợ về cách dùng app, luyện tập nhạc cụ, bài học, hợp âm, gam, VIP và thanh toán."
            : "Hi! I can help with app usage, instrument practice, lessons, chords, scales, VIP, and payments.";
    }
    return language === "vi"
        ? "Mình có thể hỗ trợ các câu hỏi về luyện tập nhạc cụ, bài học, hợp âm, gam, mục tiêu, streak, VIP và thanh toán. Bạn có thể hỏi cụ thể hơn nhé."
        : "I can help with questions about instrument practice, lessons, chords, scales, goals, streaks, VIP, and payments. Please ask a more specific question.";
}
async function generateAssistantReply(_userId, message) {
    const language = detectLanguage(message);
    return getSupportReply(language, message);
}
async function createChatMessage(userId, message) {
    const assistantReply = await generateAssistantReply(userId, message);
    return prisma_1.prisma.$transaction(async (tx) => {
        const userMessage = await tx.chat_messages.create({
            data: {
                user_id: userId,
                sender: "user",
                message: message.trim(),
            },
        });
        const botMessage = await tx.chat_messages.create({
            data: {
                user_id: userId,
                sender: "bot",
                message: assistantReply,
            },
        });
        return { userMessage, botMessage };
    });
}
async function getChatMessages(userId) {
    const messages = await prisma_1.prisma.chat_messages.findMany({
        where: { user_id: userId },
        orderBy: { created_at: "desc" },
        take: 100,
    });
    return messages.reverse();
}
