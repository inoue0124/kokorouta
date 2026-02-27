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
    func isValid_categoryAnd201Chars_returnsFalse() {
        let viewModel = ComposeViewModel()
        viewModel.selectCategory(.relationship)
        viewModel.worryText = String(repeating: "あ", count: 201)
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
}
