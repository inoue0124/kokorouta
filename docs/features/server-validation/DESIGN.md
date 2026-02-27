# 詳細設計書: サーバー側悩み入力バリデーション

> Issue: #19
> 生成日時: 2026-02-27
> ステータス: Draft
> 入力: docs/features/server-validation/REQUIREMENTS.md

## 1. 変更対象ファイル一覧

### サーバー側（Cloud Functions）

| ファイル | 変更内容 |
|---|---|
| `functions/src/generateTanka.ts` | バリデーションロジック追加、AI プロンプト修正、品質判定処理追加 |

### iOS 側

| ファイル | 変更内容 |
|---|---|
| `Sources/Shared/Networking/NetworkError.swift` | `invalidArgument(message:)` ケース追加 |
| `Sources/Shared/Networking/APIClient.swift` | `invalid-argument` エラーコードのマッピング追加 |
| `Sources/Shared/Error/AppError.swift` | `invalidArgument` → `.validation(message)` マッピング追加 |
| `Sources/Features/Feed/View/TankaResultView.swift` | バリデーションエラー時の UI（戻って修正するボタン）追加 |
| `Sources/Features/Feed/View/ComposeView.swift` | 文字数上限 200 → 300 に変更 |
| `Sources/Features/Feed/ViewModel/ComposeViewModel.swift` | `isValid` の最大文字数を 300 に変更 |

### テスト

| ファイル | 変更内容 |
|---|---|
| `Tests/Features/Feed/TankaResultViewModelTests.swift` | バリデーションエラー時のテスト追加 |
| `Tests/Features/Feed/ComposeViewModelTests.swift` | 文字数上限 300 のテスト更新 |

## 2. サーバー側設計

### 2.1 静的バリデーション（generateTanka.ts）

既存のカテゴリ・空文字バリデーションの直後、日次制限チェックの **前** に配置する。

```typescript
// 実行順序:
// 1. 認証チェック（既存）
// 2. カテゴリバリデーション（既存）
// 3. 空文字チェック（既存）
// 4. ★ 静的バリデーション（新規: 文字数・同一文字繰り返し）
// 5. 日次制限チェック（既存）
// 6. OpenAI API 呼び出し（既存）
// 7. ★ AI 品質判定チェック（新規）
// 8. Firestore 保存（既存）
```

#### バリデーション関数

```typescript
function validateWorryText(text: string): void {
  const trimmed = text.trim();

  // V-4: 空白のみ（既存ロジックを統合）
  if (trimmed.length === 0) {
    throw new HttpsError("invalid-argument", "悩みのテキストを入力してください。");
  }

  // V-1: 最低文字数
  if (trimmed.length < 10) {
    throw new HttpsError("invalid-argument", "もう少し詳しく悩みを書いてください。");
  }

  // V-2: 最大文字数
  if (trimmed.length > 300) {
    throw new HttpsError("invalid-argument", "悩みは300文字以内で入力してください。");
  }

  // V-3: 同一文字繰り返し
  const charFrequency = new Map<string, number>();
  for (const char of trimmed) {
    charFrequency.set(char, (charFrequency.get(char) || 0) + 1);
  }
  const maxFrequency = Math.max(...charFrequency.values());
  if (maxFrequency / trimmed.length >= 0.7) {
    throw new HttpsError("invalid-argument", "悩みの内容を具体的に書いてください。");
  }
}
```

### 2.2 AI 品質判定（generateTanka.ts）

OpenAI プロンプトを修正し、JSON 形式でレスポンスを返させる。

#### プロンプト変更

**system プロンプト（変更後）:**
```
あなたは日本の短歌の名人です。ユーザーの悩みに寄り添い、心を癒す美しい短歌（五七五七七の31音）を一首だけ詠んでください。

以下の JSON 形式で返答してください:
{
  "isValidInput": true または false,
  "tankaText": "五文字 七文字 五文字 七文字 七文字"
}

isValidInput の判定基準:
- 意味のある日本語の悩み・相談であれば true
- 意味不明な文字列、テスト入力、悩みと無関係な内容であれば false

isValidInput が false の場合、tankaText は空文字にしてください。
isValidInput が true の場合、各句の間にはスペースを入れてください。
```

