# 要件定義書: Cloud Functions → 直接 Firestore アクセスへの移行

> 生成日時: 2026-02-28
> Issue: #68
> ステータス: Draft

## 1. 概要

Cloud Functions のコールドスタートによる遅延を回避するため、AI 生成以外の CRUD 操作をアプリから直接 Firestore を呼び出す方式に変更する。

## 2. 背景・動機

- Cloud Functions はコールドスタート時に数秒〜十数秒の遅延が発生する
- フィード取得・お気に入り操作は頻繁に行われるため、UX への影響が大きい
- AI 生成処理はサーバーサイドで実行する必要があるが、それ以外の CRUD 操作はクライアントから直接実行可能

## 3. 移行対象

### 3.1 直接 Firestore アクセスに移行する操作

| # | 操作 | 現在の実装 | 移行後 | 理由 |
|---|---|---|---|---|
| 1 | フィード取得 (`fetchFeed`) | Cloud Functions | 直接 Firestore クエリ | 読み取りのみ。コールドスタートの影響が最も大きい |
| 2 | マイ短歌取得 (`fetchMyTanka`) | Cloud Functions | 直接 Firestore クエリ | 読み取りのみ |
| 3 | いいね追加 (`likeTanka`) | Cloud Functions | Firestore Transaction | 頻繁な操作。Transaction で整合性を担保 |
| 4 | いいね削除 (`unlikeTanka`) | Cloud Functions | Firestore Transaction | 同上 |
| 5 | ブロックユーザー取得 (`fetchBlockedUsers`) | Cloud Functions | 直接 Firestore クエリ | 読み取りのみ |

### 3.2 Cloud Functions を維持する操作

| # | 操作 | 理由 |
|---|---|---|
| 1 | 短歌生成 (`generateTanka`) | OpenAI API キーをサーバー側で管理する必要がある |
| 2 | 通報 (`reportTanka`) | サーバーサイドでのバリデーション・レートリミットが重要 |
| 3 | ブロック追加/解除 (`blockUser` / `unblockUser`) | 複数コレクションの整合性を担保する必要がある |
| 4 | アカウント削除 (`deleteAccount`) | Admin SDK による多コレクション削除が必要 |

## 4. 機能要件

### FR-1: フィード取得の直接 Firestore アクセス

- `tanka` コレクションから `isHidden == false` の短歌を `createdAt` 降順で取得する
- ブロックユーザーの短歌をフィルタリングする（`users/{uid}/blockedUsers` を参照）
- 各短歌について `tanka/{tankaID}/likes/{uid}` の存在で `isLikedByMe` を判定する
- カーソルベースのページネーションをサポートする（`afterID` パラメータ）
- `limit + 1` 件取得して `hasMore` を判定する

### FR-2: マイ短歌取得の直接 Firestore アクセス

- `tanka` コレクションから `authorID == uid` の短歌を `createdAt` 降順で取得する
- 各短歌について `isLikedByMe` を判定する

### FR-3: いいね追加の直接 Firestore アクセス

- Firestore Transaction で以下を実行する:
  - `tanka/{tankaID}` の存在を確認する
  - `tanka/{tankaID}/likes/{uid}` が存在しないことを確認する（重複防止）
  - `tanka/{tankaID}/likes/{uid}` にドキュメントを追加する
  - `tanka/{tankaID}.likeCount` をインクリメントする
- 更新後の `likeCount` を返す

### FR-4: いいね削除の直接 Firestore アクセス

- Firestore Transaction で以下を実行する:
  - `tanka/{tankaID}` の存在を確認する
  - `tanka/{tankaID}/likes/{uid}` の存在を確認する
  - `tanka/{tankaID}/likes/{uid}` を削除する
  - `tanka/{tankaID}.likeCount` をデクリメントする（最小値 0）
- 更新後の `likeCount` を返す

### FR-5: ブロックユーザー取得の直接 Firestore アクセス

- `users/{uid}/blockedUsers` サブコレクションからブロックユーザー一覧を取得する

## 5. 非機能要件

### NFR-1: パフォーマンス

- フィード取得がコールドスタートの影響を受けずに高速に動作すること
- いいね追加・削除が即座に反映されること

### NFR-2: セキュリティ

- Firestore Security Rules が適切に設定されていること
  - 認証済みユーザーのみアクセス可能
  - 自分のいいねのみ追加・削除可能
  - 自分のブロックリストのみ読み取り可能
  - 短歌の読み取りは認証済みユーザーに許可
  - `likeCount` や `isHidden` などのフィールドはクライアントから直接変更不可（Transaction 経由のみ）

### NFR-3: データ整合性

- いいね操作は Firestore Transaction で整合性を担保すること
- `likeCount` が負の値にならないこと

### NFR-4: エラーハンドリング

- Firestore エラーを既存の `AppError` / `NetworkError` にマッピングすること
- ユーザーに適切なエラーメッセージを表示すること

### NFR-5: テスタビリティ

- 既存の Mock パターンを維持し、テストが引き続き動作すること
- Protocol レベルのインターフェースは変更しない

## 6. 受け入れ条件

- [ ] フィード取得がコールドスタートの影響を受けずに高速に動作する
- [ ] お気に入り追加・削除が即座に反映される
- [ ] AI 生成処理は引き続き Cloud Functions 経由で正常に動作する
- [ ] Firestore Security Rules が適切に設定されている
- [ ] 既存のテストが引き続きパスする
- [ ] `TankaRepositoryProtocol` のインターフェースは変更しない
