@testable import App
import Testing

@MainActor
struct LikedTankaViewModelTests {
    @Test
    func loadLikedTanka_success_updatesTankaList() async {
        let mock = MockTankaRepository()
        mock.stubbedLikedTankaList = [
            Tanka.mock(id: "liked-1", isLikedByMe: true),
            Tanka.mock(id: "liked-2", isLikedByMe: true),
        ]
        let viewModel = LikedTankaViewModel(tankaRepository: mock)

        await viewModel.loadLikedTanka()

        #expect(viewModel.tankaList.count == 2)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }

    @Test
    func loadLikedTanka_failure_setsError() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.noConnection
        let viewModel = LikedTankaViewModel(tankaRepository: mock)

        await viewModel.loadLikedTanka()

        #expect(viewModel.tankaList.isEmpty)
        #expect(viewModel.error != nil)
        #expect(viewModel.isLoading == false)
    }

    @Test
    func loadLikedTanka_empty_setsEmptyList() async {
        let mock = MockTankaRepository()
        mock.stubbedLikedTankaList = []
        let viewModel = LikedTankaViewModel(tankaRepository: mock)

        await viewModel.loadLikedTanka()

        #expect(viewModel.tankaList.isEmpty)
        #expect(viewModel.error == nil)
    }

    @Test
    func toggleLike_unlike_removesFromList() async {
        let mock = MockTankaRepository()
        mock.stubbedLikedTankaList = [
            Tanka.mock(id: "liked-1", likeCount: 5, isLikedByMe: true),
            Tanka.mock(id: "liked-2", likeCount: 3, isLikedByMe: true),
        ]
        mock.stubbedLikeResponse = LikeResponse(likeCount: 4)
        let viewModel = LikedTankaViewModel(tankaRepository: mock)
        await viewModel.loadLikedTanka()
        #expect(viewModel.tankaList.count == 2)

        await viewModel.toggleLike(for: viewModel.tankaList[0])

        #expect(viewModel.tankaList.count == 1)
        #expect(viewModel.tankaList[0].id == "liked-2")
        #expect(mock.unlikeCallCount == 1)
    }

    @Test
    func toggleLike_unlikeError_setsError() async {
        let mock = MockTankaRepository()
        mock.stubbedLikedTankaList = [
            Tanka.mock(id: "liked-1", likeCount: 5, isLikedByMe: true),
        ]
        let viewModel = LikedTankaViewModel(tankaRepository: mock)
        await viewModel.loadLikedTanka()

        mock.stubbedError = NetworkError.noConnection
        await viewModel.toggleLike(for: viewModel.tankaList[0])

        #expect(viewModel.tankaList.count == 1)
        #expect(viewModel.error != nil)
    }

    @Test
    func initialState_hasCorrectDefaults() {
        let mock = MockTankaRepository()
        let viewModel = LikedTankaViewModel(tankaRepository: mock)

        #expect(viewModel.tankaList.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }

    @Test
    func loadLikedTanka_retry_clearsError() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.serverError(statusCode: 500)
        let viewModel = LikedTankaViewModel(tankaRepository: mock)
        await viewModel.loadLikedTanka()
        #expect(viewModel.error != nil)

        mock.stubbedError = nil
        mock.stubbedLikedTankaList = [Tanka.mock(id: "liked-1", isLikedByMe: true)]
        await viewModel.loadLikedTanka()

        #expect(viewModel.error == nil)
        #expect(viewModel.tankaList.count == 1)
    }
}
