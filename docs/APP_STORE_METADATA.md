# App Store 審査用メタデータ

## 基本情報

- **アプリ名**: こころうた
- **サブタイトル**: 悩みに寄り添うAI短歌
- **バンドル ID**: com.carriage.kokorouta
- **カテゴリ（プライマリ）**: ライフスタイル
- **カテゴリ（セカンダリ）**: エンターテインメント
- **バージョン**: 1.0.0
- **対応 OS**: iOS 17.0 以上
- **価格**: 無料（App 内課金なし）
- **言語**: 日本語

---

## App Store 説明文

### 概要（プロモーションテキスト / 170文字以内）

日々の悩みを、美しい短歌に変えてみませんか。こころうたは、あなたの気持ちに寄り添い、AIが五七五七七の歌を詠むアプリです。

### 説明文

相談するほどでもない、でも心に引っかかる小さな悩み——こころうたは、そんな日常のモヤモヤを美しい短歌（五七五七七）に変えるアプリです。

言葉の力で心を軽くし、他のユーザーの悩みと短歌を通じて「自分だけじゃない」という共感を届けます。

■ あなたの悩みに寄り添う一首
人間関係、恋愛、仕事、健康——カテゴリを選んで、今の気持ちを言葉にしてみてください。AIがあなたの悩みを汲み取り、心に響く短歌を詠みます。

■ 1日1首、じっくりと
こころうたでは、1日に1回だけ短歌を生成できます。急がず、じっくりと自分の気持ちと向き合う。和紙に墨で書かれた短歌を読むような、静かで暖かい体験をお届けします。

■ みんなの歌を読む
他のユーザーが詠んだ短歌をフィードで閲覧できます。カードをタップすると裏返り、縦書きの短歌が現れます。共感した歌には「いいね」を送りましょう。同じ悩みを持つ誰かの歌が、あなたの心を軽くしてくれるかもしれません。

■ シェアする
心に響いた短歌は、美しい画像として保存・シェアできます。

■ 安心して使える
- 完全匿名で利用可能（アカウント登録不要）
- 不適切な投稿の通報・ブロック機能
- アカウントとデータの完全削除に対応

こころうたは、心のケアを日常に溶け込ませるアプリです。SNS疲れしているけれど、ゆるやかな繋がりは求めている——そんなあなたに。

---

## キーワード（100文字以内）

短歌,AI,悩み相談,メンタルヘルス,ポエム,五七五七七,癒し,心,ストレス,日記

---

## スクリーンショット用の画面説明

1. **フィード画面** — みんなの短歌が流れるタイムライン
2. **悩み入力画面** — カテゴリ選択と悩みテキストの入力
3. **生成中画面** — 波紋アニメーションのローディング
4. **短歌カード** — 生成された短歌の表示（カードフリップ）
5. **わたしの歌** — 自分が生成した短歌の一覧

---

## App Review Information（審査チームへの情報）

### デモアカウント

不要（匿名認証のため、アプリ起動時に自動的にサインインされます）

### 審査メモ（Notes for Review）

```
This app uses Firebase Anonymous Authentication. No login credentials are required - the app automatically signs in users anonymously on launch.

Main features:
1. Enter a worry/concern (10-300 characters) and select a category
2. AI generates a personalized Japanese tanka (31-syllable poem)
3. Browse other users' tankas in the feed
4. Like, report, and block functionality

Key points for review:
- Tanka generation is limited to once per day per user
- All content is AI-generated Japanese poetry (tanka format: 5-7-5-7-7 syllables)
- User-generated input (worry text) is validated by AI before processing
- Content moderation: tankas are auto-hidden after 3 reports
- No personal information is collected; all users are anonymous
- No in-app purchases or subscriptions
- Photo library access is only used to save/share tanka images

Third-party services:
- Firebase (Authentication, Firestore, Cloud Functions)
- OpenAI API (via Firebase Cloud Functions, for tanka generation)
```

---

## 年齢制限レーティング（Content Rating）

| 質問項目 | 回答 |
|---------|------|
| 暴力的なコンテンツ | なし |
| 性的なコンテンツ | なし |
| 頻繁/過激な成人向けコンテンツ | なし |
| 賭博 | なし |
| ホラー/恐怖 | なし |
| 薬物の使用または言及 | なし |
| 医療情報 | なし |
| 不敬表現・下品なユーモア | なし |
| 暴力的なコンテンツ（アニメ/ファンタジー） | なし |
| ユーザー生成コンテンツ | **あり**（ユーザーが悩みを入力、公開フィードで共有） |
| 制限のないWebアクセス | なし |

**推奨レーティング**: **12+**（ユーザー生成コンテンツを含むため）

---

## App Privacy（プライバシー情報）

### データの収集

| データ種別 | 収集 | 用途 | ユーザーとの紐付け |
|-----------|------|------|------------------|
| ユーザー ID（匿名） | はい | アプリの機能 | はい（匿名 ID） |
| ユーザーコンテンツ（悩みテキスト・短歌） | はい | アプリの機能 | はい（匿名 ID） |
| 使用状況データ | いいえ | — | — |
| 位置情報 | いいえ | — | — |
| 連絡先情報 | いいえ | — | — |
| 購入履歴 | いいえ | — | — |
| 閲覧履歴 | いいえ | — | — |
| 診断 | いいえ | — | — |

### トラッキング

**トラッキングなし** — ATT（App Tracking Transparency）は不要

### データの共有

- ユーザーが入力した悩みテキストは OpenAI API に送信され、短歌生成に使用されます
- 生成された短歌はフィードで他のユーザーに公開されます
- 個人を特定する情報は第三者に共有されません

---

## 必要なURL（App Store Connect に設定）

| 項目 | 状態 |
|------|------|
| **プライバシーポリシー URL** | ⚠️ 要作成・公開 |
| **サポート URL** | ⚠️ 要作成・公開 |
| **マーケティング URL** | 任意 |

### プライバシーポリシーに含めるべき内容

1. 匿名認証の説明（個人情報を収集しないこと）
2. 悩みテキストが AI（OpenAI）で処理されること
3. 悩みテキストと短歌がフィードで公開されること
4. Firebase（Google）によるデータ保存
5. データ保持期間とアカウント削除時の対応
6. 通報・ブロック機能の説明
7. 問い合わせ先

---

## エクスポートコンプライアンス

| 質問 | 回答 |
|------|------|
| 暗号化の使用 | **はい**（HTTPS 通信） |
| 標準的な暗号化の免除に該当 | **はい**（HTTPS/TLS のみ） |

※ App Store Connect で「Uses Non-Exempt Encryption: NO」を選択

---

## 連絡先情報

- **サポートメール**: （要設定）
- **サポートURL**: （要設定）
- **プライバシーポリシーURL**: （要設定）
