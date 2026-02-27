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
}
