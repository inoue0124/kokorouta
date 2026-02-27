import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

export const fetchBlockedUsers = onCall(
  { region: "asia-northeast1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "認証が必要です。");
    }

    const db = admin.firestore();

    const snapshot = await db
      .collection("users")
      .doc(uid)
      .collection("blockedUsers")
      .get();

    const blockedUsers = snapshot.docs.map((doc) => ({
      id: doc.id,
      blockedID: doc.id,
      createdAt: doc.data().createdAt.toDate().toISOString(),
    }));

    return { blockedUsers };
  }
);
