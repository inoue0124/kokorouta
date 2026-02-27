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

    @Test
    func generateTanka_invalidArgument_setsValidationError() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.invalidArgument(message: "もう少し詳しく悩みを書いてください。")
        let viewModel = TankaResultViewModel(tankaRepository: mock)

        await viewModel.generateTanka(category: .work, worryText: "あああああああああああ")

        #expect(viewModel.generatedTanka == nil)
        #expect(viewModel.isLoading == false)
        if case let .validation(message) = viewModel.error {
            #expect(message == "もう少し詳しく悩みを書いてください。")
        } else {
            Issue.record("Expected .validation error but got \(String(describing: viewModel.error))")
        }
    }

    @Test
    func generateTanka_invalidArgument_doesNotSetDailyLimit() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.invalidArgument(message: "悩みの内容を具体的に書いてください。")
        let viewModel = TankaResultViewModel(tankaRepository: mock)

        await viewModel.generateTanka(category: .health, worryText: "テストテストテスト")

        #expect(viewModel.generatedTanka == nil)
        if case .rateLimited = viewModel.error {
            Issue.record("Should not be rateLimited error")
        }
    }
}
