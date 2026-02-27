import Foundation

enum ReportReason: String, Codable, Sendable, CaseIterable {
    case inappropriate
    case spam
    case other

    var displayName: String {
        switch self {
        case .inappropriate: "不適切な内容"
        case .spam: "スパム"
        case .other: "その他"
        }
    }
}
