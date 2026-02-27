import Foundation

struct GenerateTankaRequest: Codable, Sendable {
    let category: WorryCategory
    let worryText: String
}
