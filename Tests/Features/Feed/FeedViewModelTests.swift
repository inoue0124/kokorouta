@testable import App
import Testing

@MainActor
struct FeedViewModelTests {
    // MARK: - loadFeed

    @Test
    func loadFeed_success_updatesTankaList() async {
        let mock = MockTankaRepository()
        let tanka = Tanka.mock()
        mock.stubbedFeedResponse = FeedResponse(
            tankaList: [tanka],
            hasMore: true,
            nextCursor: "cursor-1"
        )
        let viewModel = FeedViewModel(tankaRepository: mock)

        await viewModel.loadFeed()

        #expect(viewModel.tankaList.count == 1)
        #expect(viewModel.tankaList[0].id == "tanka-1")
        #expect(viewModel.hasMore == true)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }

    @Test
    func loadFeed_failure_setsError() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.noConnection
        let viewModel = FeedViewModel(tankaRepository: mock)

        await viewModel.loadFeed()

        #expect(viewModel.tankaList.isEmpty)
        #expect(viewModel.error != nil)
        #expect(viewModel.isLoading == false)
    }

    @Test
    func loadFeed_emptyResponse_setsEmptyList() async {
        let mock = MockTankaRepository()
        mock.stubbedFeedResponse = FeedResponse(tankaList: [], hasMore: false, nextCursor: nil)
        let viewModel = FeedViewModel(tankaRepository: mock)

        await viewModel.loadFeed()

        #expect(viewModel.tankaList.isEmpty)
        #expect(viewModel.hasMore == false)
        #expect(viewModel.error == nil)
    }

    // MARK: - loadFeed error recovery

    @Test
    func loadFeed_retry_clearsPreviousError() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.noConnection
        let viewModel = FeedViewModel(tankaRepository: mock)
        await viewModel.loadFeed()
        #expect(viewModel.error != nil)

        mock.stubbedError = nil
        mock.stubbedFeedResponse = FeedResponse(
            tankaList: [Tanka.mock()],
            hasMore: false,
            nextCursor: nil
        )
        await viewModel.loadFeed()

        #expect(viewModel.error == nil)
        #expect(viewModel.tankaList.count == 1)
    }

    @Test
    func loadFeed_refresh_replacesExistingData() async {
        let mock = MockTankaRepository()
        mock.stubbedFeedResponse = FeedResponse(
            tankaList: [Tanka.mock(id: "old-1")],
            hasMore: false,
            nextCursor: nil
        )
        let viewModel = FeedViewModel(tankaRepository: mock)
        await viewModel.loadFeed()
        #expect(viewModel.tankaList.count == 1)

        mock.stubbedFeedResponse = FeedResponse(
            tankaList: [Tanka.mock(id: "new-1"), Tanka.mock(id: "new-2")],
            hasMore: true,
            nextCursor: "cursor-new"
        )
        await viewModel.loadFeed()

        #expect(viewModel.tankaList.count == 2)
        #expect(viewModel.tankaList[0].id == "new-1")
        #expect(viewModel.hasMore == true)
    }

    @Test
    func loadFeed_passesNilAfterID() async {
        let mock = MockTankaRepository()
        mock.stubbedFeedResponse = FeedResponse(tankaList: [], hasMore: false, nextCursor: nil)
        let viewModel = FeedViewModel(tankaRepository: mock)

        await viewModel.loadFeed()

        #expect(mock.fetchFeedLastAfterID == nil)
    }

    // MARK: - Initial state

    @Test
    func initialState_hasCorrectDefaults() {
        let mock = MockTankaRepository()
        let viewModel = FeedViewModel(tankaRepository: mock)

        #expect(viewModel.tankaList.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.isLoadingMore == false)
        #expect(viewModel.error == nil)
        #expect(viewModel.hasMore == true)
        #expect(viewModel.reportTarget == nil)
        #expect(viewModel.blockTarget == nil)
    }
}

// MARK: - Pagination, Like, Report, Block Tests

@MainActor
struct FeedViewModelPaginationTests {
    // MARK: - loadMore

