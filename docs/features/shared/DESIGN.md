# 詳細設計書: Shared（共通基盤）

> 生成日時: 2026-02-27
> ステータス: Draft

## ディレクトリ構成

```
Sources/Shared/
├── Model/
│   ├── Tanka.swift
│   ├── WorryCategory.swift
│   ├── ReportReason.swift
│   ├── BlockedUser.swift
│   └── AppTab.swift
├── Repository/
│   ├── TankaRepositoryProtocol.swift
│   ├── TankaRepository.swift
│   └── DTO/
│       ├── FeedResponse.swift
│       ├── LikeResponse.swift
│       ├── GenerateTankaRequest.swift
│       ├── GenerateTankaResponse.swift
│       ├── MyTankaResponse.swift
│       ├── BlockedUsersResponse.swift
│       └── ReportRequest.swift
├── Networking/
│   ├── APIClient.swift
│   └── NetworkError.swift
├── Error/
│   └── AppError.swift
├── Components/
│   ├── TankaCard.swift
│   ├── VerticalText.swift
│   ├── CategoryChip.swift
│   ├── LikeButton.swift
│   ├── LoadingView.swift
│   ├── ErrorView.swift
│   └── EmptyStateView.swift
├── Extensions/
│   ├── Color+App.swift
│   ├── Font+App.swift
│   └── Date+Formatting.swift
├── DI/
│   └── EnvironmentKeys.swift
└── Navigation/
    └── FeedRoute.swift
```

## Model 層

### Tanka

```swift
struct Tanka: Codable, Sendable, Identifiable {
    let id: String
    let authorID: String
    let category: WorryCategory
    let worryText: String
    let tankaText: String
    var likeCount: Int
    var isLikedByMe: Bool
    let createdAt: Date
}
```

### WorryCategory

```swift
enum WorryCategory: String, Codable, Sendable, CaseIterable {
    case relationship
    case love
    case work
    case health

    var displayName: String { ... }
}
```

### ReportReason

```swift
enum ReportReason: String, Codable, Sendable, CaseIterable {
    case inappropriate
    case spam
    case other

    var displayName: String { ... }
}
```

### BlockedUser

```swift
struct BlockedUser: Codable, Sendable, Identifiable {
    let id: String
    let blockedID: String
    let createdAt: Date
}
```

### AppTab

```swift
enum AppTab: String, CaseIterable {
    case feed = "フィード"
    case myTanka = "わたしの歌"
    case settings = "設定"

    var systemImage: String { ... }
}
```

## Repository 層

### TankaRepositoryProtocol

```swift
protocol TankaRepositoryProtocol: Sendable {
    func generateTanka(category: WorryCategory, worryText: String) async throws -> Tanka
    func fetchFeed(limit: Int, afterID: String?) async throws -> FeedResponse
    func fetchMyTanka() async throws -> [Tanka]
    func like(tankaID: String) async throws -> LikeResponse
    func unlike(tankaID: String) async throws -> LikeResponse
    func report(tankaID: String, reason: ReportReason) async throws
    func blockUser(userID: String) async throws
    func unblockUser(userID: String) async throws
    func fetchBlockedUsers() async throws -> [BlockedUser]
    func deleteAccount() async throws
}
```

### TankaRepository

Firebase Cloud Functions 経由の本番実装。APIClient を依存として受け取る。

### DTO（Data Transfer Object）

API のリクエスト/レスポンス型を `Repository/DTO/` に配置。全て `Codable, Sendable` に準拠。

## Networking 層

### APIClient

Firebase Cloud Functions の呼び出しをラップする。`URLSession` + `async/await` で実装。

- `get<T: Decodable>(_:parameters:) async throws -> T`
- `post<T: Decodable, U: Encodable>(_:body:) async throws -> T`
- `delete(_:) async throws`
- Firebase Auth のトークンを自動付与
- JSONDecoder に `dateDecodingStrategy = .iso8601` を設定

### NetworkError

```swift
enum NetworkError: Error, Sendable {
    case noConnection
    case timeout
    case serverError(statusCode: Int)
    case decodingError
    case unauthorized
}
```

## コンポーネント設計

### TankaCard

- 3D フリップアニメーション（`.rotation3DEffect`）
- 表面: 悩みテキスト + カテゴリ + 日付 + いいね
- 裏面: 縦書き短歌（VerticalText）
- タップでフリップ切替
- 白背景、墨色テキスト、余白多め

### VerticalText

- `Text` の `.rotationEffect` + `.frame` で縦書きを実現
- 明朝体フォント（HiraginoMincho-W3）
- 右から左に行が進む

### デザイントークン

`Color+App` / `Font+App` に定義。`docs/development-guidelines.md` の §6 に準拠。
