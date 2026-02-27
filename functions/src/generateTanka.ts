import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import OpenAI from "openai";

const openaiApiKey = defineSecret("OPENAI_API_KEY");

const VALID_CATEGORIES = ["relationship", "love", "work", "health", "other"];
const MAX_DAILY_TANKA = 1;

function validateWorryText(text: string): void {
  const trimmed = text.trim();

  if (trimmed.length === 0) {
    throw new HttpsError("invalid-argument", "悩みのテキストを入力してください。");
  }

  if (trimmed.length < 10) {
    throw new HttpsError("invalid-argument", "もう少し詳しく悩みを書いてください。");
  }

  if (trimmed.length > 300) {
    throw new HttpsError("invalid-argument", "悩みは300文字以内で入力してください。");
  }

  const charFrequency = new Map<string, number>();
  for (const char of trimmed) {
    charFrequency.set(char, (charFrequency.get(char) || 0) + 1);
  }
  const maxFrequency = Math.max(...charFrequency.values());
  if (maxFrequency / trimmed.length >= 0.7) {
    throw new HttpsError("invalid-argument", "悩みの内容を具体的に書いてください。");
  }
}

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

    if (!worryText || typeof worryText !== "string") {
      throw new HttpsError("invalid-argument", "悩みのテキストを入力してください。");
    }

    validateWorryText(worryText);

    const db = admin.firestore();
    const userRef = db.collection("users").doc(uid);

    // Check daily limit
    const now = new Date();
    const userDoc = await userRef.get();
    let isToday = false;
    let dailyCount = 0;

    if (userDoc.exists) {
      const userData = userDoc.data();
      const lastCreatedAt = userData?.lastTankaCreatedAt;

      if (lastCreatedAt && typeof lastCreatedAt.toDate === "function") {
        // New format: Firestore Timestamp
        const lastDate = lastCreatedAt.toDate();
        isToday =
          lastDate.getFullYear() === now.getFullYear() &&
          lastDate.getMonth() === now.getMonth() &&
          lastDate.getDate() === now.getDate();
      } else if (typeof userData?.lastTankaDate === "string") {
        // Legacy format: "YYYY-MM-DD" string (backward compatibility)
        const today = now.toISOString().split("T")[0];
        isToday = userData.lastTankaDate === today;
      }

      dailyCount = isToday ? (userData?.dailyTankaCount ?? 1) : 0;

      if (isToday && dailyCount >= MAX_DAILY_TANKA) {
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
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content:
            "あなたは日本の短歌の名人です。ユーザーの悩みに寄り添い、" +
            "心を癒す美しい短歌（五七五七七の31音）を一首だけ詠んでください。\n\n" +
            "以下の JSON 形式で返答してください:\n" +
            '{ "isValidInput": true, "tankaText": "五文字\\n七文字\\n五文字\\n七文字\\n七文字" }\n\n' +
            "isValidInput の判定基準:\n" +
            "- 意味のある日本語の悩み・相談であれば true\n" +
            "- 意味不明な文字列、テスト入力、悩みと無関係な内容であれば false\n\n" +
            "isValidInput が false の場合、tankaText は空文字にしてください。\n" +
            "isValidInput が true の場合、各句の間には改行（\\n）を入れてください。",
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

    const rawContent = completion.choices[0]?.message?.content?.trim();
    if (!rawContent) {
      throw new HttpsError("internal", "短歌の生成に失敗しました。もう一度お試しください。");
    }

    let parsed: { isValidInput: boolean; tankaText: string };
    try {
      parsed = JSON.parse(rawContent);
    } catch {
      // JSON パース失敗時はフォールバック（従来の文字列レスポンスとして扱う）
      parsed = { isValidInput: true, tankaText: rawContent };
    }

    if (!parsed.isValidInput) {
      throw new HttpsError("invalid-argument", "悩みの内容をもう少し具体的に書いてください。");
    }

    const tankaText = parsed.tankaText?.trim();
    if (!tankaText) {
      throw new HttpsError("internal", "短歌の生成に失敗しました。もう一度お試しください。");
    }

    // Save to Firestore
    const firestoreNow = admin.firestore.Timestamp.now();
    const tankaRef = db.collection("tanka").doc();

    const tankaData = {
      authorID: uid,
      category,
      worryText,
      tankaText,
      likeCount: 0,
      reportCount: 0,
      isHidden: false,
      createdAt: firestoreNow,
    };

    await tankaRef.set(tankaData);

    // Update user's daily tanka tracking
    await userRef.set(
      {
        lastTankaCreatedAt: firestoreNow,
        dailyTankaCount: isToday ? dailyCount + 1 : 1,
        createdAt: userDoc.exists ? userDoc.data()?.createdAt : firestoreNow,
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
        createdAt: firestoreNow.toDate().toISOString(),
      },
    };
  }
);
