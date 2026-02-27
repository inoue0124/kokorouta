import Foundation

final class TankaRepository: TankaRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

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

    func fetchFeed(limit: Int, afterID: String?) async throws -> FeedResponse {
        var data: [String: Any] = ["limit": limit]
        if let afterID { data["afterID"] = afterID }
        return try await apiClient.call("fetchFeed", data: data)
    }

    func fetchMyTanka() async throws -> [Tanka] {
        let response: MyTankaResponse = try await apiClient.call("fetchMyTanka")
        return response.tankaList
    }

    func like(tankaID: String) async throws -> LikeResponse {
        try await apiClient.call("likeTanka", data: ["tankaID": tankaID])
    }

    func unlike(tankaID: String) async throws -> LikeResponse {
        try await apiClient.call("unlikeTanka", data: ["tankaID": tankaID])
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

    func fetchBlockedUsers() async throws -> [BlockedUser] {
        let response: BlockedUsersResponse = try await apiClient.call("fetchBlockedUsers")
        return response.blockedUsers
    }

    func deleteAccount() async throws {
        try await apiClient.callVoid("deleteAccount")
    }
}
