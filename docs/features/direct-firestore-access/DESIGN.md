# 詳細設計書: Cloud Functions → 直接 Firestore アクセスへの移行

> 生成日時: 2026-02-28
> Issue: #68
> ステータス: Draft
> 入力: REQUIREMENTS.md, docs/architecture.md, docs/development-guidelines.md

## 1. 設計概要

### 変更前のデータフロー

```
View → ViewModel → TankaRepository → APIClient → Cloud Functions → Firestore
```

### 変更後のデータフロー

```
[直接アクセス対象]
View → ViewModel → TankaRepository → FirestoreClient → Firestore

[Functions 維持対象]
View → ViewModel → TankaRepository → APIClient → Cloud Functions → OpenAI API / Firestore
```

### 設計方針

- `TankaRepositoryProtocol` のインターフェースは変更しない
- `TankaRepository` の実装を変更し、`FirestoreClient` と `APIClient` を併用する
- 新規 `FirestoreClient` クラスで Firestore 直接アクセスのロジックをカプセル化する
- Firestore エラーを既存の `NetworkError` にマッピングする

## 2. 新規ファイル

### 2.1 FirestoreClient (`Sources/Shared/Networking/FirestoreClient.swift`)

Firestore への直接アクセスを担当するクライアント。`APIClient` と同レイヤーに配置する。

```swift
@preconcurrency import FirebaseAuth
@preconcurrency import FirebaseFirestore
import Foundation

final class FirestoreClient: Sendable {
    static let shared = FirestoreClient()

    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    /// 現在の認証ユーザー ID を取得する
    private var currentUserID: String {
        get throws {
            guard let uid = Auth.auth().currentUser?.uid else {
                throw NetworkError.unauthorized
            }
            return uid
        }
    }
}
```

#### 2.1.1 fetchFeed メソッド

```swift
func fetchFeed(limit: Int, afterID: String?) async throws -> FeedResponse {
    let uid = try currentUserID

    // ブロックユーザー ID を取得
    let blockedSnapshot = try await db
        .collection("users")
        .document(uid)
        .collection("blockedUsers")
        .getDocuments()
    let blockedUserIDs = Set(blockedSnapshot.documents.map(\.documentID))

    // クエリ構築
    var query: Query = db
        .collection("tanka")
        .whereField("isHidden", isEqualTo: false)
        .order(by: "createdAt", descending: true)

    // カーソルベースページネーション
    if let afterID {
        let cursorDoc = try await db.collection("tanka").document(afterID).getDocument()
        guard cursorDoc.exists else {
            throw NetworkError.invalidArgument(message: "指定されたカーソルの短歌が見つかりません。")
        }
        query = query.start(afterDocument: cursorDoc)
    }

    // limit + 1 件取得して hasMore を判定
    let snapshot = try await query.limit(to: limit + 1).getDocuments()

    // ブロックユーザーの短歌をフィルタ
    let filteredDocs = snapshot.documents.filter { doc in
        let authorID = doc.data()["authorID"] as? String ?? ""
        return !blockedUserIDs.contains(authorID)
    }

    let hasMore = filteredDocs.count > limit
    let resultDocs = hasMore ? Array(filteredDocs.prefix(limit)) : filteredDocs

    // 各短歌の isLikedByMe を判定
    let tankaList = try await withThrowingTaskGroup(of: Tanka.self) { group in
        for doc in resultDocs {
            group.addTask {
                try await self.mapDocumentToTanka(doc, uid: uid)
            }
        }
        var results: [Tanka] = []
        for try await tanka in group {
            results.append(tanka)
        }
        return results
    }

    // createdAt 降順でソート（TaskGroup は順序を保証しないため）
    let sortedList = tankaList.sorted { $0.createdAt > $1.createdAt }

    let nextCursor = hasMore ? resultDocs.last?.documentID : nil
    return FeedResponse(tankaList: sortedList, hasMore: hasMore, nextCursor: nextCursor)
}
```

#### 2.1.2 fetchMyTanka メソッド

