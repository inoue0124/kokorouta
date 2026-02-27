# スペック駆動開発プラグイン仕様書

## 概要

ios-claude-plugins マーケットプレイスに、スペック駆動開発ワークフローを実現する **1つのプラグイン（`spec-driven-dev`）** を追加する。
プラグインは6つのスキルを持ち、各スキルが対応するドキュメントを `docs/` 配下に生成する。

ワークフローは Step 1 → 6 の順に実行される。Step 1 のみユーザー承認を挟み、Step 2〜6 は前ステップの出力を入力として自動的に生成する。

## 対象プロジェクトの前提

| 項目 | 値 |
|---|---|
| 言語 | Swift 6.2 |
| UI | SwiftUI |
| アーキテクチャ | MVVM（View → ViewModel → Repository → Model） |
| 状態管理 | `@Observable`（Observation フレームワーク） |
| 並行処理 | Swift Concurrency（async/await, Sendable） |
| プロジェクト生成 | XcodeGen（`project.yml`） |
| Lint / Format | SwiftLint / SwiftFormat（Mint 管理） |
| CI / CD | Fastlane + GitHub Actions |
| 最小デプロイメント | iOS 17.0 |

## ディレクトリ構造（出力先）

```
docs/
├── ideas/                      # ユーザーが事前に置くアイデアメモ（入力）
├── product-requirements.md     # Step 1 で生成
├── functional-design.md        # Step 2 で生成
├── architecture.md             # Step 3 で生成
├── repository-structure.md     # Step 4 で生成
├── development-guidelines.md   # Step 5 で生成
├── glossary.md                 # Step 6 で生成
└── features/                   # 個別フィーチャーの実装スペック（別プラグイン）
```

---

## プラグイン構成

```
plugins/spec-driven-dev/
├── .claude-plugin/
│   └── plugin.json
└── skills/
    ├── prd-writing/
    │   ├── skill.md
    │   └── references/
    │       └── TEMPLATE.md
    ├── functional-design/
    │   ├── skill.md
    │   └── references/
    │       └── TEMPLATE.md
    ├── architecture-design/
    │   ├── skill.md
    │   └── references/
    │       └── TEMPLATE.md
    ├── repository-structure/
    │   ├── skill.md
    │   └── references/
    │       └── TEMPLATE.md
    ├── development-guidelines/
    │   ├── skill.md
    │   └── references/
    │       └── TEMPLATE.md
    └── glossary-gen/
        ├── skill.md
        └── references/
            └── TEMPLATE.md
```

### plugin.json

```json
{
  "name": "spec-driven-dev",
  "version": "0.1.0",
  "description": "スペック駆動開発ワークフロー — PRD・機能設計・アーキテクチャ・リポジトリ構造・開発ガイドライン・用語集を段階的に生成する",
  "skills": [
    {
      "name": "prd-writing",
      "description": "docs/ideas/ を元にプロダクト要求定義書（docs/product-requirements.md）を作成する",
      "path": "./skills/prd-writing"
    },
    {
      "name": "functional-design",
      "description": "プロダクト要求定義書を元に機能設計書（docs/functional-design.md）を作成する",
      "path": "./skills/functional-design"
    },
    {
      "name": "architecture-design",
      "description": "既存ドキュメントを元にアーキテクチャ設計書（docs/architecture.md）を作成する",
      "path": "./skills/architecture-design"
    },
    {
      "name": "repository-structure",
      "description": "既存ドキュメントを元にリポジトリ構造定義書（docs/repository-structure.md）を作成する",
      "path": "./skills/repository-structure"
    },
    {
      "name": "development-guidelines",
      "description": "既存ドキュメントを元に開発ガイドライン（docs/development-guidelines.md）を作成する",
      "path": "./skills/development-guidelines"
    },
    {
      "name": "glossary-gen",
      "description": "全ドキュメントから用語を抽出し用語集（docs/glossary.md）を作成する",
      "path": "./skills/glossary-gen"
    }
  ]
}
```

---

## スキル仕様

### Skill 1: prd-writing

| 項目 | 内容 |
|---|---|
| スキル名 | `/prd-writing` |
| 入力 | `docs/ideas/` 配下のファイル群 |
| 出力 | `docs/product-requirements.md` |
| ユーザー承認 | **必要**（承認されるまで待機） |

#### 生成内容

1. **プロダクト概要** — アプリの目的、ターゲットユーザー、解決する課題
2. **ユーザーストーリー一覧** — 「〜として、〜したい、なぜなら〜」形式。MoSCoW 優先度（Must / Should / Could / Won't）付き
3. **画面フロー** — Mermaid 図で画面遷移を可視化
4. **機能要件** — 画面ごとの入力・処理・出力
5. **非機能要件** — パフォーマンス、アクセシビリティ、オフライン対応、セキュリティ、ローカライゼーション
6. **外部依存** — API エンドポイント（メソッド・パス・概要）、サードパーティ SDK
7. **受け入れ条件** — 具体的・検証可能な条件。検証方法を明記
8. **成功指標** — KPI（定量的な目標値）
9. **スコープ外** — 明示的に含めない項目

