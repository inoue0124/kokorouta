# タスクリスト: Cloud Functions → 直接 Firestore アクセスへの移行

> 生成日時: 2026-02-28
> Issue: #68
> 入力: REQUIREMENTS.md, DESIGN.md

## タスク一覧

- [ ] **Task 1**: FirestoreClient の新規作成
  - ファイル: `Sources/Shared/Networking/FirestoreClient.swift`
  - 内容:
    - `FirestoreClient` クラスを作成（`Sendable`、シングルトン）
    - `currentUserID` プロパティの実装
    - `mapDocumentToTanka` ヘルパーメソッドの実装
    - `fetchFeed(limit:afterID:)` メソッドの実装
    - `fetchMyTanka()` メソッドの実装
    - `like(tankaID:)` メソッドの実装（Transaction）
    - `unlike(tankaID:)` メソッドの実装（Transaction）
    - `fetchBlockedUsers()` メソッドの実装

- [ ] **Task 2**: TankaRepository の変更
  - ファイル: `Sources/Shared/Repository/TankaRepository.swift`
  - 内容:
    - `FirestoreClient` の依存を追加
    - `fetchFeed` / `fetchMyTanka` / `like` / `unlike` / `fetchBlockedUsers` を `FirestoreClient` に委譲
    - `generateTanka` / `report` / `blockUser` / `unblockUser` / `deleteAccount` は `APIClient` 経由を維持

- [ ] **Task 3**: AppError の Firestore エラー対応
  - ファイル: `Sources/Shared/Error/AppError.swift`
  - 内容:
    - `init(_ error:)` に Firestore エラードメインのマッピングを追加

- [ ] **Task 4**: Firestore Security Rules の更新
  - ファイル: `firestore.rules`
  - 内容:
    - `tanka` コレクションの読み取りを認証済みユーザーに許可
    - `tanka/{tankaID}` の `likeCount` のみ更新可能に設定
    - `tanka/{tankaID}/likes/{userID}` の自分のドキュメントのみ作成・削除可能
    - `users/{userID}/blockedUsers` の自分のサブコレクションのみ読み取り可能

- [ ] **Task 5**: Firestore インデックスの確認・更新
  - ファイル: `firestore.indexes.json`
  - 内容:
    - `tanka` コレクションの `isHidden` + `createdAt` 複合インデックスの確認
    - `tanka` コレクションの `authorID` + `createdAt` 複合インデックスの確認

- [ ] **Task 6**: 構文検証・ビルド確認
  - 内容:
    - 全ファイルの構文検証
    - ビルドが通ることを確認
