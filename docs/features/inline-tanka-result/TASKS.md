# タスクリスト: 短歌生成結果の同一画面内アニメーション表示

> Issue: #16
> 生成日時: 2026-02-27
> ステータス: Draft
> 入力: REQUIREMENTS.md, DESIGN.md

## タスク一覧

### Phase 1: モデル・ViewModel の変更

- [ ] **T1: ComposePhase enum を定義する**
  - ファイル: `Sources/Features/Feed/ViewModel/ComposeViewModel.swift`
  - `ComposePhase` enum（`.input`, `.loading`, `.result(Tanka)`, `.error(AppError)`）を追加
  - ヘルパープロパティ（`isInput`, `isRateLimited`）を追加

- [ ] **T2: ComposeViewModel に生成ロジックを追加する**
  - ファイル: `Sources/Features/Feed/ViewModel/ComposeViewModel.swift`
  - `tankaRepository` 依存を追加（コンストラクタインジェクション）
  - `submitTanka()` async メソッドを追加（phase 遷移 + API 呼び出し）
  - `retry()` async メソッドを追加
  - `generatedTanka` プロパティを追加

### Phase 2: 新規コンポーネント作成

- [ ] **T3: AnimatedVerticalText コンポーネントを作成する**
  - ファイル: `Sources/Shared/Components/AnimatedVerticalText.swift`（新規）
  - 既存 `VerticalText` のロジックを踏襲
  - 句ごとのフェードインアニメーション（opacity + offset）
  - 右→左の読み順で句が順番に出現
  - `phraseDelay` パラメータで間隔調整可能
  - `accessibilityReduceMotion` 対応

### Phase 3: View の変更

- [ ] **T4: ComposeView を phase 対応に変更する**
  - ファイル: `Sources/Features/Feed/View/ComposeView.swift`
  - `@Binding hasReachedDailyLimit` を追加
  - `@Environment(\.tankaRepository)` を追加し ViewModel に注入
  - phase に応じた表示切り替え（input / loading / result / error）
  - 結果表示に TankaCard + ShareButton + 「フィードに戻る」ボタンを配置
  - 結果表示の TankaCard は裏面（短歌テキスト）を初期表示にする
  - submit ボタンで `viewModel.submitTanka()` を呼ぶ（ナビゲーション遷移を廃止）
  - フェーズ遷移時に `withAnimation` でアニメーションを適用
  - `hasReachedDailyLimit` を result/rateLimited 時に true に設定

- [ ] **T5: FeedNavigationView を更新する**
  - ファイル: `Sources/Features/Feed/View/FeedNavigationView.swift`
  - `ComposeView` に `hasReachedDailyLimit` Binding を渡す
  - `.tankaResult` ケースの navigationDestination を削除

- [ ] **T6: FeedRoute から `.tankaResult` を削除する**
  - ファイル: `Sources/Shared/Navigation/FeedRoute.swift`
  - `.tankaResult(category:worryText:)` ケースを削除

### Phase 4: 不要ファイル削除

- [ ] **T7: TankaResultView を削除する**
  - ファイル: `Sources/Features/Feed/View/TankaResultView.swift`（削除）
  - Xcode プロジェクトからも除外

- [ ] **T8: TankaResultViewModel を削除する**
  - ファイル: `Sources/Features/Feed/ViewModel/TankaResultViewModel.swift`（削除）
  - Xcode プロジェクトからも除外

### Phase 5: 検証

- [ ] **T9: ビルド検証**
  - 全ファイルの構文・型チェック
  - ビルドが通ることを確認

## 依存関係

```
T1 → T2 → T4
T3 → T4
T4 → T5 → T6 → T7, T8
T7, T8 → T9
```