#### スキルの振る舞い

- `docs/ideas/` が空または存在しない場合、ユーザーにヒアリングしてアイデアを引き出す
- 生成後「この内容でよいですか？」とユーザーに確認を求める
- ユーザーがフィードバックを返した場合、修正して再度確認を求める
- 承認されたら `docs/product-requirements.md` を確定する

---

### Skill 2: functional-design

| 項目 | 内容 |
|---|---|
| スキル名 | `/functional-design` |
| 入力 | `docs/product-requirements.md` |
| 出力 | `docs/functional-design.md` |
| ユーザー承認 | 不要（自動生成） |

#### 生成内容

1. **画面一覧** — 画面名・概要・主要コンポーネントの表
2. **画面詳細仕様** — 画面ごとに以下を記述:
   - レイアウト構成（コンポーネント階層）
   - 状態一覧（state / binding / computed）
   - ユーザーインタラクション（アクション → 結果）
   - エラー状態とその表示
3. **画面遷移仕様** — Mermaid state diagram で遷移を定義。遷移トリガーと渡すパラメータ
4. **データモデル一覧** — エンティティ名・プロパティ・型・制約。エンティティ間の関連図
5. **API インターフェース仕様** — エンドポイントごとのリクエスト / レスポンス定義（型名まで）
6. **共通コンポーネント** — 再利用可能な UI コンポーネントの仕様

#### スキルの振る舞い

- `docs/product-requirements.md` が存在しない場合はエラーメッセージを出して終了
- プロダクト要求定義書のユーザーストーリーと受け入れ条件を全て網羅するよう生成する

---

### Skill 3: architecture-design

| 項目 | 内容 |
|---|---|
| スキル名 | `/architecture-design` |
| 入力 | `docs/product-requirements.md`, `docs/functional-design.md` |
| 出力 | `docs/architecture.md` |
| ユーザー承認 | 不要（自動生成） |

#### 生成内容

1. **アーキテクチャ概要** — レイヤー図（View → ViewModel → Repository → Model）と各レイヤーの責務
2. **技術スタック** — Swift 6.2, SwiftUI, Observation, Swift Concurrency, XcodeGen 等の選定理由
3. **レイヤー設計**
   - **View 層**: SwiftUI View の設計方針。`@State` で ViewModel を保持、`@Environment` で DI
   - **ViewModel 層**: `@Observable class`。状態プロパティ、アクションメソッド（`async`）、エラーハンドリング
   - **Repository 層**: Protocol（`Sendable`）+ 具象実装。`async throws` メソッド
   - **Model 層**: `Codable, Sendable, Identifiable` 準拠の struct
4. **DI 戦略** — `@Environment` + `EnvironmentKey` パターン。`@EnvironmentObject` は使わない
5. **ナビゲーション設計** — `NavigationStack` + `navigationDestination`。Route enum（`Hashable`）
6. **エラーハンドリング方針** — ネットワーク・バリデーション・認証・不明エラーの分類と UI 表現
7. **データフロー図** — Mermaid sequence diagram でユーザー操作 → View → ViewModel → Repository → API の流れ
8. **テスト戦略** — ViewModel / Repository のユニットテスト方針。Mock の作り方

#### スキルの振る舞い

- プロジェクトの `CLAUDE.md` も読み、既存の規約と矛盾しないようにする
- 入力ドキュメントが不足している場合はエラーメッセージを出して終了

---

### Skill 4: repository-structure

| 項目 | 内容 |
|---|---|
| スキル名 | `/repository-structure` |
| 入力 | `docs/product-requirements.md`, `docs/functional-design.md`, `docs/architecture.md` |
| 出力 | `docs/repository-structure.md` |
| ユーザー承認 | 不要（自動生成） |

#### 生成内容

1. **ディレクトリツリー** — 全ファイル・フォルダを tree 形式で表示。各ファイルに1行コメント
   ```
   Sources/
   ├── App/
   │   ├── App.swift                    # アプリエントリポイント
   │   └── ContentView.swift            # ルートナビゲーション
   └── Features/
       ├── <FeatureName>/
       │   ├── View/
       │   │   ├── <FeatureName>View.swift
       │   │   └── Components/
       │   ├── ViewModel/
       │   │   └── <FeatureName>ViewModel.swift
       │   ├── Model/
       │   │   └── <ModelName>.swift
       │   └── Repository/
       │       ├── <FeatureName>RepositoryProtocol.swift
       │       └── <FeatureName>Repository.swift
       └── Shared/
           ├── Components/              # 共通 UI コンポーネント
           ├── Extensions/              # Swift 拡張
           ├── Networking/              # API クライアント
           └── DI/                      # 依存注入ヘルパー
   Tests/
   └── <FeatureName>/
       ├── <FeatureName>ViewModelTests.swift
       └── Mock<FeatureName>Repository.swift
   ```
