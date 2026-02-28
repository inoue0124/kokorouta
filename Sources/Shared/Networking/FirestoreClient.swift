@preconcurrency import FirebaseAuth
@preconcurrency import FirebaseFirestore
import Foundation

final class FirestoreClient: Sendable {
    static let shared = FirestoreClient()

    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    // MARK: - Auth

    private var currentUserID: String {
        get throws {
            guard let uid = Auth.auth().currentUser?.uid else {
                throw NetworkError.unauthorized
            }
            return uid
        }
    }

    // MARK: - Feed

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
                throw NetworkError.serverError(statusCode: 404)
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

        // 各短歌の isLikedByMe を並行で判定
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

    // MARK: - My Tanka

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

    // MARK: - Liked Tanka

    func fetchLikedTanka() async throws -> [Tanka] {
        let uid = try currentUserID

        // collectionGroup で likes サブコレクションを横断検索
        // likerID フィールドで自分のいいねのみ取得
        let likesSnapshot = try await db
            .collectionGroup("likes")
            .whereField("likerID", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        // 親パスから tankaID を抽出
        let tankaIDs = likesSnapshot.documents.compactMap { doc -> String? in
            // パス: tanka/{tankaID}/likes/{uid}
            let pathComponents = doc.reference.path.split(separator: "/")
            guard pathComponents.count >= 2 else { return nil }
            return String(pathComponents[1])
        }

        guard !tankaIDs.isEmpty else { return [] }

        // 各短歌ドキュメントを並列フェッチ
        return try await withThrowingTaskGroup(of: Tanka?.self) { group in
            for tankaID in tankaIDs {
                group.addTask {
                    let doc = try await self.db.collection("tanka").document(tankaID).getDocument()
                    guard doc.exists else { return nil }
                    return try await self.mapDocumentToTanka(doc, uid: uid)
                }
            }
            var results: [Tanka] = []
            for try await tanka in group {
                if let tanka {
                    results.append(tanka)
                }
            }
            return results.sorted { $0.createdAt > $1.createdAt }
        }
    }

    // MARK: - Like

    func like(tankaID: String) async throws -> LikeResponse {
        let uid = try currentUserID
        let tankaRef = db.collection("tanka").document(tankaID)
        let likeRef = tankaRef.collection("likes").document(uid)

        let result = try await db.runTransaction { transaction, errorPointer -> Any? in
            let tankaDoc: DocumentSnapshot
            do {
                tankaDoc = try transaction.getDocument(tankaRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
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

            // すでにいいね済みの場合は現在のカウントを返す
            if likeDoc.exists {
                return tankaDoc.data()?["likeCount"] as? Int ?? 0
            }

            let currentCount = tankaDoc.data()?["likeCount"] as? Int ?? 0
            let updatedCount = currentCount + 1

            transaction.setData([
                "likerID": uid,
                "createdAt": FieldValue.serverTimestamp(),
            ], forDocument: likeRef)
            transaction.updateData(["likeCount": updatedCount], forDocument: tankaRef)

            return updatedCount
        }

        guard let newLikeCount = result as? Int else {
            throw NetworkError.serverError(statusCode: 500)
        }
        return LikeResponse(likeCount: newLikeCount)
    }

    func unlike(tankaID: String) async throws -> LikeResponse {
        let uid = try currentUserID
        let tankaRef = db.collection("tanka").document(tankaID)
        let likeRef = tankaRef.collection("likes").document(uid)

        let result = try await db.runTransaction { transaction, errorPointer -> Any? in
            let tankaDoc: DocumentSnapshot
            do {
                tankaDoc = try transaction.getDocument(tankaRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
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

            // いいねが存在しない場合は現在のカウントを返す
            guard likeDoc.exists else {
                return tankaDoc.data()?["likeCount"] as? Int ?? 0
            }

            let currentCount = tankaDoc.data()?["likeCount"] as? Int ?? 0
            let updatedCount = max(0, currentCount - 1)

            transaction.deleteDocument(likeRef)
            transaction.updateData(["likeCount": updatedCount], forDocument: tankaRef)

            return updatedCount
        }

        guard let newLikeCount = result as? Int else {
            throw NetworkError.serverError(statusCode: 500)
        }
        return LikeResponse(likeCount: newLikeCount)
    }

    // MARK: - Blocked Users

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

    // MARK: - Helper

    private func mapDocumentToTanka(_ doc: DocumentSnapshot, uid: String) async throws -> Tanka {
        guard let data = doc.data() else {
            throw NetworkError.decodingError
        }

        let likeDoc = try await doc.reference.collection("likes").document(uid).getDocument()

        guard let category = (data["category"] as? String).flatMap(WorryCategory.init(rawValue:)),
              let createdAtTimestamp = data["createdAt"] as? Timestamp
        else {
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
}