```swift
func fetchMyTanka() async throws -> [Tanka] {
    let uid = try currentUserID

    let snapshot = try await db
        .collection("tanka")
        .whereField("authorID", isEqualTo: uid)
        .order(by: "createdAt", descending: true)
        .getDocuments()

    return try await withThrowingTaskGroup(of: Tanka.self) { group in
        for doc in snapshot.documents {
            group.addTask {
                try await self.mapDocumentToTanka(doc, uid: uid)
            }
        }
        var results: [Tanka] = []
        for try await tanka in group {
            results.append(tanka)
        }
        return results.sorted { $0.createdAt > $1.createdAt }
    }
}
```

#### 2.1.3 like / unlike メソッド

```swift
func like(tankaID: String) async throws -> LikeResponse {
    let uid = try currentUserID
    let tankaRef = db.collection("tanka").document(tankaID)
    let likeRef = tankaRef.collection("likes").document(uid)

    let newLikeCount = try await db.runTransaction { transaction, errorPointer in
        let tankaDoc: DocumentSnapshot
        do {
            tankaDoc = try transaction.getDocument(tankaRef)
        } catch {
            errorPointer?.pointee = error as NSError
            return nil as Int?
        }

        guard tankaDoc.exists else {
            errorPointer?.pointee = NSError(
                domain: "FirestoreClient",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "指定された短歌が見つかりません。"]
            )
            return nil
        }

        let likeDoc: DocumentSnapshot
        do {
            likeDoc = try transaction.getDocument(likeRef)
        } catch {
            errorPointer?.pointee = error as NSError
            return nil
        }

        if likeDoc.exists { return tankaDoc.data()?["likeCount"] as? Int ?? 0 }

        let currentCount = tankaDoc.data()?["likeCount"] as? Int ?? 0
        let updatedCount = currentCount + 1

        transaction.setData(["createdAt": FieldValue.serverTimestamp()], forDocument: likeRef)
        transaction.updateData(["likeCount": updatedCount], forDocument: tankaRef)

        return updatedCount
    }

    return LikeResponse(likeCount: newLikeCount ?? 0)
}

func unlike(tankaID: String) async throws -> LikeResponse {
    let uid = try currentUserID
    let tankaRef = db.collection("tanka").document(tankaID)
    let likeRef = tankaRef.collection("likes").document(uid)

    let newLikeCount = try await db.runTransaction { transaction, errorPointer in
        let tankaDoc: DocumentSnapshot
        do {
            tankaDoc = try transaction.getDocument(tankaRef)
        } catch {
            errorPointer?.pointee = error as NSError
            return nil as Int?
        }

        guard tankaDoc.exists else {
            errorPointer?.pointee = NSError(
                domain: "FirestoreClient",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "指定された短歌が見つかりません。"]
            )
            return nil
        }

        let likeDoc: DocumentSnapshot
        do {
            likeDoc = try transaction.getDocument(likeRef)
        } catch {
            errorPointer?.pointee = error as NSError
            return nil
        }

        guard likeDoc.exists else {
            return tankaDoc.data()?["likeCount"] as? Int ?? 0
        }

        let currentCount = tankaDoc.data()?["likeCount"] as? Int ?? 0
        let updatedCount = max(0, currentCount - 1)

        transaction.deleteDocument(likeRef)
        transaction.updateData(["likeCount": updatedCount], forDocument: tankaRef)

        return updatedCount
    }

    return LikeResponse(likeCount: newLikeCount ?? 0)
}
```

#### 2.1.4 fetchBlockedUsers メソッド

```swift
func fetchBlockedUsers() async throws -> [BlockedUser] {
    let uid = try currentUserID

    let snapshot = try await db
        .collection("users")
        .document(uid)
        .collection("blockedUsers")
        .getDocuments()

    return snapshot.documents.compactMap { doc in
        guard let createdAt = (doc.data()["createdAt"] as? Timestamp)?.dateValue() else {
            return nil
        }
        return BlockedUser(
            id: doc.documentID,
            blockedID: doc.documentID,
            createdAt: createdAt
        )
    }
}
```

#### 2.1.5 ヘルパーメソッド

