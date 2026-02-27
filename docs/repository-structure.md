# リポジトリ構造定義書

> 生成日時: 2026-02-27
> ステータス: Draft
> 入力: docs/product-requirements.md, docs/functional-design.md, docs/architecture.md

## 1. ディレクトリツリー

```
kokorouta/
├── CLAUDE.md                                    # AI アシスタント向け規約
├── project.yml                                  # XcodeGen プロジェクト定義
├── Mintfile                                     # SwiftLint / SwiftFormat バージョン管理
├── .swiftlint.yml                               # SwiftLint ルール
├── .swiftformat                                 # SwiftFormat ルール
├── .github/
│   ├── workflows/
│   │   └── ci.yml                               # CI ワークフロー
│   └── dependabot.yml                           # 依存関係自動更新
├── fastlane/
│   └── Fastfile                                 # CI/CD レーン定義
├── docs/
│   ├── ideas/                                   # アイデアメモ
│   ├── product-requirements.md                  # プロダクト要求定義書
│   ├── functional-design.md                     # 機能設計書
│   ├── architecture.md                          # アーキテクチャ設計書
│   ├── repository-structure.md                  # リポジトリ構造定義書（本ドキュメント）
│   ├── development-guidelines.md                # 開発ガイドライン
│   └── glossary.md                              # 用語集
├── Sources/
│   ├── App/
│   │   ├── App.swift                            # @main エントリポイント
│   │   ├── ContentView.swift                    # TabView ルートナビゲーション
│   │   ├── Info.plist                           # アプリ設定
│   │   └── DI/
│   │       └── EnvironmentKeys.swift            # 全 EnvironmentKey 定義
│   ├── Features/
│   │   ├── Feed/
│   │   │   ├── View/
│   │   │   │   ├── FeedView.swift               # フィード画面
│   │   │   │   └── FeedNavigationView.swift     # フィードタブのナビゲーション
│   │   │   ├── ViewModel/
│   │   │   │   └── FeedViewModel.swift          # フィード画面 ViewModel
│   │   │   └── Model/
│   │   │       └── FeedResponse.swift           # フィード API レスポンス型
│   │   ├── Compose/
│   │   │   ├── View/
│   │   │   │   └── ComposeView.swift            # 悩み入力画面
│   │   │   ├── ViewModel/
│   │   │   │   └── ComposeViewModel.swift       # 悩み入力 ViewModel
│   │   │   └── Model/
│   │   │       └── GenerateTankaRequest.swift   # 短歌生成リクエスト型
│   │   ├── TankaResult/
│   │   │   ├── View/
│   │   │   │   └── TankaResultView.swift        # 短歌表示画面
│   │   │   └── ViewModel/
│   │   │       └── TankaResultViewModel.swift   # 短歌生成 ViewModel
│   │   ├── MyTanka/
│   │   │   ├── View/
│   │   │   │   ├── MyTankaView.swift            # マイ短歌履歴画面
│   │   │   │   └── MyTankaNavigationView.swift  # マイ短歌タブのナビゲーション
│   │   │   └── ViewModel/
│   │   │       └── MyTankaViewModel.swift       # マイ短歌履歴 ViewModel
│   │   ├── Settings/
│   │   │   ├── View/
│   │   │   │   ├── SettingsView.swift           # 設定画面
│   │   │   │   ├── SettingsNavigationView.swift # 設定タブのナビゲーション
│   │   │   │   ├── BlockListView.swift          # ブロックリスト画面
│   │   │   │   └── AccountDeleteView.swift      # アカウント削除画面
│   │   │   └── ViewModel/
│   │   │       ├── SettingsViewModel.swift      # 設定 ViewModel
│   │   │       └── BlockListViewModel.swift     # ブロックリスト ViewModel
│   │   └── Report/
│   │       ├── View/
│   │       │   └── ReportSheet.swift            # 通報シート
│   │       └── ViewModel/
│   │           └── ReportViewModel.swift        # 通報 ViewModel
│   └── Shared/
│       ├── Components/
│       │   ├── TankaCard.swift                  # フリップ可能な短歌カード
│       │   ├── VerticalText.swift               # 縦書きテキスト表示
│       │   ├── CategoryChip.swift               # カテゴリ選択チップ
│       │   ├── LikeButton.swift                 # いいねボタン
│       │   ├── LoadingView.swift                # ローディング表示
│       │   ├── ErrorView.swift                  # エラー表示
│       │   └── EmptyStateView.swift             # 空データ表示
│       ├── Extensions/
│       │   ├── Color+App.swift                  # アプリ共通カラー定義
│       │   ├── Font+App.swift                   # アプリ共通フォント定義
│       │   └── Date+Formatting.swift            # 日付フォーマット
│       ├── Model/
│       │   ├── Tanka.swift                      # 短歌モデル
│       │   ├── WorryCategory.swift              # 悩みカテゴリ enum
│       │   ├── ReportReason.swift               # 通報理由 enum
│       │   ├── BlockedUser.swift                # ブロックユーザーモデル
│       │   └── AppTab.swift                     # タブ定義 enum
│       ├── Repository/
│       │   ├── TankaRepositoryProtocol.swift    # 短歌 Repository Protocol
│       │   └── TankaRepository.swift            # 短歌 Repository 実装
│       ├── Networking/
│       │   ├── APIClient.swift                  # Firebase Cloud Functions クライアント
│       │   └── NetworkError.swift               # ネットワークエラー型
│       ├── Error/
│       │   └── AppError.swift                   # アプリ共通エラー型
│       └── Navigation/
│           └── FeedRoute.swift                  # フィードタブのルート定義
├── Tests/
│   ├── Feed/
│   │   └── FeedViewModelTests.swift             # フィード ViewModel テスト
│   ├── Compose/
│   │   └── ComposeViewModelTests.swift          # 悩み入力 ViewModel テスト
│   ├── TankaResult/
│   │   └── TankaResultViewModelTests.swift      # 短歌生成 ViewModel テスト
│   ├── MyTanka/
│   │   └── MyTankaViewModelTests.swift          # マイ短歌 ViewModel テスト
│   ├── Settings/
│   │   └── BlockListViewModelTests.swift        # ブロックリスト ViewModel テスト
│   ├── Report/
│   │   └── ReportViewModelTests.swift           # 通報 ViewModel テスト
│   └── Mock/
│       └── MockTankaRepository.swift            # 共通 Mock Repository
```

