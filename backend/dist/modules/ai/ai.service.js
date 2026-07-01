"use strict";
/*
import { env } from "../../config/env";

type GenerateReplyInput = {
  systemPrompt: string;
  userMessage: string;
};

function getGroqModels() {
  return [
    "disabled-legacy-model",
    ...""
      .split(",")
      .map((model) => model.trim())
      .filter(Boolean),
  ];
}

async function disabledLegacyAiReply(input: GenerateReplyInput) {
  const models = getGroqModels();
  let lastError = "Failed to generate AI reply";

  for (const model of models) {
    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: "Bearer disabled",
      },
      body: JSON.stringify({
        model,
        messages: [
          {
            role: "system",
            content: input.systemPrompt,
          },
          {
            role: "user",
            content: input.userMessage,
          },
        ],
        temperature: 0.7,
      }),
    });

    const data = await response.json();

    if (!response.ok) {
      lastError = data.error?.message || lastError;
      console.error(`Groq API error with model ${model}:`, data);
      continue;
    }

    const text = data.choices?.[0]?.message?.content;

    if (text) {
      return text.trim();
    }
  }

  console.error("All Groq models failed:", lastError);

  return "Xin lỗi, AI đang quá tải hoặc hết giới hạn miễn phí tạm thời. Bạn thử lại sau một chút nhé.";
}
*/
Object.defineProperty(exports, "__esModule", { value: true });
