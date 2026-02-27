import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

export const reportTanka = onCall(
  { region: "asia-northeast1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "認証が必要です。");
    }

    const { tankaID, reason } = request.data;

    if (!tankaID || typeof tankaID !== "string") {
      throw new HttpsError("invalid-argument", "tankaID を指定してください。");
    }

    if (!reason || typeof reason !== "string" || reason.trim().length === 0) {
      throw new HttpsError("invalid-argument", "通報理由を入力してください。");
    }

    const db = admin.firestore();
    const tankaRef = db.collection("tanka").doc(tankaID);

    const tankaDoc = await tankaRef.get();
    if (!tankaDoc.exists) {
      throw new HttpsError("not-found", "指定された短歌が見つかりません。");
    }

    // Add report
    await db.collection("reports").add({
      tankaID,
      reporterID: uid,
      reason: reason.trim(),
      createdAt: admin.firestore.Timestamp.now(),
    });

    // Increment reportCount and hide if >= 3
    const currentReportCount = tankaDoc.data()?.reportCount ?? 0;
    const newReportCount = currentReportCount + 1;

    const updateData: Record<string, unknown> = {
      reportCount: newReportCount,
    };
    if (newReportCount >= 3) {
      updateData.isHidden = true;
    }

    await tankaRef.update(updateData);

    return {};
  }
);
