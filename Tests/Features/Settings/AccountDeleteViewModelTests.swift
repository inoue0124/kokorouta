@testable import App
import Testing

@MainActor
struct AccountDeleteViewModelTests {
    // MARK: - canDelete

    @Test
    func canDelete_emptyText_returnsFalse() {
        let mock = MockTankaRepository()
        let viewModel = AccountDeleteViewModel(tankaRepository: mock)
        #expect(viewModel.canDelete == false)
    }

    @Test
    func canDelete_wrongText_returnsFalse() {
        let mock = MockTankaRepository()
        let viewModel = AccountDeleteViewModel(tankaRepository: mock)
        viewModel.confirmationText = "消去"
        #expect(viewModel.canDelete == false)
    }

    @Test
    func canDelete_correctText_returnsTrue() {
        let mock = MockTankaRepository()
        let viewModel = AccountDeleteViewModel(tankaRepository: mock)
        viewModel.confirmationText = "削除"
        #expect(viewModel.canDelete == true)
    }

    @Test
    func canDelete_textWithSpaces_returnsFalse() {
        let mock = MockTankaRepository()
        let viewModel = AccountDeleteViewModel(tankaRepository: mock)
        viewModel.confirmationText = "削除 "
        #expect(viewModel.canDelete == false)
    }

    // MARK: - deleteAccount

    @Test
    func deleteAccount_success_setsIsDeleted() async {
        let mock = MockTankaRepository()
        let viewModel = AccountDeleteViewModel(tankaRepository: mock)

        await viewModel.deleteAccount()

        #expect(viewModel.isDeleted == true)
        #expect(viewModel.isDeleting == false)
        #expect(viewModel.error == nil)
        #expect(mock.deleteAccountCallCount == 1)
    }

    @Test
    func deleteAccount_failure_setsError() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.noConnection
        let viewModel = AccountDeleteViewModel(tankaRepository: mock)

        await viewModel.deleteAccount()

        #expect(viewModel.isDeleted == false)
        #expect(viewModel.error != nil)
        #expect(viewModel.isDeleting == false)
    }

    @Test
    func deleteAccount_retry_clearsError() async {
        let mock = MockTankaRepository()
        mock.stubbedError = NetworkError.serverError(statusCode: 500)
        let viewModel = AccountDeleteViewModel(tankaRepository: mock)
        await viewModel.deleteAccount()
        #expect(viewModel.error != nil)

        mock.stubbedError = nil
        await viewModel.deleteAccount()

        #expect(viewModel.error == nil)
        #expect(viewModel.isDeleted == true)
    }
}
