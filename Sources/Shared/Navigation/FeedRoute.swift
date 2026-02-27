import Foundation

enum FeedRoute: Hashable {
    case compose
    case tankaResult(category: WorryCategory, worryText: String)
}
