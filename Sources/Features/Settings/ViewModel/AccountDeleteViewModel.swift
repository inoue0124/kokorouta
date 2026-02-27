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
        do {
            try await tankaRepository.deleteAccount()
        } catch {
            self.error = AppError(error)
            isDeleting = false
            return
        }
        // サーバー側のデータ削除は完了済みのため、ローカルのサインアウト失敗は無視する
        try? Auth.auth().signOut()
        isDeleting = false
        isDeleted = true
        // Show confirmation briefly before resetting app
        try? await Task.sleep(for: .seconds(1.5))
        NotificationCenter.default.post(name: .accountDidDelete, object: nil)
    }
}
