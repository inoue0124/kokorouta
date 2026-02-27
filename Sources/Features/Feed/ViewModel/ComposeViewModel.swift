import Foundation

// MARK: - ComposePhase

enum ComposePhase {
    case input
    case loading
    case result(Tanka)
    case error(AppError)

    var isInput: Bool {
        if case .input = self { return true }
        return false
    }

    var discriminator: Int {
        switch self {
        case .input: 0
        case .loading: 1
        case .result: 2
        case .error: 3
        }
    }
}

// MARK: - ComposeViewModel

@Observable
@MainActor
final class ComposeViewModel {
    // MARK: - State

    var selectedCategory: WorryCategory?
    var worryText: String = ""
    private(set) var phase: ComposePhase = .input
    private(set) var generatedTanka: Tanka?

    // MARK: - Dependencies

    private let tankaRepository: any TankaRepositoryProtocol

    // MARK: - Computed

    var characterCount: Int {
        worryText.count
    }

    var isValid: Bool {
        selectedCategory != nil && characterCount >= 10 && characterCount <= 200
    }

    var validationMessage: String? {
        guard selectedCategory == nil || characterCount >= 1 else { return nil }
        if selectedCategory == nil, characterCount >= 1 {
            return "カテゴリを選んでください"
        }
        if characterCount >= 1, characterCount < 10 {
            return "もう少し詳しく教えてください"
        }
        return nil
    }

    var isRateLimited: Bool {
        if case .error(let error) = phase,
           case .rateLimited = error {
            return true
        }
        return false
    }

    // MARK: - Init

    init(tankaRepository: any TankaRepositoryProtocol = TankaRepository()) {
        self.tankaRepository = tankaRepository
    }

    // MARK: - Actions

    func selectCategory(_ category: WorryCategory) {
        selectedCategory = category
    }

    func submitTanka() async {
        guard let category = selectedCategory else { return }
        phase = .loading
        do {
            let tanka = try await tankaRepository.generateTanka(
                category: category,
                worryText: worryText
            )
            generatedTanka = tanka
            phase = .result(tanka)
        } catch {
            phase = .error(AppError(error))
        }
    }

    func retry() async {
        await submitTanka()
    }
}
