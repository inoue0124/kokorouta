import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

export const unlikeTanka = onCall(
  { region: "asia-northeast1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "認証が必要です。");
    }

    const { tankaID } = request.data;

    if (!tankaID || typeof tankaID !== "string") {
      throw new HttpsError("invalid-argument", "tankaID を指定してください。");
    }

    const db = admin.firestore();
    const tankaRef = db.collection("tanka").doc(tankaID);
    const likeRef = tankaRef.collection("likes").doc(uid);

    const newLikeCount = await db.runTransaction(async (transaction) => {
      const tankaDoc = await transaction.get(tankaRef);
      if (!tankaDoc.exists) {
        throw new HttpsError("not-found", "指定された短歌が見つかりません。");
      }

      const likeDoc = await transaction.get(likeRef);
      if (!likeDoc.exists) {
        throw new HttpsError("not-found", "いいねが見つかりません。");
      }

      const currentCount = tankaDoc.data()?.likeCount ?? 0;
      const updatedCount = Math.max(0, currentCount - 1);

      transaction.delete(likeRef);
      transaction.update(tankaRef, { likeCount: updatedCount });

      return updatedCount;
    });

    return { likeCount: newLikeCount };
  }
);
