# 詳細設計書: MyTanka（マイ短歌履歴）

> 生成日時: 2026-02-27
> ステータス: Draft

## 1. ファイル構成

```
Sources/Features/MyTanka/
├── View/
│   └── MyTankaView.swift           # マイ短歌一覧画面
└── ViewModel/
    └── MyTankaViewModel.swift      # マイ短歌状態管理
```

## 2. View 設計

### MyTankaView

| プロパティ | 種別 | 型 | 説明 |
|---|---|---|---|
| viewModel | @State | MyTankaViewModel? | ViewModel（.task で初期化） |
| repository | @Environment | TankaRepositoryProtocol | DI |

**レイアウト:**
- `ScrollView` + `LazyVStack` で `TankaCard` を一覧表示（`onLike: nil`）
- `.refreshable` でプルリフレッシュ
- `navigationTitle("わたしの歌")`

**状態分岐:**
- `isLoading && tankaList.isEmpty` → `LoadingView`
- `error != nil && tankaList.isEmpty` → `ErrorView`
- `tankaList.isEmpty` → `EmptyStateView`
- それ以外 → カード一覧

## 3. ViewModel 設計

### MyTankaViewModel

```swift
@Observable
@MainActor
final class MyTankaViewModel {
    private(set) var tankaList: [Tanka] = []
    private(set) var isLoading = false
    private(set) var error: AppError?

    private let tankaRepository: any TankaRepositoryProtocol

    init(tankaRepository: any TankaRepositoryProtocol) { ... }

    func loadMyTanka() async { ... }
}
```

## 4. ContentView 更新

マイ短歌タブのプレースホルダーを `NavigationStack { MyTankaView() }` に置き換える。