```swift
private func mapDocumentToTanka(_ doc: DocumentSnapshot, uid: String) async throws -> Tanka {
    guard let data = doc.data() else {
        throw NetworkError.decodingError
    }

    let likeDoc = try await doc.reference.collection("likes").document(uid).getDocument()

    guard let category = (data["category"] as? String).flatMap(WorryCategory.init(rawValue:)),
          let createdAtTimestamp = data["createdAt"] as? Timestamp else {
        throw NetworkError.decodingError
    }

    return Tanka(
        id: doc.documentID,
        authorID: data["authorID"] as? String ?? "",
        category: category,
        worryText: data["worryText"] as? String ?? "",
        tankaText: data["tankaText"] as? String ?? "",
        likeCount: data["likeCount"] as? Int ?? 0,
        isLikedByMe: likeDoc.exists,
        createdAt: createdAtTimestamp.dateValue()
    )
}
```

## 3. 既存ファイルの変更

### 3.1 TankaRepository (`Sources/Shared/Repository/TankaRepository.swift`)

`FirestoreClient` と `APIClient` を併用するように変更する。

```swift
import Foundation

final class TankaRepository: TankaRepositoryProtocol {
    private let apiClient: APIClient
    private let firestoreClient: FirestoreClient

    init(apiClient: APIClient = .shared, firestoreClient: FirestoreClient = .shared) {
        self.apiClient = apiClient
        self.firestoreClient = firestoreClient
    }

    // MARK: - 直接 Firestore アクセス

    func fetchFeed(limit: Int, afterID: String?) async throws -> FeedResponse {
        try await firestoreClient.fetchFeed(limit: limit, afterID: afterID)
    }

    func fetchMyTanka() async throws -> [Tanka] {
        try await firestoreClient.fetchMyTanka()
    }

    func like(tankaID: String) async throws -> LikeResponse {
        try await firestoreClient.like(tankaID: tankaID)
    }

    func unlike(tankaID: String) async throws -> LikeResponse {
        try await firestoreClient.unlike(tankaID: tankaID)
    }

    func fetchBlockedUsers() async throws -> [BlockedUser] {
        try await firestoreClient.fetchBlockedUsers()
    }

    // MARK: - Cloud Functions 経由（変更なし）

    func generateTanka(category: WorryCategory, worryText: String) async throws -> Tanka {
        let response: GenerateTankaResponse = try await apiClient.call(
            "generateTanka",
            data: [
                "category": category.rawValue,
                "worryText": worryText,
            ]
        )
        return response.tanka
    }

    func report(tankaID: String, reason: ReportReason) async throws {
        try await apiClient.callVoid(
            "reportTanka",
            data: [
                "tankaID": tankaID,
                "reason": reason.rawValue,
            ]
        )
    }

    func blockUser(userID: String) async throws {
        try await apiClient.callVoid("blockUser", data: ["userID": userID])
    }

    func unblockUser(userID: String) async throws {
        try await apiClient.callVoid("unblockUser", data: ["userID": userID])
    }

    func deleteAccount() async throws {
        try await apiClient.callVoid("deleteAccount")
    }
}
```

### 3.2 Firestore Security Rules (`firestore.rules`)

