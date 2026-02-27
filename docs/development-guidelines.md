# 開発ガイドライン

> 生成日時: 2026-02-27
> ステータス: Draft
> 入力: docs/product-requirements.md, docs/architecture.md, docs/repository-structure.md, CLAUDE.md

## 1. コーディング規約

### 1.1 命名規則（Swift API Design Guidelines 準拠）

| 対象 | 規則 | 例 |
|---|---|---|
| 型名 | UpperCamelCase | `FeedViewModel`, `TankaRepository` |
| メソッド名 | lowerCamelCase | `fetchFeed()`, `toggleLike(for:)` |
| 変数名 | lowerCamelCase | `tankaList`, `isLoading` |
| Boolean | is / has / can / should プレフィックス | `isLoading`, `hasMore`, `canCompose` |
| Protocol | -able / -ible / -ing サフィックス または名詞 | `TankaRepositoryProtocol`, `Sendable` |
| Enum ケース | lowerCamelCase | `WorryCategory.relationship` |
| ファイル名 | 主要型名と一致 | `FeedViewModel.swift` |

### 1.2 ファイル構成

- 1 ファイル 1 型を原則とする
- View は Feature 内の `View/` ディレクトリに配置
- ViewModel は Feature 内の `ViewModel/` ディレクトリに配置
- 共通モデルは `Shared/Model/` に配置
- Extension は `Shared/Extensions/` に配置

### 1.3 アクセスコントロール

| レベル | 用途 |
|---|---|
| `internal`（デフォルト） | モジュール内で使う型・メソッド |
| `private` | ファイル内でのみ使うプロパティ・メソッド |
| `private(set)` | ViewModel の状態プロパティ（読み取りは internal、書き込みは private） |
| `public` | 現時点では不要（単一ターゲット構成のため） |

### 1.4 SwiftLint / SwiftFormat 補足

- SwiftLint / SwiftFormat は Mint で管理する（`Mintfile` にバージョンを固定）
- CI（GitHub Actions）で自動チェック
- 主要ルール: `line_length: 120`, `force_unwrapping: error`, `force_cast: error`

## 2. 実装パターン集

### 2.1 View パターン

```swift
struct FeedView: View {
    @State private var viewModel = FeedViewModel()

    var body: some View {
        content
            .task {
                await viewModel.loadFeed()
            }
            .refreshable {
                await viewModel.loadFeed()
            }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.tankaList.isEmpty {
            LoadingView()
        } else if let error = viewModel.error, viewModel.tankaList.isEmpty {
            ErrorView(error: error) {
                Task { await viewModel.loadFeed() }
            }
        } else if viewModel.tankaList.isEmpty {
            EmptyStateView(message: "まだ短歌がありません")
        } else {
            tankaList
        }
    }
}
```

**ポイント:**
- `@State` で ViewModel のオーナーシップを持つ
- `@ViewBuilder` で状態ごとのレイアウトを分岐
- `.task` で非同期処理を開始

### 2.2 ViewModel パターン

```swift
@Observable
@MainActor
final class FeedViewModel {
    // MARK: - State
    private(set) var tankaList: [Tanka] = []
    private(set) var isLoading = false
    private(set) var error: AppError?
    private(set) var hasMore = true

    // MARK: - Sheet / Alert State
    var reportTarget: Tanka?
    var blockTarget: Tanka?

    // MARK: - Dependencies
    private let tankaRepository: any TankaRepositoryProtocol

    // MARK: - Init
    init(tankaRepository: any TankaRepositoryProtocol = TankaRepository()) {
        self.tankaRepository = tankaRepository
    }

    // MARK: - Actions
    func loadFeed() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await tankaRepository.fetchFeed(limit: 20, afterID: nil)
            tankaList = response.tankaList
            hasMore = response.hasMore
            error = nil
        } catch {
            self.error = AppError(error)
        }
    }
}
```

**ポイント:**
- `@Observable` + `@MainActor` をクラスに適用
- `private(set)` で状態の外部からの直接変更を防ぐ
- `MARK` コメントでセクションを分ける
- コンストラクタインジェクションで依存を注入（テスト時に差し替え可能）

