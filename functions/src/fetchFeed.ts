import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

export const fetchFeed = onCall(
  { region: "asia-northeast1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "認証が必要です。");
    }

    const { limit, afterID } = request.data;

    if (!limit || typeof limit !== "number" || limit < 1 || limit > 100) {
      throw new HttpsError("invalid-argument", "limit は 1〜100 の数値を指定してください。");
    }

    const db = admin.firestore();

    // Fetch blocked user IDs
    const blockedSnapshot = await db
      .collection("users")
      .doc(uid)
      .collection("blockedUsers")
      .get();
    const blockedUserIDs = new Set(blockedSnapshot.docs.map((doc) => doc.id));

    // Build query
    let query = db
      .collection("tanka")
      .where("isHidden", "==", false)
      .orderBy("createdAt", "desc");

    // Cursor-based pagination
    if (afterID) {
      const cursorDoc = await db.collection("tanka").doc(afterID).get();
      if (!cursorDoc.exists) {
        throw new HttpsError("not-found", "指定されたカーソルの短歌が見つかりません。");
      }
      query = query.startAfter(cursorDoc);
    }

    // Fetch one extra to determine hasMore
    const snapshot = await query.limit(limit + 1).get();

    // Filter out blocked users' tankas
    const filteredDocs = snapshot.docs.filter(
      (doc) => !blockedUserIDs.has(doc.data().authorID)
    );

    const hasMore = filteredDocs.length > limit;
    const resultDocs = hasMore ? filteredDocs.slice(0, limit) : filteredDocs;

    // Check likes for each tanka
    const tankaList = await Promise.all(
      resultDocs.map(async (doc) => {
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

    const lastDoc = resultDocs[resultDocs.length - 1];
    return {
      tankaList,
      hasMore,
      ...(hasMore && lastDoc ? { nextCursor: lastDoc.id } : {}),
    };
  }
);
