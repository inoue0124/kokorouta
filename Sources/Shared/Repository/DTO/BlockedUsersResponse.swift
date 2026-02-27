import Foundation

struct BlockedUsersResponse: Codable, Sendable {
    let blockedUsers: [BlockedUser]
}
