import Foundation

@Observable
@MainActor
final class TankaResultViewModel {
    private(set) var generatedTanka: Tanka?
    private(set) var isLoading = false
    private(set) var error: AppError?

    private let tankaRepository: any TankaRepositoryProtocol
    private let dailyLimitService: any DailyLimitServiceProtocol

    init(
        tankaRepository: any TankaRepositoryProtocol,
        dailyLimitService: any DailyLimitServiceProtocol
    ) {
        self.tankaRepository = tankaRepository
        self.dailyLimitService = dailyLimitService
    }

    func generateTanka(category: WorryCategory, worryText: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let tanka = try await tankaRepository.generateTanka(
                category: category,
                worryText: worryText
            )
            generatedTanka = tanka
            dailyLimitService.recordCreation()
        } catch {
            self.error = AppError(error)
        }
    }
}