認証済みユーザーに適切なアクセス権を付与する。

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // 短歌コレクション
    match /tanka/{tankaID} {
      // 認証済みユーザーは読み取り可能
      allow read: if request.auth != null;

      // クライアントからの直接作成・削除は不可（Cloud Functions 経由のみ）
      allow create, delete: if false;

      // likeCount のみ更新可能（Transaction 経由で likes サブコレクションと同時に更新）
      allow update: if request.auth != null
        && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['likeCount'])
        && request.resource.data.likeCount is int
        && request.resource.data.likeCount >= 0;

      // いいねサブコレクション
      match /likes/{userID} {
        // 認証済みユーザーは読み取り可能
        allow read: if request.auth != null;

        // 自分の ID のドキュメントのみ作成・削除可能
        allow create: if request.auth != null && request.auth.uid == userID;
        allow delete: if request.auth != null && request.auth.uid == userID;
      }
    }

    // ユーザーコレクション
    match /users/{userID} {
      // 自分のドキュメントのみ読み取り可能
      allow read: if request.auth != null && request.auth.uid == userID;

      // ブロックユーザーサブコレクション
      match /blockedUsers/{blockedID} {
        // 自分のブロックリストのみ読み取り可能
        allow read: if request.auth != null && request.auth.uid == userID;

        // 作成・削除は Cloud Functions 経由のみ
        allow create, delete: if false;
      }
    }

    // 通報コレクション（Cloud Functions 経由のみ）
    match /reports/{reportID} {
      allow read, write: if false;
    }
  }
}
```

### 3.3 AppError の Firestore エラー対応 (`Sources/Shared/Error/AppError.swift`)

`AppError.init(_ error:)` に Firestore エラーのマッピングを追加する。

```swift
init(_ error: Error) {
    if let networkError = error as? NetworkError {
        switch networkError {
        case .rateLimited:
            self = .rateLimited(nextAvailableAt: Calendar.current.startOfDay(
                for: Date()
            ).addingTimeInterval(24 * 60 * 60))
        case let .invalidArgument(message):
            self = .validation(message)
        default:
            self = .network(networkError)
        }
    } else if let appError = error as? Self {
        self = appError
    } else {
        let nsError = error as NSError
        // Firestore エラーのマッピング
        if nsError.domain == "FIRFirestoreErrorDomain" {
            switch nsError.code {
            case 7: // PERMISSION_DENIED
                self = .network(.unauthorized)
            case 14: // UNAVAILABLE
                self = .network(.noConnection)
            case 4: // DEADLINE_EXCEEDED
                self = .network(.timeout)
            default:
                self = .unknown(error.localizedDescription)
            }
        } else {
            self = .unknown(error.localizedDescription)
        }
    }
}
```

## 4. 変更しないファイル

以下のファイルは変更しない:

- `TankaRepositoryProtocol.swift` — インターフェースは維持
- `APIClient.swift` — Cloud Functions 用クライアントとして維持
- `FeedViewModel.swift` — Repository を通じたアクセスのため変更不要
- `MyTankaViewModel.swift` — 同上
- `MockTankaRepository.swift` — テスト用 Mock は Protocol ベースのため変更不要
- 各 View ファイル — ViewModel 経由のため変更不要

## 5. データフロー図（変更後）

### フィード取得フロー

```
FeedView
  → FeedViewModel.loadFeed()
    → TankaRepository.fetchFeed(limit:afterID:)
      → FirestoreClient.fetchFeed(limit:afterID:)
        → Firestore: users/{uid}/blockedUsers (ブロックリスト取得)
        → Firestore: tanka (isHidden == false, createdAt desc, cursor pagination)
        → Firestore: tanka/{id}/likes/{uid} (isLikedByMe 判定, 並行実行)
      ← FeedResponse
    ← FeedResponse
  ← @Observable で自動更新
```

### いいねフロー

```
FeedView (いいねタップ)
  → FeedViewModel.toggleLike(for:)
    → TankaRepository.like(tankaID:)
      → FirestoreClient.like(tankaID:)
        → Firestore Transaction:
          1. tanka/{tankaID} 読み取り
          2. tanka/{tankaID}/likes/{uid} 存在確認
          3. likes/{uid} ドキュメント作成
          4. likeCount インクリメント
      ← LikeResponse(likeCount)
    ← LikeResponse
  ← @Observable で自動更新
```

## 6. Firestore インデックス

以下の複合インデックスが必要（既存の `firestore.indexes.json` に追加が必要な場合）:

| コレクション | フィールド | 順序 |
|---|---|---|
| `tanka` | `isHidden` (Ascending), `createdAt` (Descending) | 必要（フィード取得用） |
| `tanka` | `authorID` (Ascending), `createdAt` (Descending) | 必要（マイ短歌取得用） |

## 7. テスト影響

### 影響なし

- `FeedViewModelTests` — MockTankaRepository を使用しているため影響なし
- `MyTankaViewModelTests` — 同上
- `ComposeViewModelTests` — 同上
- `TankaResultViewModelTests` — 同上
- `BlockListViewModelTests` — 同上
- `ReportViewModelTests` — 同上

### 追加検討

- `FirestoreClient` の統合テストは手動テストで確認する（Firestore Emulator を使用）
