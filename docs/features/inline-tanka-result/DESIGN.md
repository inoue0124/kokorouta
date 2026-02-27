# 詳細設計書: 短歌生成結果の同一画面内アニメーション表示

> Issue: #16
> 生成日時: 2026-02-27
> ステータス: Draft
> 入力: REQUIREMENTS.md, docs/architecture.md, docs/development-guidelines.md

## 1. 設計概要

### 現在のフロー（ナビゲーション遷移）

```
ComposeView → [path.append(.tankaResult)] → TankaResultView
```

### 変更後のフロー（同一画面内状態遷移）

```
ComposeView 内で:
  .input → .loading → .result / .error
```

## 2. 状態遷移設計

### ComposeViewModel の Phase

```swift
enum ComposePhase {
    case input           // 入力フォーム表示
    case loading         // 生成中（ローディング表示）
    case result(Tanka)   // 結果表示（アニメーション付き）
    case error(AppError) // エラー表示
}
```

### 状態遷移図

```
         ┌──────────┐
         │  input   │ ← 初期状態
         └────┬─────┘
              │ 「短歌を詠む」タップ
              ▼
         ┌──────────┐
         │ loading  │
         └────┬─────┘
              │
         ┌────┴─────┐
         ▼          ▼
   ┌──────────┐ ┌──────────┐
   │  result  │ │  error   │
   └──────────┘ └────┬─────┘
                     │ リトライ
                     ▼
                ┌──────────┐
                │ loading  │
                └──────────┘
```

## 3. ファイル変更一覧

### 変更するファイル

| ファイル | 変更内容 |
|---|---|
| `Sources/Features/Feed/ViewModel/ComposeViewModel.swift` | Phase 管理・生成ロジック追加 |
| `Sources/Features/Feed/View/ComposeView.swift` | Phase に応じた表示切り替え・アニメーション |
| `Sources/Features/Feed/View/FeedNavigationView.swift` | `tankaResult` ルート削除、`hasReachedDailyLimit` を Binding で ComposeView に渡す |
| `Sources/Shared/Navigation/FeedRoute.swift` | `.tankaResult` ケース削除 |

### 削除するファイル

| ファイル | 理由 |
|---|---|
| `Sources/Features/Feed/View/TankaResultView.swift` | ComposeView に統合 |
| `Sources/Features/Feed/ViewModel/TankaResultViewModel.swift` | ComposeViewModel に統合 |

### 新規作成するファイル

| ファイル | 内容 |
|---|---|
| `Sources/Shared/Components/AnimatedVerticalText.swift` | 句ごとフェードインアニメーション付き縦書きテキスト |

## 4. コンポーネント設計

### 4.1 ComposeViewModel（変更）

```swift
@Observable
@MainActor
final class ComposeViewModel {
    // MARK: - State（既存）
    var selectedCategory: WorryCategory?
    var worryText: String = ""

    // MARK: - State（新規）
    private(set) var phase: ComposePhase = .input
    private(set) var generatedTanka: Tanka?

    // MARK: - Dependencies
    private let tankaRepository: any TankaRepositoryProtocol

    // MARK: - Computed（既存）
    var characterCount: Int { worryText.count }
    var isValid: Bool { ... }
    var validationMessage: String? { ... }

    // MARK: - Init
    init(tankaRepository: any TankaRepositoryProtocol = TankaRepository()) {
        self.tankaRepository = tankaRepository
    }

    // MARK: - Actions（既存）
    func selectCategory(_ category: WorryCategory) { ... }

    // MARK: - Actions（新規）
    func submitTanka() async {
        guard let category = selectedCategory else { return }
        phase = .loading
        do {
            let tanka = try await tankaRepository.generateTanka(
                category: category,
                worryText: worryText
            )
            generatedTanka = tanka
            phase = .result(tanka)
        } catch {
            phase = .error(AppError(error))
        }
    }

    func retry() async {
        await submitTanka()
    }

    var isRateLimited: Bool {
        if case .error(let error) = phase,
           case .rateLimited = error {
            return true
        }
        return false
    }
}
```

**設計ポイント:**
- `TankaResultViewModel` の生成ロジックを `ComposeViewModel` に統合
- `phase` で画面の表示状態を一元管理
- `@Environment` 経由で `tankaRepository` を受け取るため、init パラメータで注入

### 4.2 ComposeView（変更）

```swift
struct ComposeView: View {
    @Binding var path: NavigationPath
    @Binding var hasReachedDailyLimit: Bool
    @Environment(\.tankaRepository) private var repository
    @State private var viewModel: ComposeViewModel?
    @FocusState private var isTextEditorFocused: Bool

    var body: some View {
        Group {
            if let viewModel {
                phaseContent(viewModel: viewModel)
            } else {
                LoadingView()
            }
        }
        .background(Color.appBackground)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel?.phase.isInput == false)
        .task {
            if viewModel == nil {
                viewModel = ComposeViewModel(tankaRepository: repository)
            }
        }
    }

    @ViewBuilder
    private func phaseContent(viewModel: ComposeViewModel) -> some View {
        switch viewModel.phase {
        case .input:
            inputContent(viewModel: viewModel)
        case .loading:
            LoadingView(message: "短歌を詠んでいます...")
        case .result(let tanka):
            resultContent(tanka: tanka)
        case .error(let error):
            errorContent(error: error, viewModel: viewModel)
        }
    }
}
```