    @Test
    func loadMore_success_appendsTankaList() async {
        let mock = MockTankaRepository()
        mock.stubbedFeedResponse = FeedResponse(
            tankaList: [Tanka.mock(id: "tanka-1")],
            hasMore: true,
            nextCursor: "cursor-1"
        )
        let viewModel = FeedViewModel(tankaRepository: mock)
        await viewModel.loadFeed()

        mock.stubbedFeedResponse = FeedResponse(
            tankaList: [Tanka.mock(id: "tanka-2")],
            hasMore: false,
            nextCursor: nil
        )
        await viewModel.loadMore()

        #expect(viewModel.tankaList.count == 2)
        #expect(viewModel.tankaList[1].id == "tanka-2")
        #expect(viewModel.hasMore == false)
    }

    @Test
    func loadMore_noMore_doesNotFetch() async {
        let mock = MockTankaRepository()
        mock.stubbedFeedResponse = FeedResponse(tankaList: [], hasMore: false, nextCursor: nil)
        let viewModel = FeedViewModel(tankaRepository: mock)
        await viewModel.loadFeed()

        let callCountBefore = mock.fetchFeedCallCount
        await viewModel.loadMore()

        #expect(mock.fetchFeedCallCount == callCountBefore)
    }

    @Test
    func loadMore_usesCursor() async {
        let mock = MockTankaRepository()
        mock.stubbedFeedResponse = FeedResponse(
            tankaList: [Tanka.mock()],
            hasMore: true,
            nextCursor: "cursor-abc"
        )
        let viewModel = FeedViewModel(tankaRepository: mock)
        await viewModel.loadFeed()

        mock.stubbedFeedResponse = FeedResponse(tankaList: [], hasMore: false, nextCursor: nil)
        await viewModel.loadMore()

        #expect(mock.fetchFeedLastAfterID == "cursor-abc")
    }

    // MARK: - loadMore error

    @Test
    func loadMore_failure_setsError() async {
        let mock = MockTankaRepository()
        mock.stubbedFeedResponse = FeedResponse(
            tankaList: [Tanka.mock()],
            hasMore: true,
            nextCursor: "cursor-1"
        )
        let viewModel = FeedViewModel(tankaRepository: mock)
        await viewModel.loadFeed()

        mock.stubbedError = NetworkError.serverError(statusCode: 500)
        await viewModel.loadMore()

        #expect(viewModel.error != nil)
        #expect(viewModel.isLoadingMore == false)
        #expect(viewModel.tankaList.count == 1)
    }

    @Test
    func loadMore_failure_preservesExistingData() async {
        let mock = MockTankaRepository()
        mock.stubbedFeedResponse = FeedResponse(
            tankaList: [Tanka.mock(id: "t1")],
            hasMore: true,
            nextCursor: "cursor-1"
        )
        let viewModel = FeedViewModel(tankaRepository: mock)
        await viewModel.loadFeed()

        mock.stubbedError = NetworkError.timeout
        await viewModel.loadMore()

        #expect(viewModel.tankaList.count == 1)
        #expect(viewModel.tankaList[0].id == "t1")
    }

    // MARK: - toggleLike

    @Test
    func toggleLike_like_updatesState() async {
        let mock = MockTankaRepository()
        mock.stubbedLikeResponse = LikeResponse(likeCount: 1)
        mock.stubbedFeedResponse = FeedResponse(
            tankaList: [Tanka.mock(likeCount: 0, isLikedByMe: false)],
            hasMore: false,
            nextCursor: nil
        )
        let viewModel = FeedViewModel(tankaRepository: mock)
        await viewModel.loadFeed()

        await viewModel.toggleLike(for: viewModel.tankaList[0])

        #expect(viewModel.tankaList[0].isLikedByMe == true)
        #expect(viewModel.tankaList[0].likeCount == 1)
        #expect(mock.likeCallCount == 1)
    }

    @Test
    func toggleLike_unlike_updatesState() async {
        let mock = MockTankaRepository()
        mock.stubbedLikeResponse = LikeResponse(likeCount: 4)
        mock.stubbedFeedResponse = FeedResponse(
            tankaList: [Tanka.mock(likeCount: 5, isLikedByMe: true)],
            hasMore: false,
            nextCursor: nil
        )
        let viewModel = FeedViewModel(tankaRepository: mock)
        await viewModel.loadFeed()

        await viewModel.toggleLike(for: viewModel.tankaList[0])

        #expect(viewModel.tankaList[0].isLikedByMe == false)
        #expect(viewModel.tankaList[0].likeCount == 4)
        #expect(mock.unlikeCallCount == 1)
    }

