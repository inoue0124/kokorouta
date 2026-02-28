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
    private var likingTankaIDs: Set<String> = []

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
        guard !likingTankaIDs.contains(tanka.id),
              let index = tankaList.firstIndex(where: { $0.id == tanka.id })
        else { return }

        likingTankaIDs.insert(tanka.id)
        defer { likingTankaIDs.remove(tanka.id) }

        let wasLiked = tanka.isLikedByMe
        let previousCount = tanka.likeCount

        if wasLiked {
            // Optimistic: リストから即座に削除
            tankaList.remove(at: index)
        } else {
            // Optimistic: いいね状態を即座に反映
            tankaList[index].isLikedByMe = true
            tankaList[index].likeCount = previousCount + 1
        }

        do {
            let response = if wasLiked {
                try await tankaRepository.unlike(tankaID: tanka.id)
            } else {
                try await tankaRepository.like(tankaID: tanka.id)
            }
            // サーバー値で同期
            if !wasLiked, let current = tankaList.firstIndex(where: { $0.id == tanka.id }) {
                tankaList[current].likeCount = response.likeCount
            }
        } catch {
            // ロールバック
            if wasLiked {
                var restored = tanka
                restored.isLikedByMe = true
                restored.likeCount = previousCount
                tankaList.insert(restored, at: min(index, tankaList.count))
            } else if let current = tankaList.firstIndex(where: { $0.id == tanka.id }) {
                tankaList[current].isLikedByMe = false
                tankaList[current].likeCount = previousCount
            }
            self.error = AppError(error)
        }
    }
}
