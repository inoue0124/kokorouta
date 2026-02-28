# 詳細設計書: いいねした短歌の一覧画面

> Issue: #73
> 生成日時: 2026-03-01
> ステータス: Draft

## 1. 画面設計

### 1.1 LikedTankaView（いいねした短歌一覧）

```
NavigationStack
└── ScrollView
    └── LazyVStack(spacing: 20)
        └── ForEach(likedTankaList)
            └── TankaCard(tanka:, onLike:)
                ├── [表面] カテゴリ + 日付 + 悩みテキスト + いいねボタン
                └── [裏面] 縦書き短歌
```

#### 状態分岐

| 状態 | 表示 |
|---|---|
| ロード中 & リスト空 | `LoadingView` |
| エラー & リスト空 | `ErrorView`（リトライボタン付き） |
| データ 0 件 | `EmptyStateView`（「いいねした短歌はまだありません」） |
| データあり | `TankaCard` 一覧 |

### 1.2 ナビゲーション導線

「わたしの歌」タブの `MyTankaView` 内に、ヘッダーとして「いいねした短歌」への `NavigationLink` を追加する。

```
NavigationStack ("わたしの歌" tab)
└── MyTankaView
    ├── Section: NavigationLink("いいねした短歌") → LikedTankaView
    └── Section: 自分の短歌カード一覧
```

## 2. レイヤー設計

### 2.1 View 層

**新規: `LikedTankaView`**
- `Sources/Features/MyTanka/View/LikedTankaView.swift`
- `@Environment(\.tankaRepository)` で Repository を注入
- `@State private var viewModel: LikedTankaViewModel?` で ViewModel を保持
- `.task` で初期読み込み、`.refreshable` でプルリフレッシュ対応
- `TankaCard(tanka:, onLike:)` を使用し、いいね解除時にリストから削除

**変更: `MyTankaView`**
- 短歌一覧の上部に「いいねした短歌」への `NavigationLink` を追加

**変更: `ContentView`**
- 「わたしの歌」タブの `NavigationStack` に `.navigationDestination(for: MyTankaRoute.self)` を追加

### 2.2 ViewModel 層

**新規: `LikedTankaViewModel`**
- `Sources/Features/MyTanka/ViewModel/LikedTankaViewModel.swift`

```swift
@Observable
@MainActor
final class LikedTankaViewModel {
    // MARK: - State
    private(set) var tankaList: [Tanka] = []
    private(set) var isLoading = false
    private(set) var error: AppError?

    // MARK: - Dependencies
    private let tankaRepository: any TankaRepositoryProtocol

    // MARK: - Init
    init(tankaRepository: any TankaRepositoryProtocol)

    // MARK: - Actions
    func loadLikedTanka() async
    func toggleLike(for tanka: Tanka) async
}
```

- `loadLikedTanka()`: Repository 経由でいいね済み短歌を取得
- `toggleLike(for:)`: いいね解除 → リストから該当短歌を削除

### 2.3 Repository 層

**変更: `TankaRepositoryProtocol`**
- `func fetchLikedTanka() async throws -> [Tanka]` を追加

**変更: `TankaRepository`**
- `fetchLikedTanka()` を実装（`FirestoreClient` に委譲）

### 2.4 Networking 層

**変更: `FirestoreClient`**
- `func fetchLikedTanka() async throws -> [Tanka]` を追加
- `collectionGroup("likes")` で `uid` に一致するドキュメントを `createdAt` 降順で取得
- 各 like ドキュメントの親パス（`tanka/{tankaID}`）から短歌 ID を抽出
- 短歌ドキュメントを並列フェッチし、`mapDocumentToTanka` で変換

### 2.5 Navigation 層

**新規: `MyTankaRoute`**
- `Sources/Shared/Navigation/MyTankaRoute.swift`

```swift
enum MyTankaRoute: Hashable {
    case likedTanka
}
```

## 3. データフロー

```
User → LikedTankaView → LikedTankaViewModel → TankaRepository → FirestoreClient
                                                                       ↓
                                                              collectionGroup("likes")
                                                              .whereField(uid)
                                                              .order(createdAt, desc)
                                                                       ↓
                                                              tanka/{tankaID} を並列フェッチ
                                                                       ↓
                                                              [Tanka] (isLikedByMe = true)
```

### いいね解除フロー

```
User tap unlike → LikedTankaViewModel.toggleLike(for:)
    → TankaRepository.unlike(tankaID:)
    → リスト更新: tankaList から該当短歌を削除
```

## 4. 変更対象ファイル一覧

### 新規作成

| ファイル | 説明 |
|---|---|
| `Sources/Features/MyTanka/View/LikedTankaView.swift` | いいねした短歌一覧画面 |
| `Sources/Features/MyTanka/ViewModel/LikedTankaViewModel.swift` | いいねした短歌一覧 ViewModel |
| `Sources/Shared/Navigation/MyTankaRoute.swift` | わたしの歌タブのルート定義 |
| `Tests/MyTanka/LikedTankaViewModelTests.swift` | ViewModel ユニットテスト |

### 変更

| ファイル | 変更内容 |
|---|---|
| `Sources/Shared/Repository/TankaRepositoryProtocol.swift` | `fetchLikedTanka()` メソッド追加 |
| `Sources/Shared/Repository/TankaRepository.swift` | `fetchLikedTanka()` 実装追加 |
| `Sources/Shared/Networking/FirestoreClient.swift` | `fetchLikedTanka()` 実装追加 |
| `Sources/Shared/Repository/MockTankaRepository.swift` | `fetchLikedTanka()` Preview 用実装追加 |
| `Tests/Mocks/MockTankaRepository.swift` | `fetchLikedTanka()` スタブ追加 |
| `Sources/Features/MyTanka/View/MyTankaView.swift` | ナビゲーションリンク追加 |
| `Sources/App/ContentView.swift` | MyTanka タブに navigationDestination 追加 |
