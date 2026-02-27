# 用語集

> 生成日時: 2026-02-27
> ステータス: Draft
> 入力: docs/ 配下の全ドキュメント

## 1. ドメイン用語

| 用語（日本語） | 用語（英語） | 定義 | コード上の命名 |
|---|---|---|---|
| 短歌 | Tanka | 5-7-5-7-7 の音数律を持つ日本の定型詩。本アプリでは AI が悩みに応じて生成する | `Tanka`, `TankaRepository` |
| 悩み | Worry | ユーザーが入力する日常の悩みテキスト（10〜200文字） | `worryText: String` |
| 悩みカテゴリ | Worry Category | 悩みの分類（人間関係・恋愛・仕事・健康の4種） | `WorryCategory` enum |
| フィード | Feed | 他ユーザーの短歌カードが新着順に流れるメイン画面 | `FeedView`, `FeedViewModel` |
| 短歌カード | Tanka Card | 表面に悩み・裏面に縦書き短歌を表示するフリップ可能なカード | `TankaCard` |
| いいね | Like | フィードの短歌に対する共感のリアクション | `LikeButton`, `likeCount`, `isLikedByMe` |
| マイ短歌 | My Tanka | ユーザー自身が過去に生成した短歌の一覧 | `MyTankaView`, `MyTankaViewModel` |
| 通報 | Report | 不適切なコンテンツを運営に報告する機能 | `Report`, `ReportSheet`, `ReportReason` |
| ブロック | Block | 特定ユーザーの短歌をフィードから非表示にする機能 | `BlockedUser`, `BlockListView` |
| 日次制限 | Daily Limit | 1日に生成可能な短歌数の制限（`MAX_DAILY_TANKA` で管理） | `lastTankaCreatedAt`, `dailyTankaCount`, `canCompose` |

## 2. 技術用語

| 用語 | 定義（プロジェクトでの意味） | 参照 |
|---|---|---|
| ViewModel | 画面の状態管理とビジネスロジックを担う `@Observable @MainActor` クラス | docs/architecture.md |
| Repository | データアクセスを抽象化する層。`TankaRepositoryProtocol` + `TankaRepository` | docs/architecture.md |
| EnvironmentKey | SwiftUI の DI メカニズム。`@Environment` で Repository を注入する | docs/architecture.md |
| Route | ナビゲーション先を表す `Hashable` enum。`FeedRoute` 等 | docs/architecture.md |
| Cloud Functions | Firebase Cloud Functions。サーバーサイドロジック（短歌生成、フィード取得等）を実行 | docs/architecture.md |
| Anonymous Auth | Firebase Anonymous Authentication。ログイン不要でユーザーを識別する匿名認証 | docs/architecture.md |
| Firestore | Firebase Cloud Firestore。短歌・いいね・通報・ブロック等のデータを保存する NoSQL DB | docs/architecture.md |
| カーソルベースページネーション | `afterID` パラメータで次のページを取得する方式。オフセットベースより整合性が高い | docs/functional-design.md |
| 縦書き | Vertical Text | テキストを縦方向に表示する。短歌カードの裏面で使用 | `VerticalText` コンポーネント |
| カードフリップ | Card Flip | 3D 回転アニメーションでカードの表裏を切り替える UI パターン | `TankaCard` |

## 3. 略語

| 略語 | 正式名称 | 説明 |
|---|---|---|
| PRD | Product Requirements Document | プロダクト要求定義書 |
| DI | Dependency Injection | 依存注入。テスタビリティ向上のために使用 |
| MVVM | Model-View-ViewModel | アーキテクチャパターン。本プロジェクトの基本構造 |
| API | Application Programming Interface | Cloud Functions 経由の HTTP エンドポイント |
| FAB | Floating Action Button | フィード画面の「今日の短歌を詠む」ボタン |
| UGC | User Generated Content | ユーザー生成コンテンツ。短歌や悩みテキストが該当 |
| DAU | Daily Active Users | 日次アクティブユーザー数 |
| KPI | Key Performance Indicator | 主要業績評価指標 |
| AAA | Arrange-Act-Assert | テストコードの構造パターン |

## 4. 命名マッピング

| ドメイン概念 | View | ViewModel | Repository | Model |
|---|---|---|---|---|
| フィード | `FeedView` | `FeedViewModel` | `TankaRepository` | `Tanka`, `FeedResponse` |
| 悩み入力 | `ComposeView` | `ComposeViewModel` | `TankaRepository` | `GenerateTankaRequest`, `WorryCategory` |
| 短歌表示 | `TankaResultView` | `TankaResultViewModel` | `TankaRepository` | `Tanka` |
| マイ短歌 | `MyTankaView` | `MyTankaViewModel` | `TankaRepository` | `Tanka` |
| 設定 | `SettingsView` | `SettingsViewModel` | - | - |
| 通報 | `ReportSheet` | `ReportViewModel` | `TankaRepository` | `ReportReason` |
| ブロック | `BlockListView` | `BlockListViewModel` | `TankaRepository` | `BlockedUser` |
| アカウント削除 | `AccountDeleteView` | `SettingsViewModel` | `TankaRepository` | - |
| 短歌カード（共通） | `TankaCard` | - | - | `Tanka` |
| 縦書き（共通） | `VerticalText` | - | - | - |
| いいね（共通） | `LikeButton` | - | - | - |
| カテゴリ（共通） | `CategoryChip` | - | - | `WorryCategory` |