### 2.3 Repository パターン

```swift
// Protocol（Shared/Repository/）
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

// 具象実装（Shared/Repository/）
final class TankaRepository: TankaRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func fetchFeed(limit: Int, afterID: String?) async throws -> FeedResponse {
        var params: [String: String] = ["limit": "\(limit)"]
        if let afterID { params["afterID"] = afterID }
        return try await apiClient.get("/api/v1/tanka/feed", parameters: params)
    }
}

// Mock（Tests/Mock/）
final class MockTankaRepository: TankaRepositoryProtocol, @unchecked Sendable {
    var stubbedFeedResponse = FeedResponse(tankaList: [], hasMore: false, nextCursor: nil)
    var stubbedError: Error?

    func fetchFeed(limit: Int, afterID: String?) async throws -> FeedResponse {
        if let error = stubbedError { throw error }
        return stubbedFeedResponse
    }
    // ... 他メソッド
}
```

### 2.4 Model パターン

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

**ポイント:**
- `Codable`, `Sendable`, `Identifiable` に準拠する struct
- イミュータブル（`let`）を基本。クライアント側で変更するもののみ `var`

### 2.5 DI パターン（EnvironmentKey）

```swift
// Sources/App/DI/EnvironmentKeys.swift
private struct TankaRepositoryKey: EnvironmentKey {
    static let defaultValue: any TankaRepositoryProtocol = TankaRepository()
}

extension EnvironmentValues {
    var tankaRepository: any TankaRepositoryProtocol {
        get { self[TankaRepositoryKey.self] }
        set { self[TankaRepositoryKey.self] = newValue }
    }
}
```

### 2.6 Navigation パターン

```swift
// タブ定義
enum AppTab: String, CaseIterable {
    case feed = "フィード"
    case myTanka = "わたしの歌"
    case settings = "設定"
}

// ルート定義
enum FeedRoute: Hashable {
    case compose
    case tankaResult(category: WorryCategory, worryText: String)
}

// ナビゲーション View
struct FeedNavigationView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            FeedView(path: $path)
                .navigationDestination(for: FeedRoute.self) { route in
                    switch route {
                    case .compose:
                        ComposeView(path: $path)
                    case .tankaResult(let category, let worryText):
                        TankaResultView(category: category, worryText: worryText, path: $path)
                    }
                }
        }
    }
}
```

## 3. 禁止パターン

| 禁止 API | 理由 | 代替 |
|---|---|---|
| `ObservableObject` / `@Published` | レガシー API | `@Observable` マクロ |
| `@StateObject` | レガシー API | `@State` |
| `@ObservedObject` | レガシー API | `@Bindable` |
| `@EnvironmentObject` | レガシー API | `@Environment` + `EnvironmentKey` |
| `DispatchQueue` | GCD はレガシー | Swift Concurrency（`async/await`） |
| `force unwrap`（`!`） | クラッシュリスク | `guard let` / `if let` / `??` |
| `force cast`（`as!`） | クラッシュリスク | `as?` + `guard` |
| `try!` | クラッシュリスク | `try` + `do/catch` |
| `NSNotificationCenter` | レガシー | Swift Concurrency / Combine（必要な場合のみ） |
| `UIKit` 直接使用 | SwiftUI ベース | SwiftUI の API を使う（`UIViewRepresentable` は最終手段） |

## 4. Git ワークフロー

### 4.1 ブランチ戦略

| ブランチ | 用途 | 例 |
|---|---|---|
| `main` | 安定ブランチ。リリース可能な状態を維持 | - |
| `feature/<issue-number>-<description>` | 新機能開発 | `feature/1-feed-view` |
| `fix/<issue-number>-<description>` | バグ修正 | `fix/15-card-flip-animation` |
| `refactor/<description>` | リファクタリング | `refactor/extract-tanka-card` |
| `docs/<description>` | ドキュメント更新 | `docs/update-architecture` |

### 4.2 Conventional Commits

```
<type>(<scope>): <subject>

type: feat, fix, docs, style, refactor, test, chore, build, ci, perf, revert
scope: feed, compose, tanka-result, my-tanka, settings, report, shared
```

