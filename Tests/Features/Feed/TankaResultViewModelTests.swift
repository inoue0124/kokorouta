@testable import App
import Testing

@MainActor
struct TankaResultViewModelTests {
    @Test
    func generateTanka_success_setsGeneratedTanka() async {
        let mock = MockTankaRepository()
        let expectedTanka = Tanka.mock()
        mock.stubbedGeneratedTanka = expectedTanka
        let viewModel = TankaResultViewModel(tankaRepository: mock)

        await viewModel.generateTanka(category: .work, worryText: "テスト悩み")

        #expect(viewModel.generatedTanka?.id == expectedTanka.id)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
        #expect(mock.generateTankaCallCount == 1)
    }

    @Test
    func generateTanka_failure_setsError() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.serverError(statusCode: 500)
        let viewModel = TankaResultViewModel(tankaRepository: mock)

        await viewModel.generateTanka(category: .love, worryText: "テスト")

        #expect(viewModel.generatedTanka == nil)
        #expect(viewModel.error != nil)
        #expect(viewModel.isLoading == false)
    }

    @Test
    func generateTanka_retry_clearsError() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.noConnection
        let viewModel = TankaResultViewModel(tankaRepository: mock)

        await viewModel.generateTanka(category: .work, worryText: "テスト")
        #expect(viewModel.error != nil)

        mock.stubbedError = nil
        mock.stubbedGeneratedTanka = Tanka.mock()
        await viewModel.generateTanka(category: .work, worryText: "テスト")

        #expect(viewModel.error == nil)
        #expect(viewModel.generatedTanka != nil)
    }
}
