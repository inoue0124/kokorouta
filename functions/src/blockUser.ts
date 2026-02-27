import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

export const blockUser = onCall(
  { region: "asia-northeast1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "認証が必要です。");
    }

    const { userID } = request.data;

    if (!userID || typeof userID !== "string") {
      throw new HttpsError("invalid-argument", "userID を指定してください。");
    }

    if (userID === uid) {
      throw new HttpsError("invalid-argument", "自分自身をブロックすることはできません。");
    }

    const db = admin.firestore();

    await db
      .collection("users")
      .doc(uid)
      .collection("blockedUsers")
      .doc(userID)
      .set({
        createdAt: admin.firestore.Timestamp.now(),
      });

    return {};
  }
);