**設計ポイント:**
- `@Binding var hasReachedDailyLimit` を追加（FeedNavigationView から渡す）
- `phase` に応じて表示を切り替え
- 入力フェーズ以外ではバックボタンを非表示にする

### 4.3 AnimatedVerticalText（新規）

```swift
struct AnimatedVerticalText: View {
    let text: String
    var fontSize: CGFloat = 22
    var font: Font? = nil
    var phraseDelay: Double = 0.4

    @State private var visiblePhraseCount: Int = 0

    var body: some View {
        let phrases = text.components(separatedBy: "\n")
            .flatMap { $0.components(separatedBy: "　") }
            .filter { !$0.isEmpty }
        let reversed = phrases.reversed().map { $0 }

        HStack(alignment: .top, spacing: fontSize * 0.8) {
            ForEach(reversed.indices, id: \.self) { index in
                let phrase = reversed[index]
                // 右から左に表示するので、表示順は reversed.count - 1 - index
                let displayOrder = reversed.count - 1 - index
                let isVisible = displayOrder < visiblePhraseCount

                VStack(spacing: fontSize * 0.2) {
                    ForEach(Array(phrase).indices, id: \.self) { charIndex in
                        Text(String(Array(phrase)[charIndex]))
                            .font(font ?? .tankaFont(size: fontSize))
                            .foregroundStyle(Color.appText)
                    }
                }
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)
                .animation(
                    .easeOut(duration: 0.5)
                        .delay(Double(displayOrder) * phraseDelay),
                    value: visiblePhraseCount
                )
            }
        }
        .onAppear {
            visiblePhraseCount = phrases.count
        }
    }
}
```

**設計ポイント:**
- 既存 `VerticalText` のロジックを踏襲しつつ、句ごとのアニメーションを追加
- `visiblePhraseCount` を 0 → phrases.count に変更することで全句が順番にフェードイン
- 右から左（日本語の縦書き読み順）に句が現れる
- `phraseDelay` でアニメーション間隔を調整可能
- `accessibilityReduceMotion` 対応は呼び出し側で phraseDelay を 0 にする

### 4.4 FeedNavigationView（変更）

```swift
struct FeedNavigationView: View {
    @State private var path = NavigationPath()
    @State private var hasReachedDailyLimit = false

    var body: some View {
        NavigationStack(path: $path) {
            FeedView(path: $path, hasReachedDailyLimit: hasReachedDailyLimit)
                .navigationDestination(for: FeedRoute.self) { route in
                    switch route {
                    case .compose:
                        ComposeView(
                            path: $path,
                            hasReachedDailyLimit: $hasReachedDailyLimit
                        )
                    }
                }
        }
    }
}
```

### 4.5 FeedRoute（変更）

```swift
enum FeedRoute: Hashable {
    case compose
    // .tankaResult を削除
}
```

## 5. アニメーション設計

### 5.1 フェーズ遷移アニメーション

| 遷移 | アニメーション | Duration |
|---|---|---|
| input → loading | 入力フォームがフェードアウト、ローディングがフェードイン | 0.3s |
| loading → result | ローディングがフェードアウト、結果カードがフェードイン | 0.5s |
| loading → error | ローディングがフェードアウト、エラー表示がフェードイン | 0.3s |

### 5.2 短歌テキスト句ごとアニメーション

- 結果カード表示後、短歌テキストの各句が右から左へ順番にフェードイン
- 各句: `opacity: 0→1` + `offset.y: 10→0`
- 句間ディレイ: 0.4 秒
- 全5句で合計約 2.0 秒の演出

### 5.3 アクセシビリティ対応

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

// reduceMotion が true の場合はアニメーションなしで即時表示
.animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: ...)
```

## 6. データフロー

```
ComposeView
  ├── @Binding path: NavigationPath (← FeedNavigationView)
  ├── @Binding hasReachedDailyLimit: Bool (← FeedNavigationView)
  ├── @Environment tankaRepository (← EnvironmentKey)
  └── @State viewModel: ComposeViewModel?
        ├── phase: ComposePhase
        ├── selectedCategory: WorryCategory?
        ├── worryText: String
        ├── generatedTanka: Tanka?
        └── tankaRepository: TankaRepositoryProtocol (via init)
```

## 7. 結果表示のレイアウト

```
┌─────────────────────────────┐
│         （ナビゲーションバー）      │
│                             │
│          [Spacer]           │
│                             │
│    ┌───────────────────┐    │
│    │                   │    │
│    │  AnimatedVertical  │    │
│    │   Text（短歌）     │    │
│    │                   │    │
│    └───────────────────┘    │
│                             │
│  「カードをタップすると      │
│    短歌が読めます」          │
│                             │
│      [ShareButton]          │
│                             │
│          [Spacer]           │
│                             │
│    [フィードに戻る ボタン]    │
│                             │
└─────────────────────────────┘
```

注: 結果表示では `TankaCard`（フリップ付き）を使用する。
`AnimatedVerticalText` は TankaCard の裏面（短歌テキスト側）で初回のみ使用し、
表面（悩みテキスト側）は通常の `VerticalText` を使用する。

→ 初回表示は裏面（短歌テキスト）を先に見せ、タップで表面（悩みテキスト）にフリップする。
