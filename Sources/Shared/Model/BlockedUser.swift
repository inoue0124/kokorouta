import Foundation

struct BlockedUser: Codable, Sendable, Identifiable {
    let id: String
    let blockedID: String
    let createdAt: Date
}
