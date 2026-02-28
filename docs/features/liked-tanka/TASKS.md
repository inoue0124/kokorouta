# タスクリスト: いいねした短歌の一覧画面

> Issue: #73
> 生成日時: 2026-03-01

## タスク一覧

- [ ] **Task 1**: `TankaRepositoryProtocol` に `fetchLikedTanka()` メソッドを追加
  - ファイル: `Sources/Shared/Repository/TankaRepositoryProtocol.swift`
  - 内容: `func fetchLikedTanka() async throws -> [Tanka]` を追加

- [ ] **Task 2**: `FirestoreClient` に `fetchLikedTanka()` を実装
  - ファイル: `Sources/Shared/Networking/FirestoreClient.swift`
  - 内容: `collectionGroup("likes")` で自分のいいねを取得し、各短歌ドキュメントを並列フェッチ

- [ ] **Task 3**: `TankaRepository` に `fetchLikedTanka()` を実装
  - ファイル: `Sources/Shared/Repository/TankaRepository.swift`
  - 内容: `FirestoreClient.fetchLikedTanka()` に委譲

- [ ] **Task 4**: `MyTankaRoute` を作成
  - ファイル: `Sources/Shared/Navigation/MyTankaRoute.swift`（新規）
  - 内容: `enum MyTankaRoute: Hashable { case likedTanka }`

- [ ] **Task 5**: `LikedTankaViewModel` を作成
  - ファイル: `Sources/Features/MyTanka/ViewModel/LikedTankaViewModel.swift`（新規）
  - 内容: `@Observable @MainActor` クラス。`loadLikedTanka()`, `toggleLike(for:)` を実装

- [ ] **Task 6**: `LikedTankaView` を作成
  - ファイル: `Sources/Features/MyTanka/View/LikedTankaView.swift`（新規）
  - 内容: 状態分岐（Loading/Error/Empty/List）、TankaCard 再利用、プルリフレッシュ対応

- [ ] **Task 7**: `MyTankaView` にナビゲーションリンクを追加
  - ファイル: `Sources/Features/MyTanka/View/MyTankaView.swift`
  - 内容: 短歌リストの上部に「いいねした短歌」への NavigationLink を追加

- [ ] **Task 8**: `ContentView` にナビゲーション先を追加
  - ファイル: `Sources/App/ContentView.swift`
  - 内容: MyTanka タブの NavigationStack に `.navigationDestination(for: MyTankaRoute.self)` を追加

- [ ] **Task 9**: Mock / Preview Repository を更新
  - ファイル: `Tests/Mocks/MockTankaRepository.swift`, `Sources/Shared/Repository/MockTankaRepository.swift`
  - 内容: `fetchLikedTanka()` のスタブ / Preview 用実装を追加

- [ ] **Task 10**: `LikedTankaViewModel` のユニットテストを作成
  - ファイル: `Tests/MyTanka/LikedTankaViewModelTests.swift`（新規）
  - 内容: 正常系・エラー系・いいね解除のテスト

- [ ] **Task 11**: 構文検証（ビルド確認）
  - 全ファイルの構文検証を実施
