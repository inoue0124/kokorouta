@testable import App
import Foundation

final class MockTankaRepository: TankaRepositoryProtocol, @unchecked Sendable {
    var stubbedFeedResponse = FeedResponse(tankaList: [], hasMore: false, nextCursor: nil)
    var stubbedLikeResponse = LikeResponse(likeCount: 0)
    var stubbedGeneratedTanka: Tanka?
    var stubbedMyTankaList: [Tanka] = []
    var stubbedLikedTankaList: [Tanka] = []
    var stubbedBlockedUsers: [BlockedUser] = []
    var stubbedError: Error?

    var generateTankaCallCount = 0
    var fetchFeedCallCount = 0
    var fetchFeedLastAfterID: String?
    var likeCallCount = 0
    var unlikeCallCount = 0
    var reportCallCount = 0
    var reportLastReason: ReportReason?
    var blockUserCallCount = 0
    var blockUserLastUserID: String?
    var unblockUserCallCount = 0
    var unblockUserLastUserID: String?
    var deleteAccountCallCount = 0

    func generateTanka(category: WorryCategory, worryText: String) async throws -> Tanka {
        generateTankaCallCount += 1
        if let error = stubbedError { throw error }
        guard let tanka = stubbedGeneratedTanka else {
            throw AppError.unknown("No stubbed tanka")
        }
        return tanka
    }

    func fetchFeed(limit: Int, afterID: String?) async throws -> FeedResponse {
        fetchFeedCallCount += 1
        fetchFeedLastAfterID = afterID
        if let error = stubbedError { throw error }
        return stubbedFeedResponse
    }

    func fetchMyTanka() async throws -> [Tanka] {
        if let error = stubbedError { throw error }
        return stubbedMyTankaList
    }

    func fetchLikedTanka() async throws -> [Tanka] {
        if let error = stubbedError { throw error }
        return stubbedLikedTankaList
    }

    func like(tankaID: String) async throws -> LikeResponse {
        likeCallCount += 1
        if let error = stubbedError { throw error }
        return stubbedLikeResponse
    }

    func unlike(tankaID: String) async throws -> LikeResponse {
        unlikeCallCount += 1
        if let error = stubbedError { throw error }
        return stubbedLikeResponse
    }

    func report(tankaID: String, reason: ReportReason) async throws {
        reportCallCount += 1
        reportLastReason = reason
        if let error = stubbedError { throw error }
    }

    func blockUser(userID: String) async throws {
        blockUserCallCount += 1
        blockUserLastUserID = userID
        if let error = stubbedError { throw error }
    }

    func unblockUser(userID: String) async throws {
        unblockUserCallCount += 1
        unblockUserLastUserID = userID
        if let error = stubbedError { throw error }
    }

    func fetchBlockedUsers() async throws -> [BlockedUser] {
        if let error = stubbedError { throw error }
        return stubbedBlockedUsers
    }

    func deleteAccount() async throws {
        deleteAccountCallCount += 1
        if let error = stubbedError { throw error }
    }
}
