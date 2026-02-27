import Foundation

struct FeedResponse: Codable, Sendable {
    let tankaList: [Tanka]
    let hasMore: Bool
    let nextCursor: String?
}
