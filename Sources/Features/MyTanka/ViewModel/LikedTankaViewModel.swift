import Foundation

@Observable
@MainActor
final class LikedTankaViewModel {
    // MARK: - State

    private(set) var tankaList: [Tanka] = []
    private(set) var isLoading = false
    private(set) var error: AppError?

    // MARK: - Dependencies

    private let tankaRepository: any TankaRepositoryProtocol

    // MARK: - Init

    init(tankaRepository: any TankaRepositoryProtocol) {
        self.tankaRepository = tankaRepository
    }

    // MARK: - Actions

    func loadLikedTanka() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            tankaList = try await tankaRepository.fetchLikedTanka()
        } catch {
            self.error = AppError(error)
        }
    }

    func toggleLike(for tanka: Tanka) async {
        guard let index = tankaList.firstIndex(where: { $0.id == tanka.id }) else { return }
        do {
            if tanka.isLikedByMe {
                _ = try await tankaRepository.unlike(tankaID: tanka.id)
                tankaList.remove(at: index)
            } else {
                let response = try await tankaRepository.like(tankaID: tanka.id)
                tankaList[index].isLikedByMe = true
                tankaList[index].likeCount = response.likeCount
            }
        } catch {
            self.error = AppError(error)
        }
    }
}