## 2. Feature Module 一覧

| # | Feature | 画面 | ViewModel | 主要 Model |
|---|---|---|---|---|
| 1 | Feed | FeedView, FeedNavigationView | FeedViewModel | Tanka, FeedResponse |
| 2 | Compose | ComposeView | ComposeViewModel | GenerateTankaRequest, WorryCategory |
| 3 | TankaResult | TankaResultView | TankaResultViewModel | Tanka |
| 4 | MyTanka | MyTankaView, MyTankaNavigationView | MyTankaViewModel | Tanka |
| 5 | Settings | SettingsView, BlockListView, AccountDeleteView, SettingsNavigationView | SettingsViewModel, BlockListViewModel | BlockedUser |
| 6 | Report | ReportSheet | ReportViewModel | ReportReason |

## 3. XcodeGen 設定（project.yml）

### 現在の project.yml との差分

現在の `project.yml` からの主な変更点:

| 項目 | 現在 | 変更後 |
|---|---|---|
| SWIFT_VERSION | "6.0" | "6.2" |
| dependencies | なし | Firebase iOS SDK |
| sources (App) | Sources/App, Sources/Features | Sources/App, Sources/Features, Sources/Shared |

### 更新後の project.yml

```yaml
name: App
options:
  bundleIdPrefix: com.example
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "16.0"
  groupSortPosition: top
  generateEmptyDirectories: true

settings:
  base:
    SWIFT_VERSION: "6.2"
    SWIFT_STRICT_CONCURRENCY: complete

packages:
  Firebase:
    url: https://github.com/firebase/firebase-ios-sdk
    from: "11.0.0"

targets:
  App:
    type: application
    platform: iOS
    sources:
      - path: Sources/App
      - path: Sources/Features
      - path: Sources/Shared
    settings:
      base:
        INFOPLIST_FILE: Sources/App/Info.plist
        PRODUCT_BUNDLE_IDENTIFIER: com.example.kokorouta
        MARKETING_VERSION: "1.0.0"
        CURRENT_PROJECT_VERSION: "1"
    dependencies:
      - package: Firebase
        product: FirebaseAuth
      - package: Firebase
        product: FirebaseFirestore
      - package: Firebase
        product: FirebaseFunctions

  AppTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: Tests
    dependencies:
      - target: App
    settings:
      base:
        BUNDLE_LOADER: "$(TEST_HOST)"
        TEST_HOST: "$(BUILT_PRODUCTS_DIR)/App.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/App"
```

## 4. ファイル命名規則

| レイヤー | パターン | 例 |
|---|---|---|
| View | `<Feature>View.swift` | `FeedView.swift`, `ComposeView.swift` |
| ナビゲーション View | `<Feature>NavigationView.swift` | `FeedNavigationView.swift` |
| ViewModel | `<Feature>ViewModel.swift` | `FeedViewModel.swift` |
| Model | `<ModelName>.swift` | `Tanka.swift`, `WorryCategory.swift` |
| Repository Protocol | `<Domain>RepositoryProtocol.swift` | `TankaRepositoryProtocol.swift` |
| Repository 実装 | `<Domain>Repository.swift` | `TankaRepository.swift` |
| Mock | `Mock<Domain>Repository.swift` | `MockTankaRepository.swift` |
| テスト | `<Feature>ViewModelTests.swift` | `FeedViewModelTests.swift` |
| 共通コンポーネント | `<ComponentName>.swift` | `TankaCard.swift`, `VerticalText.swift` |
| Extension | `<Type>+<Purpose>.swift` | `Color+App.swift`, `Font+App.swift` |
| エラー型 | `<Scope>Error.swift` | `AppError.swift`, `NetworkError.swift` |
| ルート定義 | `<Tab>Route.swift` | `FeedRoute.swift` |
