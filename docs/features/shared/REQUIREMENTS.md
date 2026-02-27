# 要件定義書: Shared（共通基盤）

> 生成日時: 2026-02-27
> ステータス: Draft

## 概要

全 Feature Module が依存する共通基盤を構築する。Model 層・Repository 層・Networking 層・共通 UI コンポーネント・デザイントークン・DI 基盤・ナビゲーション定義を含む。

## 背景

kokorouta アプリは Feed / Compose / TankaResult / MyTanka / Settings / Report の 6 Feature Module で構成される。これらが共通で使用する型・プロトコル・コンポーネントを `Sources/Shared/` に集約し、重複を排除する。

## 機能要件

### FR-001: データモデル

| モデル | 説明 | 準拠プロトコル |
|---|---|---|
| Tanka | 短歌エンティティ | Codable, Sendable, Identifiable |
| WorryCategory | 悩みカテゴリ enum（4種） | String, Codable, Sendable, CaseIterable |
| ReportReason | 通報理由 enum（3種） | String, Codable, Sendable, CaseIterable |
| BlockedUser | ブロックユーザー | Codable, Sendable, Identifiable |
| AppTab | タブ定義 enum | String, CaseIterable |

### FR-002: Repository Protocol + 実装

- `TankaRepositoryProtocol: Sendable` — 全 API 操作を定義
- `TankaRepository` — Firebase Cloud Functions 経由の実装
- API レスポンス型: `FeedResponse`, `LikeResponse`, `GenerateTankaRequest`, `GenerateTankaResponse`, `BlockedUsersResponse`, `MyTankaResponse`, `ReportRequest`

### FR-003: Networking

- `APIClient` — Firebase Cloud Functions 呼び出しの共通クライアント
- `NetworkError` — ネットワークエラー型

### FR-004: エラーハンドリング

- `AppError` — アプリ共通エラー型（network / validation / rateLimited / authentication / unknown）

### FR-005: 共通 UI コンポーネント

| コンポーネント | 説明 |
|---|---|
| TankaCard | フリップ可能な短歌カード（表: 悩み、裏: 縦書き短歌） |
| VerticalText | 縦書きテキスト表示（明朝体） |
| CategoryChip | カテゴリ選択チップ |
| LikeButton | いいねボタン（トグル式） |
| LoadingView | ローディング表示 |
| ErrorView | リトライボタン付きエラー表示 |
| EmptyStateView | 空データ時のメッセージ表示 |

### FR-006: デザイントークン

- `Color+App` — アプリ共通カラー（appBackground, appText, appSubText, appCardBackground, appDivider）
- `Font+App` — アプリ共通フォント（tankaFont, appTitle, appBody, appCaption）
- `Date+Formatting` — 日付フォーマット

### FR-007: DI 基盤

- `EnvironmentKeys` — TankaRepository の EnvironmentKey 定義

### FR-008: ナビゲーション

- `FeedRoute` — フィードタブのルート定義 enum

## 非機能要件

- 全型が `Sendable` に準拠すること（Swift 6.2 strict concurrency）
- `@Observable` / `@State` / `@Environment` を使用（レガシー API 禁止）
- 1 ファイル 1 型

## 受け入れ条件

| # | 条件 | 検証方法 |
|---|---|---|
| AC-001 | 全ファイルが構文チェック（typecheck）を通過すること | swiftc -typecheck または XcodeBuildMCP |
| AC-002 | Sources/Shared/ 配下にファイルが正しく配置されていること | ディレクトリ構成を確認 |
| AC-003 | project.yml に Sources/Shared がソースとして含まれていること | project.yml を確認 |
| AC-004 | Sample Feature を削除し、Shared のみの状態でビルドが通ること | ビルド確認 |
