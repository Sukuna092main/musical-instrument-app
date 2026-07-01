import { prisma } from "../../config/prisma";
import {
  searchYoutubeVideos,
  type YoutubeVideo,
} from "../youtube/youtube.service";

type ChatLanguage = "vi" | "en";

function normalizeText(value: string) {
  return value
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");
}

function detectLanguage(message: string): ChatLanguage {
  const hasVietnameseCharacters =
    /[ăâđêôơưáàảãạắằẳẵặấầẩẫậéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ]/i.test(
      message
    );

  const normalized = normalizeText(message);
  const hasVietnameseWords =
    /\b(toi|ban|giup|tim|nhac|bai|dang nhap|thanh toan|goi vip|nhac cu)\b/.test(
      normalized
    );

  return hasVietnameseCharacters || hasVietnameseWords ? "vi" : "en";
}

function includesAny(text: string, keywords: string[]) {
  return keywords.some((keyword) => text.includes(keyword));
}

function shouldSearchYoutube(message: string) {
  const text = normalizeText(message);

  const hasSearchIntent = includesAny(text, [
    "tim",
    "find",
    "search",
    "look up",
    "play",
    "nghe",
    "listen",
  ]);

  const hasMusicIntent = includesAny(text, [
    "youtube",
    "bai hat",
    "song",
    "music",
    "track",
    "nhac",
    "cover",
    "official",
  ]);

  return hasSearchIntent && hasMusicIntent;
}

function isYoutubeHowToQuestion(message: string) {
  const text = normalizeText(message);

  return (
    text.includes("youtube") &&
    includesAny(text, ["how", "cach", "paste", "dan", "link", "player"])
  );
}

