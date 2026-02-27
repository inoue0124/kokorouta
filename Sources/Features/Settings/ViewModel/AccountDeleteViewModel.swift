import Foundation

@Observable
@MainActor
final class AccountDeleteViewModel {
    var confirmationText: String = ""
    private(set) var isDeleting = false
    private(set) var error: AppError?
    private(set) var isDeleted = false

    private let tankaRepository: any TankaRepositoryProtocol

    init(tankaRepository: any TankaRepositoryProtocol) {
        self.tankaRepository = tankaRepository
    }

    var canDelete: Bool {
        confirmationText == "削除"
    }

    func deleteAccount() async {
        isDeleting = true
        error = nil
        defer { isDeleting = false }
        do {
            try await tankaRepository.deleteAccount()
            isDeleted = true
        } catch {
            self.error = AppError(error)
        }
    }
}
