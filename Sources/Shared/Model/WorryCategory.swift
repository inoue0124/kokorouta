import Foundation

enum WorryCategory: String, Codable, Sendable, CaseIterable {
    case relationship
    case love
    case work
    case health

    var displayName: String {
        switch self {
        case .relationship: "人間関係"
        case .love: "恋愛"
        case .work: "仕事"
        case .health: "健康"
        }
    }
}
