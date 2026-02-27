import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

export const deleteAccount = onCall(
  { region: "asia-northeast1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "認証が必要です。");
    }

    const db = admin.firestore();

    // 1. Set all user's tanka to isHidden = true (batch)
    const tankaSnapshot = await db
      .collection("tanka")
      .where("authorID", "==", uid)
      .get();

    const batchSize = 500;
    for (let i = 0; i < tankaSnapshot.docs.length; i += batchSize) {
      const batch = db.batch();
      const chunk = tankaSnapshot.docs.slice(i, i + batchSize);
      for (const doc of chunk) {
        batch.update(doc.ref, { isHidden: true });
      }
      await batch.commit();
    }

    // 2. Delete all blockedUsers subcollection docs
    const blockedSnapshot = await db
      .collection("users")
      .doc(uid)
      .collection("blockedUsers")
      .get();

    for (let i = 0; i < blockedSnapshot.docs.length; i += batchSize) {
      const batch = db.batch();
      const chunk = blockedSnapshot.docs.slice(i, i + batchSize);
      for (const doc of chunk) {
        batch.delete(doc.ref);
      }
      await batch.commit();
    }

    // 3. Delete the user document
    await db.collection("users").doc(uid).delete();

    // 4. Delete Firebase Auth user
    await admin.auth().deleteUser(uid);

    return {};
  }
);
