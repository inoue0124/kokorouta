@preconcurrency import FirebaseAuth
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
        } catch {
            self.error = AppError(error)
            return
        }
        try? Auth.auth().signOut()
        isDeleted = true
        NotificationCenter.default.post(name: .accountDidDelete, object: nil)
    }
}