2. **XcodeGen 設定** — `project.yml` に追加すべき targets / sources / dependencies
3. **ファイル命名規則** — 各レイヤーの命名パターン一覧

#### スキルの振る舞い

- 機能設計書の画面一覧とデータモデルから、必要な Feature Module を全て列挙する
- 既存の `project.yml` を読み、現在の構成との差分を明示する

---

### Skill 5: development-guidelines

| 項目 | 内容 |
|---|---|
| スキル名 | `/development-guidelines` |
| 入力 | `docs/product-requirements.md`, `docs/architecture.md`, `docs/repository-structure.md`, `CLAUDE.md` |
| 出力 | `docs/development-guidelines.md` |
| ユーザー承認 | 不要（自動生成） |

#### 生成内容

1. **コーディング規約**
   - 命名規則（Swift API Design Guidelines 準拠）
   - ファイル構成（1ファイル1型）
   - アクセスコントロールの方針
   - SwiftLint / SwiftFormat ルールの補足説明
2. **実装パターン集** — 各レイヤーのコードテンプレート:
   - View: `@State private var viewModel` パターン
   - ViewModel: `@Observable class` + `async` action パターン
   - Repository: Protocol + 具象 + Mock パターン
   - Model: `Codable, Sendable, Identifiable` struct パターン
   - DI: `EnvironmentKey` パターン
   - Navigation: Route enum + `NavigationStack` パターン
3. **禁止パターン** — 使ってはいけない API とその理由
   - `ObservableObject` / `@Published` → `@Observable` を使う
   - `@StateObject` / `@ObservedObject` → `@State` を使う
   - `@EnvironmentObject` → `@Environment` を使う
   - `DispatchQueue` → Swift Concurrency を使う
4. **Git ワークフロー** — ブランチ戦略、Conventional Commits、PR テンプレート
5. **テストガイドライン** — テスト命名規則、Mock の作り方、カバレッジ基準

#### スキルの振る舞い

- `CLAUDE.md` の内容と矛盾しないこと。CLAUDE.md の規約を詳細化・補足する位置づけ
- 入力ドキュメントが不足している場合はエラーメッセージを出して終了

---

### Skill 6: glossary-gen

| 項目 | 内容 |
|---|---|
| スキル名 | `/glossary-gen` |
| 入力 | `docs/` 配下の全ドキュメント（Step 1〜5 の出力） |
| 出力 | `docs/glossary.md` |
| ユーザー承認 | 不要（自動生成） |

#### 生成内容

1. **ドメイン用語** — ビジネスドメイン固有の用語（日本語 / 英語 / 定義 / 使用箇所）
2. **技術用語** — プロジェクトで使う技術用語とその文脈での意味
3. **略語** — 略語とその正式名称
4. **命名マッピング** — ドメイン用語 → コード上の命名（クラス名・変数名）の対応表

#### テーブル形式

```markdown
| 用語（日本語） | 用語（英語） | 定義 | コード上の命名 |
|---|---|---|---|
| 商品 | Product | 販売対象のアイテム | `Product`, `ProductRepository` |
```

#### スキルの振る舞い

- Step 1〜5 の全ドキュメントをスキャンし、用語を自動抽出する
- 入力ドキュメントが不足している場合はエラーメッセージを出して終了

---

## 共通仕様

### エラーハンドリング

- 必要な入力ドキュメントが存在しない場合、「`docs/xxx.md` が見つかりません。先に `/yyy` を実行してください。」とエラーを出して終了する
- 部分的に存在する場合は、存在するドキュメントのみを使って生成する（ただし警告を出す）

### 出力規約

- 全ドキュメントは日本語で記述する
- Mermaid 図を積極的に使う（画面遷移、データフロー、レイヤー図）
- コード例は Swift で記述し、プロジェクトの規約（Swift 6.2, @Observable 等）に準拠する
- 各ドキュメントの冒頭に生成日時とステータス（Draft / Approved）を記載する

---

## ワークフロー全体像

```
docs/ideas/ (ユーザーの入力)
    │
    ▼
Step 1: /prd-writing ──→ docs/product-requirements.md
    │                          ↑ ユーザー承認
    ▼
Step 2: /functional-design ──→ docs/functional-design.md
    │
    ▼
Step 3: /architecture-design ──→ docs/architecture.md
    │
    ▼
Step 4: /repository-structure ──→ docs/repository-structure.md
    │
    ▼
Step 5: /development-guidelines ──→ docs/development-guidelines.md
    │
    ▼
Step 6: /glossary-gen ──→ docs/glossary.md
    │
    ▼
Feature 実装へ（/implement-feature）
```
