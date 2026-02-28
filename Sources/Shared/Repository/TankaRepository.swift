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

    func fetchLikedTanka() async throws -> [Tanka] {
        try await firestoreClient.fetchLikedTanka()
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

    // MARK: - Cloud Functions 経由

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
