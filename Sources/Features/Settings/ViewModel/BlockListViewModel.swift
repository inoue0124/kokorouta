import Foundation

@Observable
@MainActor
final class BlockListViewModel {
    private(set) var blockedUsers: [BlockedUser] = []
    private(set) var isLoading = false
    private(set) var error: AppError?

    private let tankaRepository: any TankaRepositoryProtocol

    init(tankaRepository: any TankaRepositoryProtocol) {
        self.tankaRepository = tankaRepository
    }

    func loadBlockedUsers() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            blockedUsers = try await tankaRepository.fetchBlockedUsers()
        } catch {
            self.error = AppError(error)
        }
    }

    func unblock(userID: String) async {
        do {
            try await tankaRepository.unblockUser(userID: userID)
            blockedUsers.removeAll { $0.blockedID == userID }
        } catch {
            self.error = AppError(error)
        }
    }
}
