import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import OpenAI from "openai";

const openaiApiKey = defineSecret("OPENAI_API_KEY");

const VALID_CATEGORIES = ["relationship", "love", "work", "health", "other"];

export const generateTanka = onCall(
  {
    region: "asia-northeast1",
    secrets: [openaiApiKey],
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "認証が必要です。");
    }

    const { category, worryText } = request.data;

    if (!category || typeof category !== "string" || !VALID_CATEGORIES.includes(category)) {
      throw new HttpsError(
        "invalid-argument",
        `カテゴリは ${VALID_CATEGORIES.join(", ")} のいずれかを指定してください。`
      );
    }

    if (!worryText || typeof worryText !== "string" || worryText.trim().length === 0) {
      throw new HttpsError("invalid-argument", "悩みのテキストを入力してください。");
    }

    const db = admin.firestore();
    const userRef = db.collection("users").doc(uid);

    // Check 1-per-day limit
    const today = new Date().toISOString().split("T")[0]; // "YYYY-MM-DD"
    const userDoc = await userRef.get();

    if (userDoc.exists) {
      const lastTankaDate = userDoc.data()?.lastTankaDate;
      if (lastTankaDate === today) {
        throw new HttpsError(
          "resource-exhausted",
          "短歌の作成は1日1回までです。明日また来てください。"
        );
      }
    }

    // Call OpenAI API to generate tanka
    const openai = new OpenAI({ apiKey: openaiApiKey.value() });

    const categoryLabel: Record<string, string> = {
      relationship: "人間関係",
      love: "恋愛",
      work: "仕事",
      health: "健康",
      other: "その他",
    };

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content:
            "あなたは日本の短歌の名人です。ユーザーの悩みに寄り添い、" +
            "心を癒す美しい短歌（五七五七七の31音）を一首だけ詠んでください。" +
            "短歌のテキストのみを返してください。説明や注釈は不要です。" +
            "各句の間にはスペースを入れてください（例: 五文字 七文字 五文字 七文字 七文字）。",
        },
        {
          role: "user",
          content:
            `カテゴリ: ${categoryLabel[category] || category}\n` +
            `悩み: ${worryText}\n\n` +
            "この悩みに寄り添う短歌を一首詠んでください。",
        },
      ],
      max_tokens: 200,
      temperature: 0.8,
    });

    const tankaText = completion.choices[0]?.message?.content?.trim();
    if (!tankaText) {
      throw new HttpsError("internal", "短歌の生成に失敗しました。もう一度お試しください。");
    }

    // Save to Firestore
    const now = admin.firestore.Timestamp.now();
    const tankaRef = db.collection("tanka").doc();

    const tankaData = {
      authorID: uid,
      category,
      worryText,
      tankaText,
      likeCount: 0,
      reportCount: 0,
      isHidden: false,
      createdAt: now,
    };

    await tankaRef.set(tankaData);

    // Update user's lastTankaDate (create user doc if it doesn't exist)
    await userRef.set(
      {
        lastTankaDate: today,
        createdAt: userDoc.exists ? userDoc.data()?.createdAt : now,
      },
      { merge: true }
    );

    return {
      tanka: {
        id: tankaRef.id,
        authorID: uid,
        category,
        worryText,
        tankaText,
        likeCount: 0,
        isLikedByMe: false,
        createdAt: now.toDate().toISOString(),
      },
    };
  }
);
