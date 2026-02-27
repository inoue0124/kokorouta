import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

export const fetchMyTanka = onCall(
  { region: "asia-northeast1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "認証が必要です。");
    }

    const db = admin.firestore();

    const snapshot = await db
      .collection("tanka")
      .where("authorID", "==", uid)
      .orderBy("createdAt", "desc")
      .get();

    const tankaList = await Promise.all(
      snapshot.docs.map(async (doc) => {
        const data = doc.data();
        const likeDoc = await doc.ref.collection("likes").doc(uid).get();
        return {
          id: doc.id,
          authorID: data.authorID,
          category: data.category,
          worryText: data.worryText,
          tankaText: data.tankaText,
          likeCount: data.likeCount,
          isLikedByMe: likeDoc.exists,
          createdAt: data.createdAt.toDate().toISOString(),
        };
      })
    );

    return { tankaList };
  }
);
