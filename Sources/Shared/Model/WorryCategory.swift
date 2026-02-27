import Foundation

enum WorryCategory: String, Codable, Sendable, CaseIterable {
    case relationship
    case love
    case work
    case health
    case other

    var displayName: String {
        switch self {
        case .relationship: "人間関係"
        case .love: "恋愛"
        case .work: "仕事"
        case .health: "健康"
        case .other: "その他"
        }
    }

    var placeholderText: String {
        switch self {
        case .relationship: "例: 職場の同僚と意見が合わず、距離を感じています"
        case .love: "例: 好きな人に気持ちを伝えたいけれど、勇気が出ません"
        case .work: "例: 転職すべきか今の仕事を続けるべきか迷っています"
        case .health: "例: 最近眠れない日が続いていて、体調が優れません"
        case .other: "例: 最近気になっていることがあり、誰かに聞いてほしいです"
        }
    }
}
