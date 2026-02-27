@testable import App
import Testing

@MainActor
struct ComposeViewModelTests {
    // MARK: - isValid

    @Test
    func isValid_noCategoryNoText_returnsFalse() {
        let viewModel = ComposeViewModel()
        #expect(viewModel.isValid == false)
    }

    @Test
    func isValid_categorySelectedButTooShort_returnsFalse() {
        let viewModel = ComposeViewModel()
        viewModel.selectCategory(.work)
        viewModel.worryText = "短い文"
        #expect(viewModel.isValid == false)
    }

    @Test
    func isValid_noCategoryButValidText_returnsFalse() {
        let viewModel = ComposeViewModel()
        viewModel.worryText = "これは十文字以上のテスト文章です"
        #expect(viewModel.isValid == false)
    }

    @Test
    func isValid_categoryAndExactly10Chars_returnsTrue() {
        let viewModel = ComposeViewModel()
        viewModel.selectCategory(.love)
        viewModel.worryText = String(repeating: "あ", count: 10)
        #expect(viewModel.isValid == true)
    }

    @Test
    func isValid_categoryAnd200Chars_returnsTrue() {
        let viewModel = ComposeViewModel()
        viewModel.selectCategory(.health)
        viewModel.worryText = String(repeating: "あ", count: 200)
        #expect(viewModel.isValid == true)
    }

    @Test
    func isValid_categoryAnd300Chars_returnsTrue() {
        let viewModel = ComposeViewModel()
        viewModel.selectCategory(.health)
        viewModel.worryText = String(repeating: "あ", count: 300)
        #expect(viewModel.isValid == true)
    }

    @Test
    func isValid_categoryAnd301Chars_returnsFalse() {
        let viewModel = ComposeViewModel()
        viewModel.selectCategory(.relationship)
        viewModel.worryText = String(repeating: "あ", count: 301)
        #expect(viewModel.isValid == false)
    }

    // MARK: - characterCount

    @Test
    func characterCount_emptyText_returnsZero() {
        let viewModel = ComposeViewModel()
        #expect(viewModel.characterCount == 0)
    }

    @Test
    func characterCount_withText_returnsCorrectCount() {
        let viewModel = ComposeViewModel()
        viewModel.worryText = "テスト"
        #expect(viewModel.characterCount == 3)
    }

    // MARK: - validationMessage

    @Test
    func validationMessage_emptyState_returnsNil() {
        let viewModel = ComposeViewModel()
        #expect(viewModel.validationMessage == nil)
    }

    @Test
    func validationMessage_noCategoryWithText_showsCategoryMessage() {
        let viewModel = ComposeViewModel()
        viewModel.worryText = "テスト"
        #expect(viewModel.validationMessage == "カテゴリを選んでください")
    }

    @Test
    func validationMessage_tooShortText_showsShortMessage() {
        let viewModel = ComposeViewModel()
        viewModel.selectCategory(.work)
        viewModel.worryText = "短い"
        #expect(viewModel.validationMessage == "もう少し詳しく教えてください")
    }

    @Test
    func validationMessage_validInput_returnsNil() {
        let viewModel = ComposeViewModel()
        viewModel.selectCategory(.work)
        viewModel.worryText = "これは十文字以上のテスト文章です"
        #expect(viewModel.validationMessage == nil)
    }

    @Test
    func validationMessage_exactly9Chars_showsShortMessage() {
        let viewModel = ComposeViewModel()
        viewModel.selectCategory(.love)
        viewModel.worryText = String(repeating: "あ", count: 9)
        #expect(viewModel.validationMessage == "もう少し詳しく教えてください")
    }

    @Test
    func validationMessage_exactly10Chars_returnsNil() {
        let viewModel = ComposeViewModel()
        viewModel.selectCategory(.love)
        viewModel.worryText = String(repeating: "あ", count: 10)
        #expect(viewModel.validationMessage == nil)
    }

    // MARK: - selectCategory

    @Test
    func selectCategory_updatesSelectedCategory() {
        let viewModel = ComposeViewModel()
        viewModel.selectCategory(.health)
        #expect(viewModel.selectedCategory == .health)
    }

