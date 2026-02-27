import Foundation

@Observable
@MainActor
final class MyTankaViewModel {
    private(set) var tankaList: [Tanka] = []
    private(set) var isLoading = false
    private(set) var error: AppError?

    private let tankaRepository: any TankaRepositoryProtocol

    init(tankaRepository: any TankaRepositoryProtocol) {
        self.tankaRepository = tankaRepository
    }

    func loadMyTanka() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            tankaList = try await tankaRepository.fetchMyTanka()
        } catch {
            self.error = AppError(error)
        }
    }
}
