# 詳細設計書: Settings（設定画面）

> 生成日時: 2026-02-27
> ステータス: Draft

## 1. ファイル構成

```
Sources/Features/Settings/
├── View/
│   ├── SettingsView.swift          # 設定一覧画面
│   ├── BlockListView.swift         # ブロックリスト画面
│   └── AccountDeleteView.swift     # アカウント削除画面
└── ViewModel/
    ├── BlockListViewModel.swift    # ブロックリスト状態管理
    └── AccountDeleteViewModel.swift # アカウント削除状態管理
```

## 2. ナビゲーション設計

設定タブは `NavigationStack` を ContentView 側で持ち、`NavigationLink(value:)` + `navigationDestination` で遷移する。

### SettingsRoute

```swift
enum SettingsRoute: Hashable {
    case blockList
    case accountDelete
}
```

`Sources/Shared/Navigation/SettingsRoute.swift` に配置。

## 3. View 設計

### SettingsView

- `List` で設定項目を表示
- セクション: アカウント（ブロックリスト、アカウント削除）
- セクション: 情報（バージョン）

### BlockListView

- ブロック中ユーザー一覧を `List` で表示
- 各行に「解除」ボタン
- 空データ: 「ブロック中のユーザーはいません」

### AccountDeleteView

- 注意テキスト表示
- 確認テキスト入力（「削除」と入力で有効化）
- 「アカウントを削除する」ボタン（destructive）

## 4. ViewModel 設計

### BlockListViewModel

```swift
@Observable
@MainActor
final class BlockListViewModel {
    private(set) var blockedUsers: [BlockedUser] = []
    private(set) var isLoading = false
    private(set) var error: AppError?

    func loadBlockedUsers() async { ... }
    func unblock(userID: String) async { ... }
}
```

### AccountDeleteViewModel

```swift
@Observable
@MainActor
final class AccountDeleteViewModel {
    var confirmationText: String = ""
    private(set) var isDeleting = false
    private(set) var error: AppError?
    private(set) var isDeleted = false

    var canDelete: Bool { confirmationText == "削除" }

    func deleteAccount() async { ... }
}
```
