# EULA 同意機能 タスクリスト

> Issue: #81
> 生成日時: 2026-03-04

## タスク

- [ ] **T1: EULA 文面を作成する**
  - `Sources/Features/EULA/Model/EULAContent.swift`
  - Guideline 1.2 要件を満たすゼロトレランスポリシーを含む利用規約テキスト

- [ ] **T2: EULAAgreementViewModel を作成する**
  - `Sources/Features/EULA/ViewModel/EULAAgreementViewModel.swift`
  - `@Observable`, `@MainActor`, UserDefaults による同意状態管理

- [ ] **T3: EULAAgreementView を作成する**
  - `Sources/Features/EULA/View/EULAAgreementView.swift`
  - EULA 全文表示 + 「同意して始める」ボタン

- [ ] **T4: EULAContentView を作成する**
  - `Sources/Features/EULA/View/EULAContentView.swift`
  - 設定画面からの閲覧用（同意ボタンなし）

- [ ] **T5: App.swift に EULA 同意チェックを統合する**
  - `@AppStorage("hasAgreedToEULA")` で分岐
  - 認証完了後、未同意なら EULAAgreementView を表示

- [ ] **T6: アカウント削除時に同意状態をリセットする**
  - `AccountDeleteViewModel.deleteAccount()` に UserDefaults リセット追加

- [ ] **T7: 設定画面に利用規約リンクを追加する**
  - `SettingsRoute` に `.eula` 追加
  - `SettingsView` の「情報」セクションにリンク追加
  - `ContentView` に `.eula` の `navigationDestination` 追加

- [ ] **T8: ビルド検証**
  - 構文チェック・ビルド確認
