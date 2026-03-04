# EULA 同意機能 詳細設計書

> Issue: #81
> 生成日時: 2026-03-04
> ステータス: Draft
> 入力: REQUIREMENTS.md, docs/architecture.md

## 1. 概要

EULA 同意画面を新規 Feature Module として実装し、App.swift の起動フローに組み込む。

## 2. アーキテクチャ

### レイヤー構成

```
Sources/Features/EULA/
├── View/
│   ├── EULAAgreementView.swift      # EULA 同意画面（初回起動時）
│   └── EULAContentView.swift        # EULA 全文閲覧画面（設定画面から）
├── ViewModel/
│   └── EULAAgreementViewModel.swift # 同意状態管理
└── Model/
    └── EULAContent.swift            # EULA 文面定義
```

### 依存方向

```
App.swift → EULAAgreementView → EULAAgreementViewModel → UserDefaults (@AppStorage)
SettingsView → EULAContentView（閲覧のみ）
```

## 3. 画面設計

### 3.1 EULA 同意画面（EULAAgreementView）

```
VStack
├── Text ("利用規約")                    # タイトル
├── ScrollView
│   └── Text (EULA 全文)                # Markdown 風テキスト
├── Button ("同意して始める")            # 同意ボタン
└── Text ("同意しない場合はアプリを利用できません")  # 注意書き
```

**表示条件:** `@AppStorage("hasAgreedToEULA")` が `false` の場合

### 3.2 EULA 閲覧画面（EULAContentView）

```
NavigationStack
└── ScrollView
    └── Text (EULA 全文)
```

設定画面からの遷移用。同意ボタンなし。

## 4. 型設計

### EULAAgreementViewModel

```swift
@Observable
@MainActor
final class EULAAgreementViewModel {
    private(set) var isAgreed = false

    func agree() {
        UserDefaults.standard.set(true, forKey: "hasAgreedToEULA")
        isAgreed = true
    }
}
```

### EULAContent

```swift
enum EULAContent {
    static let fullText: String = """
    ... EULA 全文 ...
    """
}
```

## 5. 起動フロー統合

### App.swift の変更

```
認証完了 → EULA 同意チェック → 未同意 → EULAAgreementView
                              → 同意済 → ContentView
```

App.swift に `@AppStorage("hasAgreedToEULA")` を追加し、分岐を制御する。

### アカウント削除時のリセット

`AccountDeleteViewModel.deleteAccount()` 内で `UserDefaults.standard.removeObject(forKey: "hasAgreedToEULA")` を呼び出す。

## 6. 設定画面の変更

### SettingsRoute に追加

```swift
enum SettingsRoute: Hashable {
    case blockList
    case accountDelete
    case eula          // 追加
}
```

### SettingsView に利用規約リンク追加

「情報」セクションに `NavigationLink(value: .eula)` を追加。

### ContentView に navigationDestination 追加

```swift
case .eula:
    EULAContentView()
```

## 7. EULA 文面の方針

以下を含む日本語の利用規約:

1. **サービスの概要**: 悩みを短歌にするアプリ
2. **利用条件**: 12 歳以上
3. **禁止事項**: 不適切コンテンツ（暴力・差別・性的・違法）、個人情報の投稿、スパム
4. **ゼロトレランスポリシー**: 違反時のアカウント停止・削除
5. **コンテンツの公開**: 投稿は他ユーザーに公開される
6. **通報・ブロック**: 不適切なコンテンツの通報機能あり
7. **免責事項**: AI 生成コンテンツについて
8. **プライバシー**: プライバシーポリシーへの参照