    @Test
    func toggleLike_nonExistentTanka_doesNothing() async {
        let mock = MockTankaRepository()
        let viewModel = FeedViewModel(tankaRepository: mock)
        let nonExistent = Tanka.mock(id: "nonexistent")

        await viewModel.toggleLike(for: nonExistent)

        #expect(mock.likeCallCount == 0)
        #expect(mock.unlikeCallCount == 0)
    }

    // MARK: - toggleLike error

    @Test
    func toggleLike_failure_setsError() async {
        let mock = MockTankaRepository()
        mock.stubbedFeedResponse = FeedResponse(
            tankaList: [Tanka.mock(likeCount: 0, isLikedByMe: false)],
            hasMore: false,
            nextCursor: nil
        )
        let viewModel = FeedViewModel(tankaRepository: mock)
        await viewModel.loadFeed()

        mock.stubbedError = NetworkError.serverError(statusCode: 500)
        await viewModel.toggleLike(for: viewModel.tankaList[0])

        #expect(viewModel.error != nil)
    }

    // MARK: - report

    @Test
    func report_success_removesTankaFromList() async {
        let mock = MockTankaRepository()
        mock.stubbedFeedResponse = FeedResponse(
            tankaList: [Tanka.mock(id: "t1"), Tanka.mock(id: "t2")],
            hasMore: false,
            nextCursor: nil
        )
        let viewModel = FeedViewModel(tankaRepository: mock)
        await viewModel.loadFeed()

        await viewModel.report(tankaID: "t1", reason: .inappropriate)

        #expect(viewModel.tankaList.count == 1)
        #expect(viewModel.tankaList[0].id == "t2")
        #expect(mock.reportCallCount == 1)
        #expect(mock.reportLastReason == .inappropriate)
    }

    @Test
    func report_failure_setsError() async {
        let mock = MockTankaRepository()
        mock.stubbedFeedResponse = FeedResponse(
            tankaList: [Tanka.mock()],
            hasMore: false,
            nextCursor: nil
        )
        let viewModel = FeedViewModel(tankaRepository: mock)
        await viewModel.loadFeed()
        mock.stubbedError = NetworkError.serverError(statusCode: 500)

        await viewModel.report(tankaID: "tanka-1", reason: .spam)

        #expect(viewModel.error != nil)
        #expect(viewModel.tankaList.count == 1)
    }

    @Test
    func report_otherReason_passesCorrectReason() async {
        let mock = MockTankaRepository()
        mock.stubbedFeedResponse = FeedResponse(
            tankaList: [Tanka.mock(id: "t1")],
            hasMore: false,
            nextCursor: nil
        )
        let viewModel = FeedViewModel(tankaRepository: mock)
        await viewModel.loadFeed()

        await viewModel.report(tankaID: "t1", reason: .other)

        #expect(mock.reportLastReason == .other)
        #expect(viewModel.tankaList.isEmpty)
    }

    // MARK: - blockUser

    @Test
    func blockUser_success_removesAllTankaByAuthor() async {
        let mock = MockTankaRepository()
        mock.stubbedFeedResponse = FeedResponse(
            tankaList: [
                Tanka.mock(id: "t1", authorID: "author-a"),
                Tanka.mock(id: "t2", authorID: "author-a"),
                Tanka.mock(id: "t3", authorID: "author-b"),
            ],
            hasMore: false,
            nextCursor: nil
        )
        let viewModel = FeedViewModel(tankaRepository: mock)
        await viewModel.loadFeed()

        await viewModel.blockUser(authorID: "author-a")

        #expect(viewModel.tankaList.count == 1)
        #expect(viewModel.tankaList[0].id == "t3")
        #expect(mock.blockUserCallCount == 1)
        #expect(mock.blockUserLastUserID == "author-a")
    }

    @Test
    func blockUser_failure_setsError() async {
        let mock = MockTankaRepository()
        mock.stubbedFeedResponse = FeedResponse(
            tankaList: [Tanka.mock()],
            hasMore: false,
            nextCursor: nil
        )
        let viewModel = FeedViewModel(tankaRepository: mock)
        await viewModel.loadFeed()
        mock.stubbedError = NetworkError.noConnection

        await viewModel.blockUser(authorID: "author-1")

        #expect(viewModel.error != nil)
        #expect(viewModel.tankaList.count == 1)
    }
}
