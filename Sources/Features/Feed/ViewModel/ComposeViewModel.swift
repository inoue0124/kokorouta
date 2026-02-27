import Foundation

@Observable
@MainActor
final class ComposeViewModel {
    var selectedCategory: WorryCategory?
    var worryText: String = ""

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

    func selectCategory(_ category: WorryCategory) {
        selectedCategory = category
    }
}
