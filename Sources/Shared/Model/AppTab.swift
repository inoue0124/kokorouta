import Foundation

enum AppTab: String, CaseIterable {
    case feed = "フィード"
    case myTanka = "わたしの歌"
    case settings = "設定"

    var systemImage: String {
        switch self {
        case .feed: "square.stack"
        case .myTanka: "book"
        case .settings: "gearshape"
        }
    }
}