    @Test
    func selectCategory_changesCategory() {
        let viewModel = ComposeViewModel()
        viewModel.selectCategory(.work)
        viewModel.selectCategory(.love)
        #expect(viewModel.selectedCategory == .love)
    }

    // MARK: - placeholderText

    @Test
    func placeholderText_noCategory_returnsDefault() {
        let viewModel = ComposeViewModel()
        #expect(viewModel.placeholderText == "ここにお悩みを入力してください")
    }

    @Test
    func placeholderText_withCategory_returnsCategoryPlaceholder() {
        let viewModel = ComposeViewModel()
        viewModel.selectCategory(.work)
        #expect(viewModel.placeholderText == WorryCategory.work.placeholderText)
    }

    @Test
    func placeholderText_changesWithCategory() {
        let viewModel = ComposeViewModel()
        viewModel.selectCategory(.love)
        #expect(viewModel.placeholderText == WorryCategory.love.placeholderText)
        viewModel.selectCategory(.health)
        #expect(viewModel.placeholderText == WorryCategory.health.placeholderText)
    }

    // MARK: - isRateLimited

    @Test
    func isRateLimited_initialState_returnsFalse() {
        let viewModel = ComposeViewModel()
        #expect(viewModel.isRateLimited == false)
    }

    @Test
    func isRateLimited_afterRateLimitError_returnsTrue() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.rateLimited
        let viewModel = ComposeViewModel(tankaRepository: mock)
        viewModel.selectCategory(.work)
        viewModel.worryText = "テスト悩みのテキストです"

        await viewModel.submitTanka()

        #expect(viewModel.isRateLimited == true)
    }

    @Test
    func isRateLimited_afterNonRateLimitError_returnsFalse() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.noConnection
        let viewModel = ComposeViewModel(tankaRepository: mock)
        viewModel.selectCategory(.work)
        viewModel.worryText = "テスト悩みのテキストです"

        await viewModel.submitTanka()

        #expect(viewModel.isRateLimited == false)
    }

    // MARK: - Initial state

    @Test
    func initialState_hasCorrectDefaults() {
        let viewModel = ComposeViewModel()

        #expect(viewModel.selectedCategory == nil)
        #expect(viewModel.worryText.isEmpty)
        #expect(viewModel.isShowingConfirmation == false)
        #expect(viewModel.phase.isInput)
        #expect(viewModel.generatedTanka == nil)
        #expect(viewModel.characterCount == 0)
        #expect(viewModel.isValid == false)
    }

    // MARK: - submitTanka guard

    @Test
    func submitTanka_withoutCategory_doesNothing() async {
        let mock = MockTankaRepository()
        let viewModel = ComposeViewModel(tankaRepository: mock)
        viewModel.worryText = "テスト悩みのテキストです"

        await viewModel.submitTanka()

        #expect(viewModel.phase.isInput)
        #expect(mock.generateTankaCallCount == 0)
    }

    // MARK: - Phase transitions

    @Test
    func resetToInput_afterError_restoresInputPhase() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.noConnection
        let viewModel = ComposeViewModel(tankaRepository: mock)
        viewModel.selectCategory(.work)
        viewModel.worryText = "テスト悩みのテキストです"

        await viewModel.submitTanka()
        #expect(!viewModel.phase.isInput)

        viewModel.resetToInput()
        #expect(viewModel.phase.isInput)
    }

    @Test
    func resetToInput_afterResult_restoresInputPhase() async {
        let mock = MockTankaRepository()
        mock.stubbedGeneratedTanka = Tanka.mock()
        let viewModel = ComposeViewModel(tankaRepository: mock)
        viewModel.selectCategory(.love)
        viewModel.worryText = "テスト悩みのテキストです"

        await viewModel.submitTanka()
        if case .result = viewModel.phase {
            // OK
        } else {
            Issue.record("Expected .result phase")
        }

        viewModel.resetToInput()
        #expect(viewModel.phase.isInput)
    }
}
