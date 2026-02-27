# 詳細設計書: Feed（フィード画面）

> 生成日時: 2026-02-27
> ステータス: Draft

## 1. ファイル構成

```
Sources/Features/Feed/
├── View/
│   ├── FeedNavigationView.swift    # NavigationStack + ルーティング
│   ├── FeedView.swift              # フィード一覧 + FAB
│   ├── ComposeView.swift           # 悩み入力画面
│   ├── TankaResultView.swift       # 短歌生成結果画面
│   ├── ReportSheet.swift           # 通報理由選択シート
│   └── FloatingActionButton.swift  # FAB コンポーネント
└── ViewModel/
    ├── FeedViewModel.swift         # フィード状態管理
    ├── ComposeViewModel.swift      # 入力バリデーション
    └── TankaResultViewModel.swift  # 短歌生成処理
```

## 2. ナビゲーション設計

### FeedNavigationView

`NavigationStack` + `NavigationPath` を所有し、`FeedRoute` による型安全ルーティングを提供する。

```swift
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
                        TankaResultView(
                            category: category,
                            worryText: worryText,
                            path: $path
                        )
                    }
                }
        }
    }
}
```

### ContentView 更新

フィードタブのプレースホルダーを `FeedNavigationView()` に置き換える。

## 3. View 設計

### 3.1 FeedView

| プロパティ | 種別 | 型 | 説明 |
|---|---|---|---|
| viewModel | @State | FeedViewModel? | ViewModel（.task で初期化） |
| path | @Binding | NavigationPath | ナビゲーションパス |
| repository | @Environment | TankaRepositoryProtocol | DI |
| showReportSheet | @State | Bool | 通報シート表示フラグ |
| showBlockAlert | @State | Bool | ブロック確認表示フラグ |

**レイアウト:**
- `ScrollView` + `LazyVStack` で `TankaCard` を一覧表示
- 最後のカードで `onAppear` → `loadMore()`
- `.refreshable` でプルリフレッシュ
- `.overlay(alignment: .bottomTrailing)` で FAB を配置
- `.contextMenu` でカード長押し → 通報 / ブロック
- `.sheet` で通報シート表示
- `.alert` でブロック確認表示

**状態分岐:**
- `isLoading && tankaList.isEmpty` → `LoadingView`
- `error != nil && tankaList.isEmpty` → `ErrorView`
- `tankaList.isEmpty` → `EmptyStateView`
- それ以外 → カード一覧

### 3.2 ComposeView

| プロパティ | 種別 | 型 | 説明 |
|---|---|---|---|
| viewModel | @State | ComposeViewModel | ViewModel |
| path | @Binding | NavigationPath | ナビゲーションパス |

**レイアウト:**
- タイトル「今日のお悩みを教えてください」
- `HStack` で `CategoryChip` × 4
- `TextEditor` で悩みテキスト入力
- 文字数カウンター（10〜200文字）
- 注意書き（個人情報に関する注意）
- 「短歌を詠む」ボタン（バリデーション通過で有効化）

**遷移:**
- 「短歌を詠む」タップ → `path.append(FeedRoute.tankaResult(category:worryText:))`

### 3.3 TankaResultView

| プロパティ | 種別 | 型 | 説明 |
|---|---|---|---|
| viewModel | @State | TankaResultViewModel? | ViewModel（.task で初期化） |
| category | let | WorryCategory | カテゴリ |
| worryText | let | String | 悩みテキスト |
| path | @Binding | NavigationPath | ナビゲーションパス |
| repository | @Environment | TankaRepositoryProtocol | DI |

**レイアウト:**
- 生成中: `LoadingView(message: "短歌を詠んでいます...")`
- 生成完了: `TankaCard` + 「フィードに戻る」ボタン
- エラー: `ErrorView` + リトライ

**遷移:**
- 「フィードに戻る」 → `path.removeLast(path.count)` でルートに戻る

### 3.4 ReportSheet

| プロパティ | 種別 | 型 | 説明 |
|---|---|---|---|
| selectedReason | @State | ReportReason? | 選択中の通報理由 |
| isSubmitting | @State | Bool | 送信中フラグ |
| tanka | let | Tanka | 通報対象の短歌 |
| onSubmit | let | (ReportReason) async -> Void | 送信コールバック |
| dismiss | @Environment | DismissAction | シート閉じる |

### 3.5 FloatingActionButton

- 画面右下に配置する円形ボタン
- 筆アイコン + 和風テイスト
- `action` クロージャで遷移を発火

## 4. ViewModel 設計

### 4.1 FeedViewModel

```swift
@Observable
@MainActor
final class FeedViewModel {
    // 状態
    private(set) var tankaList: [Tanka] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var error: AppError?
    private(set) var hasMore = true
    var reportTarget: Tanka?
    var blockTarget: Tanka?

    private var nextCursor: String?
    private let tankaRepository: any TankaRepositoryProtocol

    init(tankaRepository: any TankaRepositoryProtocol) { ... }

    // アクション
    func loadFeed() async { ... }
    func loadMore() async { ... }
    func toggleLike(for tanka: Tanka) async { ... }
    func report(tankaID: String, reason: ReportReason) async { ... }
    func blockUser(authorID: String) async { ... }
}
```

### 4.2 ComposeViewModel

```swift
@Observable
@MainActor
final class ComposeViewModel {
    var selectedCategory: WorryCategory?
    var worryText: String = ""

    var isValid: Bool { ... }        // カテゴリ選択済み && 10〜200文字
    var characterCount: Int { ... }  // worryText.count
    var validationMessage: String? { ... }
}
```

### 4.3 TankaResultViewModel

```swift
@Observable
@MainActor
final class TankaResultViewModel {
    private(set) var generatedTanka: Tanka?
    private(set) var isLoading = false
    private(set) var error: AppError?

    private let tankaRepository: any TankaRepositoryProtocol

    init(tankaRepository: any TankaRepositoryProtocol) { ... }

    func generateTanka(category: WorryCategory, worryText: String) async { ... }
}
```

## 5. DI パターン

View 内で `@Environment(\.tankaRepository)` を取得し、`.task` 内で ViewModel をコンストラクタインジェクションで初期化する。

```swift
struct FeedView: View {
    @Environment(\.tankaRepository) private var repository
    @State private var viewModel: FeedViewModel?

    var body: some View {
        content
            .task {
                if viewModel == nil {
                    viewModel = FeedViewModel(tankaRepository: repository)
                }
                await viewModel?.loadFeed()
            }
    }
}
```

## 6. エラーハンドリング

| エラー | ハンドリング |
|---|---|
| ネットワークエラー | `ErrorView` + リトライボタン |
| 空フィード | `EmptyStateView("まだ短歌がありません")` |
| レートリミット | `AppError.rateLimited` → FAB 無効化 |
| 通報/ブロック失敗 | `error` にセットし表示 |
| 短歌生成失敗 | `ErrorView` + リトライボタン |
| バリデーション | インラインメッセージ |