function extractYoutubeSearchQuery(message: string) {
  const quoted = message.match(/["'“”](.+?)["'“”]/);

  if (quoted?.[1]) {
    return quoted[1].trim();
  }

  return message
    .replace(/\b(tìm giúp tôi|tim giup toi|tìm cho tôi|tim cho toi)\b/gi, "")
    .replace(
      /\b(tìm|tim|find|search|look up|please|giúp tôi|giup toi|cho tôi|cho toi)\b/gi,
      ""
    )
    .replace(/\b(bài hát|bai hat|bài|bai|song|music|track|nhạc|nhac)\b/gi, "")
    .replace(/\b(trên youtube|tren youtube|on youtube|youtube|link)\b/gi, "")
    .replace(
      /\b(tôi muốn nghe|toi muon nghe|i want to listen to|i want|listen to|nghe)\b/gi,
      ""
    )
    .replace(/[?!.,]+$/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

function formatYoutubeResults(
  language: ChatLanguage,
  query: string,
  videos: YoutubeVideo[]
) {
  if (videos.length === 0) {
    return language === "vi"
      ? `Mình chưa tìm thấy kết quả YouTube phù hợp cho "${query}". Bạn thử nhập rõ hơn tên bài hát và nghệ sĩ nhé.`
      : `I could not find a suitable YouTube result for "${query}". Try using the song title together with the artist name.`;
  }

  const list = videos
    .slice(0, 5)
    .map(
      (video, index) =>
        `${index + 1}. ${video.title} - ${video.channelTitle}\n${video.url}`
    )
    .join("\n\n");

  return language === "vi"
    ? `Mình tìm thấy một vài kết quả YouTube cho "${query}":\n\n${list}\n\nLưu ý: app chỉ mở/phát link YouTube hợp lệ, không tải video từ YouTube.`
    : `I found a few YouTube results for "${query}":\n\n${list}\n\nNote: the app only opens/plays valid YouTube links and does not download YouTube videos.`;
}

function getSupportReply(language: ChatLanguage, message: string) {
  const text = normalizeText(message);

  if (isYoutubeHowToQuestion(message)) {
    return language === "vi"
      ? "Bạn có thể dán link YouTube vào màn hình Player để phát trong app. App sẽ dùng YouTube player hợp lệ và không tải video từ YouTube."
      : "You can paste a YouTube link into the Player screen. The app will play it through a valid YouTube player and will not download YouTube videos.";
  }

  if (
    includesAny(text, ["vip", "premium", "goi", "subscription", "subscribe"])
  ) {
    return language === "vi"
      ? "Gói VIP dùng để mở khóa các nhạc cụ cao cấp hơn. User Free vẫn xem và dùng được nhạc cụ miễn phí; khi nâng cấp VIP, app sẽ mở thêm các nhạc cụ premium và quyền lợi đi kèm."
      : "VIP unlocks premium instruments and extra benefits. Free users can still use free instruments; VIP users get access to premium instruments.";
  }

  if (includesAny(text, ["payment", "pay", "thanh toan", "mua", "billing"])) {
    return language === "vi"
      ? "Thanh toán VIP sẽ được xử lý qua hệ thống thanh toán phù hợp với nền tảng phát hành. Với app mobile phát hành chính thức, gói digital/VIP thường nên đi qua Apple In-App Purchase hoặc Google Play Billing."
      : "VIP payment should be handled through the correct payment system for the release platform. For official mobile app stores, digital VIP packages usually need Apple In-App Purchase or Google Play Billing.";
  }

  if (includesAny(text, ["mp4", "upload", "file", "video"])) {
    return language === "vi"
      ? "Bạn có thể chọn file MP4 từ thiết bị để phát trong Player. Khi có upload cloud, app nên lưu file ở storage riêng và chỉ lưu metadata trong database."
      : "You can choose an MP4 file from the device and play it in the Player. For cloud upload, the app should store the file in object storage and keep only metadata in the database.";
  }

  if (
    includesAny(text, [
      "instrument",
      "nhac cu",
      "guitar",
      "piano",
      "drum",
      "violin",
    ])
  ) {
    return language === "vi"
      ? "App có danh sách nhạc cụ Free và VIP. Người dùng có thể xem chi tiết nhạc cụ, nghe/thưởng thức cùng YouTube hoặc MP4, và mở khóa nhạc cụ cao cấp bằng VIP."
      : "The app has Free and VIP instruments. Users can view instrument details, enjoy music with YouTube or MP4 playback, and unlock premium instruments with VIP.";
  }

  if (
    includesAny(text, [
      "login",
      "register",
      "dang nhap",
      "dang ky",
      "account",
      "tai khoan",
    ])
  ) {
    return language === "vi"
      ? "Bạn có thể đăng ký hoặc đăng nhập để lưu lịch sử media, kiểm tra trạng thái VIP và dùng các tính năng cá nhân hóa."
      : "You can register or log in to save media history, check VIP status, and use personalized features.";
  }

  if (includesAny(text, ["hello", "hi", "xin chao", "chao"])) {
    return language === "vi"
      ? "Chào bạn! Mình có thể hỗ trợ về cách dùng app, nhạc cụ, VIP, thanh toán, YouTube link và MP4."
      : "Hi! I can help with app usage, instruments, VIP, payments, YouTube links, and MP4 playback.";
  }

  return language === "vi"
    ? "Mình có thể hỗ trợ các câu hỏi về app, nhạc cụ Free/VIP, thanh toán, YouTube link, MP4 và lịch sử nghe nhạc. Bạn có thể hỏi cụ thể hơn nhé."
    : "I can help with questions about the app, Free/VIP instruments, payments, YouTube links, MP4 playback, and music history. Please ask a more specific question.";
}

async function generateAssistantReply(_userId: string, message: string) {
  const language = detectLanguage(message);

  if (shouldSearchYoutube(message)) {
    const searchQuery = extractYoutubeSearchQuery(message) || message.trim();

    try {
      const videos = await searchYoutubeVideos(searchQuery);
      return formatYoutubeResults(language, searchQuery, videos);
    } catch (error) {
      console.error("YouTube search failed in chat:", error);

      return language === "vi"
        ? "Mình chưa tìm YouTube được lúc này. Bạn thử lại sau hoặc nhập trực tiếp link YouTube vào Player nhé."
        : "I cannot search YouTube right now. Please try again later or paste a YouTube link directly into the Player.";
    }
  }

  return getSupportReply(language, message);
}

export async function createChatMessage(userId: string, message: string) {
  const assistantReply = await generateAssistantReply(userId, message);

  return prisma.$transaction(async (tx) => {
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

export async function getChatMessages(userId: string) {
  const messages = await prisma.chat_messages.findMany({
    where: { user_id: userId },
    orderBy: { created_at: "desc" },
    take: 100,
  });

  return messages.reverse();
}
