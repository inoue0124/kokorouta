import Foundation

protocol TankaRepositoryProtocol: Sendable {
    func generateTanka(category: WorryCategory, worryText: String) async throws -> Tanka
    func fetchFeed(limit: Int, afterID: String?) async throws -> FeedResponse
    func fetchMyTanka() async throws -> [Tanka]
    func like(tankaID: String) async throws -> LikeResponse
    func unlike(tankaID: String) async throws -> LikeResponse
    func report(tankaID: String, reason: ReportReason) async throws
    func blockUser(userID: String) async throws
    func unblockUser(userID: String) async throws
    func fetchBlockedUsers() async throws -> [BlockedUser]
    func deleteAccount() async throws
}
