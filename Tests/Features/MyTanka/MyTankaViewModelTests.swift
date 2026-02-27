@testable import App
import Testing

@MainActor
struct MyTankaViewModelTests {
    @Test
    func loadMyTanka_success_updatesTankaList() async {
        let mock = MockTankaRepository()
        mock.stubbedMyTankaList = [Tanka.mock(id: "my-1"), Tanka.mock(id: "my-2")]
        let viewModel = MyTankaViewModel(tankaRepository: mock)

        await viewModel.loadMyTanka()

        #expect(viewModel.tankaList.count == 2)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }

    @Test
    func loadMyTanka_failure_setsError() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.noConnection
        let viewModel = MyTankaViewModel(tankaRepository: mock)

        await viewModel.loadMyTanka()

        #expect(viewModel.tankaList.isEmpty)
        #expect(viewModel.error != nil)
        #expect(viewModel.isLoading == false)
    }

    @Test
    func loadMyTanka_empty_setsEmptyList() async {
        let mock = MockTankaRepository()
        mock.stubbedMyTankaList = []
        let viewModel = MyTankaViewModel(tankaRepository: mock)

        await viewModel.loadMyTanka()

        #expect(viewModel.tankaList.isEmpty)
        #expect(viewModel.error == nil)
    }

    @Test
    func loadMyTanka_refresh_replacesExistingData() async {
        let mock = MockTankaRepository()
        mock.stubbedMyTankaList = [Tanka.mock(id: "old-1")]
        let viewModel = MyTankaViewModel(tankaRepository: mock)
        await viewModel.loadMyTanka()
        #expect(viewModel.tankaList.count == 1)

        mock.stubbedMyTankaList = [Tanka.mock(id: "new-1"), Tanka.mock(id: "new-2")]
        await viewModel.loadMyTanka()

        #expect(viewModel.tankaList.count == 2)
        #expect(viewModel.tankaList[0].id == "new-1")
    }

    @Test
    func loadMyTanka_retry_clearsError() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.serverError(statusCode: 500)
        let viewModel = MyTankaViewModel(tankaRepository: mock)
        await viewModel.loadMyTanka()
        #expect(viewModel.error != nil)

        mock.stubbedError = nil
        mock.stubbedMyTankaList = [Tanka.mock()]
        await viewModel.loadMyTanka()

        #expect(viewModel.error == nil)
        #expect(viewModel.tankaList.count == 1)
    }

    @Test
    func initialState_hasCorrectDefaults() {
        let mock = MockTankaRepository()
        let viewModel = MyTankaViewModel(tankaRepository: mock)

        #expect(viewModel.tankaList.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }

    @Test
    func loadMyTanka_multipleTanka_preservesOrder() async {
        let mock = MockTankaRepository()
        mock.stubbedMyTankaList = [
            Tanka.mock(id: "a"),
            Tanka.mock(id: "b"),
            Tanka.mock(id: "c"),
        ]
        let viewModel = MyTankaViewModel(tankaRepository: mock)

        await viewModel.loadMyTanka()

        #expect(viewModel.tankaList.count == 3)
        #expect(viewModel.tankaList[0].id == "a")
        #expect(viewModel.tankaList[1].id == "b")
        #expect(viewModel.tankaList[2].id == "c")
    }
}