例:
```
feat(feed): フィード画面の短歌カード一覧を実装
fix(compose): 文字数カウントが正しくない問題を修正
refactor(shared): TankaCard コンポーネントを抽出
test(feed): FeedViewModel のユニットテストを追加
docs: アーキテクチャ設計書を更新
```

### 4.3 PR テンプレート

```markdown
## 概要
<!-- 変更内容を 1-2 文で -->

## 変更内容
- [ ] 変更点 1
- [ ] 変更点 2

## テスト
- [ ] ユニットテスト追加 / 更新
- [ ] 手動テスト実施

## スクリーンショット
<!-- UI 変更がある場合 -->
```

## 5. テストガイドライン

### 5.1 テスト命名規則

Swift Testing フレームワーク（`@Test`）を使用:

```swift
@Test
func loadFeed_success_updatesTankaList() async { ... }

@Test
func loadFeed_networkError_setsError() async { ... }

@Test
func toggleLike_alreadyLiked_removesLike() async { ... }
```

パターン: `<メソッド名>_<条件>_<期待結果>`

### 5.2 テスト構造（AAA パターン）

```swift
@Test
func loadFeed_success_updatesTankaList() async {
    // Arrange
    let mockRepository = MockTankaRepository()
    mockRepository.stubbedFeedResponse = FeedResponse(
        tankaList: [.mock],
        hasMore: false,
        nextCursor: nil
    )
    let viewModel = FeedViewModel(tankaRepository: mockRepository)

    // Act
    await viewModel.loadFeed()

    // Assert
    #expect(viewModel.tankaList.count == 1)
    #expect(viewModel.isLoading == false)
    #expect(viewModel.error == nil)
}
```

### 5.3 カバレッジ基準

| 対象 | 目標 |
|---|---|
| ViewModel | 80% 以上 |
| Repository | 70% 以上 |
| Model | バリデーションロジックがある場合のみ |
| View | SwiftUI Preview で確認。自動テストは必須ではない |

### 5.4 テストで検証すべき観点

| 観点 | 例 |
|---|---|
| 正常系 | データ取得成功時に状態が更新されること |
| エラー系 | ネットワークエラー時に error が設定されること |
| ローディング | 処理中は isLoading が true になること |
| バリデーション | 文字数制限が正しく機能すること |
| 1日制限 | 2回目の作成が拒否されること |

## 6. デザイン実装ガイドライン

### 6.1 カラーパレット

```swift
extension Color {
    /// 背景色: 温かみのある白
    static let appBackground = Color(red: 0.98, green: 0.97, blue: 0.96)

    /// メインテキスト: 墨色（純黒ではない）
    static let appText = Color(red: 0.25, green: 0.25, blue: 0.25)

    /// サブテキスト: 薄い墨色
    static let appSubText = Color(red: 0.5, green: 0.5, blue: 0.5)

    /// カードの背景: 白
    static let appCardBackground = Color.white

    /// 区切り線（使う場合は極力薄く）
    static let appDivider = Color(red: 0.9, green: 0.88, blue: 0.86)
}
```

### 6.2 フォント定義

```swift
extension Font {
    /// 短歌表示用: 明朝体
    static func tankaFont(size: CGFloat) -> Font {
        .custom("HiraginoMincho-W3", size: size)
    }

    /// 見出し用: システムフォント（軽め）
    static func appTitle(size: CGFloat) -> Font {
        .system(size: size, weight: .light)
    }

    /// 本文用: システムフォント（軽め）
    static func appBody(size: CGFloat) -> Font {
        .system(size: size, weight: .regular)
    }

    /// キャプション用
    static func appCaption(size: CGFloat) -> Font {
        .system(size: size, weight: .light)
    }
}
```

### 6.3 デザイン原則

- **余白**: 要素間の余白を十分に取る。詰め込まない
- **色**: 基本は白・灰色・墨色のみ。アクセントカラーは使わない
- **装飾**: 罫線やボーダーは最小限。影も控えめ
- **アニメーション**: カードフリップ以外は控えめ。duration は 0.3〜0.5 秒程度
- **文字**: 純粋な黒は使わない。墨色（`appText`）を基本とする
