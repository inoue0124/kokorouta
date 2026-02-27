# タスクリスト: サーバー側悩み入力バリデーション

> Issue: #19
> 生成日時: 2026-02-27
> 入力: docs/features/server-validation/DESIGN.md

## タスク一覧

### サーバー側

- [ ] T-1: `generateTanka.ts` に静的バリデーション関数 `validateWorryText` を追加する
  - 対象: `functions/src/generateTanka.ts`
  - 内容: 最低文字数(10)、最大文字数(300)、同一文字繰り返し(70%)チェックを日次制限チェックの前に配置
  - 既存の空文字チェックを `validateWorryText` に統合

- [ ] T-2: OpenAI プロンプトを JSON レスポンス形式に変更する
  - 対象: `functions/src/generateTanka.ts`
  - 内容: system プロンプトに `isValidInput` + `tankaText` の JSON 形式を指示
  - `response_format: { type: "json_object" }` を OpenAI API パラメータに追加

- [ ] T-3: AI 品質判定のレスポンスパース処理を追加する
  - 対象: `functions/src/generateTanka.ts`
  - 内容: JSON パース、`isValidInput: false` 時のエラーハンドリング、フォールバック処理

### iOS 側 - エラーハンドリング

- [ ] T-4: `NetworkError` に `invalidArgument(message:)` ケースを追加する
  - 対象: `Sources/Shared/Networking/NetworkError.swift`

- [ ] T-5: `APIClient.mapError` に `invalidArgument` のマッピングを追加する
  - 対象: `Sources/Shared/Networking/APIClient.swift`
  - 内容: `FunctionsErrorCode.invalidArgument` → `NetworkError.invalidArgument(message:)`

- [ ] T-6: `AppError` で `invalidArgument` を `.validation(message)` にマッピングする
  - 対象: `Sources/Shared/Error/AppError.swift`
  - 内容: `init(_ error:)` に `NetworkError.invalidArgument` のケースを追加

### iOS 側 - UI

- [ ] T-7: `TankaResultView` にバリデーションエラー時の UI を追加する
  - 対象: `Sources/Features/Feed/View/TankaResultView.swift`
  - 内容: `.validation` エラー時に `validationErrorContent` を表示（エラーメッセージ + 「戻って修正する」ボタン）

- [ ] T-8: `ComposeView` / `ComposeViewModel` の文字数上限を 300 に変更する
  - 対象: `Sources/Features/Feed/View/ComposeView.swift`, `Sources/Features/Feed/ViewModel/ComposeViewModel.swift`
  - 内容: TextEditor 制限 200→300、カウント表示 `/300`、`isValid` 上限 300

### テスト

- [ ] T-9: `TankaResultViewModelTests` にバリデーションエラーのテストを追加する
  - 対象: `Tests/Features/Feed/TankaResultViewModelTests.swift`
  - 内容: `NetworkError.invalidArgument` スロー時に `AppError.validation` が設定されることを検証

- [ ] T-10: `ComposeViewModelTests` の文字数上限テストを更新する
  - 対象: `Tests/Features/Feed/ComposeViewModelTests.swift`
  - 内容: 300 文字での有効性テストを追加・更新
