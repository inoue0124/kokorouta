import Foundation

@Observable
@MainActor
final class FeedViewModel {
    private(set) var tankaList: [Tanka] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var error: AppError?
    private(set) var paginationError: AppError?
    private(set) var hasMore = true
    var reportTarget: Tanka?
    var blockTarget: Tanka?

    private var nextCursor: String?
    private var likingTankaIDs: Set<String> = []
    private let tankaRepository: any TankaRepositoryProtocol

    init(tankaRepository: any TankaRepositoryProtocol) {
        self.tankaRepository = tankaRepository
    }

    func loadFeed() async {
        isLoading = true
        error = nil
        paginationError = nil
        defer { isLoading = false }
        do {
            let response = try await tankaRepository.fetchFeed(limit: 20, afterID: nil)
            tankaList = response.tankaList
            hasMore = response.hasMore
            nextCursor = response.nextCursor
        } catch {
            self.error = AppError(error)
        }
    }

    func loadMore() async {
        guard hasMore, !isLoadingMore, !isLoading else { return }
        paginationError = nil
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let response = try await tankaRepository.fetchFeed(limit: 20, afterID: nextCursor)
            tankaList.append(contentsOf: response.tankaList)
            hasMore = response.hasMore
            nextCursor = response.nextCursor
        } catch {
            paginationError = AppError(error)
        }
    }

    func toggleLike(for tanka: Tanka) async {
        guard !likingTankaIDs.contains(tanka.id),
              let index = tankaList.firstIndex(where: { $0.id == tanka.id })
        else { return }

        likingTankaIDs.insert(tanka.id)
        defer { likingTankaIDs.remove(tanka.id) }

        let wasLiked = tanka.isLikedByMe
        let previousCount = tanka.likeCount

        // Optimistic update
        tankaList[index].isLikedByMe = !wasLiked
        tankaList[index].likeCount = wasLiked ? max(0, previousCount - 1) : previousCount + 1

        do {
            let response = if wasLiked {
                try await tankaRepository.unlike(tankaID: tanka.id)
            } else {
                try await tankaRepository.like(tankaID: tanka.id)
            }
            // Sync with server value
            if let current = tankaList.firstIndex(where: { $0.id == tanka.id }) {
                tankaList[current].likeCount = response.likeCount
            }
        } catch {
            // Rollback on failure
            if let current = tankaList.firstIndex(where: { $0.id == tanka.id }) {
                tankaList[current].isLikedByMe = wasLiked
                tankaList[current].likeCount = previousCount
            }
            self.error = AppError(error)
        }
    }

    func report(tankaID: String, reason: ReportReason) async throws {
        try await tankaRepository.report(tankaID: tankaID, reason: reason)
        tankaList.removeAll { $0.id == tankaID }
    }

    func blockUser(authorID: String) async {
        do {
            try await tankaRepository.blockUser(userID: authorID)
            tankaList.removeAll { $0.authorID == authorID }
        } catch {
            self.error = AppError(error)
        }
    }
}
