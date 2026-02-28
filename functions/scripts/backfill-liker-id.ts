/**
 * マイグレーションスクリプト: 既存の likes ドキュメントに likerID フィールドを追加する
 *
 * 背景:
 *   likes サブコレクションのドキュメント ID は userID だが、
 *   collectionGroup クエリで likerID フィールドによるフィルタが必要なため、
 *   既存データにも likerID を補填する。
 *
 * 実行方法:
 *   cd functions
 *   npx ts-node scripts/backfill-liker-id.ts
 */

import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

async function backfillLikerID(): Promise<void> {
  const tankaSnapshot = await db.collection("tanka").get();
  let updated = 0;
  let skipped = 0;

  for (const tankaDoc of tankaSnapshot.docs) {
    const likesSnapshot = await tankaDoc.ref.collection("likes").get();

    const batch = db.batch();
    let batchCount = 0;

    for (const likeDoc of likesSnapshot.docs) {
      const data = likeDoc.data();
      if (data.likerID) {
        skipped++;
        continue;
      }

      // ドキュメント ID が userID
      batch.update(likeDoc.ref, { likerID: likeDoc.id });
      batchCount++;
      updated++;

      // Firestore バッチは 500 件まで
      if (batchCount >= 500) {
        await batch.commit();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }
  }

  console.log(`Done. Updated: ${updated}, Skipped: ${skipped}`);
}

backfillLikerID().catch(console.error);