#### レスポンスパース

```typescript
const content = completion.choices[0]?.message?.content?.trim();
if (!content) {
  throw new HttpsError("internal", "短歌の生成に失敗しました。もう一度お試しください。");
}

let parsed: { isValidInput: boolean; tankaText: string };
try {
  parsed = JSON.parse(content);
} catch {
  // JSON パース失敗時はフォールバック（従来の文字列レスポンスとして扱う）
  parsed = { isValidInput: true, tankaText: content };
}

if (!parsed.isValidInput) {
  throw new HttpsError("invalid-argument", "悩みの内容をもう少し具体的に書いてください。");
}

const tankaText = parsed.tankaText?.trim();
if (!tankaText) {
  throw new HttpsError("internal", "短歌の生成に失敗しました。もう一度お試しください。");
}
```

## 3. iOS 側設計

### 3.1 NetworkError 変更

```swift
enum NetworkError: Error, Sendable {
    case noConnection
    case timeout
    case serverError(statusCode: Int)
    case decodingError
    case unauthorized
    case rateLimited
    case invalidArgument(message: String)  // 新規追加
}
```

### 3.2 APIClient.mapError 変更

`invalid-argument` エラーコードを処理する。Firebase Functions の `invalid-argument` は `FunctionsErrorCode.invalidArgument` に対応する。エラーメッセージはサーバーから返される日本語メッセージをそのまま使う。

```swift
private func mapError(_ error: NSError) -> NetworkError {
    switch error.code {
    case FunctionsErrorCode.invalidArgument.rawValue:
        let message = error.localizedDescription
        return .invalidArgument(message: message)
    case FunctionsErrorCode.unauthenticated.rawValue:
        .unauthorized
    // ... 既存のケース
    }
}
```

### 3.3 AppError 変更

`NetworkError.invalidArgument` を `.validation(message)` にマッピングする。

```swift
init(_ error: Error) {
    if let networkError = error as? NetworkError {
        switch networkError {
        case .rateLimited:
            self = .rateLimited(nextAvailableAt: ...)
        case .invalidArgument(let message):
            self = .validation(message)
        default:
            self = .network(networkError)
        }
    }
    // ...
}
```

### 3.4 TankaResultView 変更

バリデーションエラー時に「戻って修正する」ボタンを表示する。既存の `ErrorView`（リトライボタン付き）の代わりに、バリデーションエラー専用の表示を行う。

```swift
} else if let error = viewModel.error {
    if case .rateLimited = error {
        rateLimitedContent(error: error)
    } else if case .validation = error {
        validationErrorContent(error: error)  // 新規
    } else {
        ErrorView(error: error) { ... }
    }
}
```

**validationErrorContent**: エラーメッセージ + 「戻って修正する」ボタン（`path.removeLast()` で ComposeView に戻る）

### 3.5 ComposeView / ComposeViewModel 変更

文字数上限を 200 → 300 に変更する。

- `ComposeView`: `onChange` で 300 文字制限、カウント表示 `\(count)/300`
- `ComposeViewModel`: `isValid` の `characterCount <= 300` に変更

## 4. エラーフロー図

```
ユーザー入力
    │
    ▼
[クライアント側バリデーション]
    │ カテゴリ未選択・10文字未満 → ボタン無効化
    │ 300文字超 → 入力不可（TextEditor制限）
    │
    ▼ 送信
[サーバー: 認証チェック]
    │
    ▼
[サーバー: カテゴリバリデーション]
    │
    ▼
[サーバー: 静的バリデーション] ←── 新規
    │ 10文字未満 → invalid-argument
    │ 300文字超 → invalid-argument
    │ 同一文字70% → invalid-argument
    │
    ▼
[サーバー: 日次制限チェック]
    │ 制限超過 → resource-exhausted
    │
    ▼
[サーバー: OpenAI API 呼び出し]
    │
    ▼
[サーバー: AI 品質判定] ←── 新規
    │ isValidInput: false → invalid-argument
    │
    ▼
[サーバー: Firestore 保存]
    │
    ▼
クライアント: 短歌表示
```
