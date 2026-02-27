@testable import App
import Testing

@MainActor
struct ComposeSubmitTests {
    @Test
    func submitTanka_success_setsResultPhase() async {
        let mock = MockTankaRepository()
        let expectedTanka = Tanka.mock()
        mock.stubbedGeneratedTanka = expectedTanka
        let viewModel = ComposeViewModel(tankaRepository: mock)
        viewModel.selectCategory(.work)
        viewModel.worryText = "テスト悩みのテキストです"

        await viewModel.submitTanka()

        #expect(viewModel.generatedTanka?.id == expectedTanka.id)
        if case .result = viewModel.phase {
            // OK
        } else {
            Issue.record("Expected .result phase but got \(viewModel.phase)")
        }
        #expect(mock.generateTankaCallCount == 1)
    }

    @Test
    func submitTanka_failure_setsErrorPhase() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.serverError(statusCode: 500)
        let viewModel = ComposeViewModel(tankaRepository: mock)
        viewModel.selectCategory(.love)
        viewModel.worryText = "テスト悩みのテキストです"

        await viewModel.submitTanka()

        #expect(viewModel.generatedTanka == nil)
        if case .error = viewModel.phase {
            // OK
        } else {
            Issue.record("Expected .error phase but got \(viewModel.phase)")
        }
    }

    @Test
    func submitTanka_retry_clearsError() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.noConnection
        let viewModel = ComposeViewModel(tankaRepository: mock)
        viewModel.selectCategory(.work)
        viewModel.worryText = "テスト悩みのテキストです"

        await viewModel.submitTanka()
        if case .error = viewModel.phase {
            // OK
        } else {
            Issue.record("Expected .error phase")
        }

        mock.stubbedError = nil
        mock.stubbedGeneratedTanka = Tanka.mock()
        await viewModel.retry()

        if case .result = viewModel.phase {
            // OK
        } else {
            Issue.record("Expected .result phase after retry")
        }
        #expect(viewModel.generatedTanka != nil)
    }

    @Test
    func submitTanka_invalidArgument_setsValidationError() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.invalidArgument(message: "もう少し詳しく悩みを書いてください。")
        let viewModel = ComposeViewModel(tankaRepository: mock)
        viewModel.selectCategory(.work)
        viewModel.worryText = "あああああああああああ"

        await viewModel.submitTanka()

        #expect(viewModel.generatedTanka == nil)
        if case .error(let error) = viewModel.phase,
           case let .validation(message) = error {
            #expect(message == "もう少し詳しく悩みを書いてください。")
        } else {
            Issue.record("Expected .validation error but got \(viewModel.phase)")
        }
    }

    @Test
    func submitTanka_invalidArgument_doesNotSetDailyLimit() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.invalidArgument(message: "悩みの内容を具体的に書いてください。")
        let viewModel = ComposeViewModel(tankaRepository: mock)
        viewModel.selectCategory(.health)
        viewModel.worryText = "テストテストテスト"

        await viewModel.submitTanka()

        #expect(viewModel.generatedTanka == nil)
        #expect(viewModel.isRateLimited == false)
    }

    @Test
    func resetToInput_returnsToInputPhase() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.invalidArgument(message: "テスト")
        let viewModel = ComposeViewModel(tankaRepository: mock)
        viewModel.selectCategory(.work)
        viewModel.worryText = "テスト悩みのテキストです"

        await viewModel.submitTanka()
        viewModel.resetToInput()

        #expect(viewModel.phase.isInput)
    }
}
