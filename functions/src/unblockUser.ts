import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

export const unblockUser = onCall(
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

    const db = admin.firestore();

    await db
      .collection("users")
      .doc(uid)
      .collection("blockedUsers")
      .doc(userID)
      .delete();

    return {};
  }
);
