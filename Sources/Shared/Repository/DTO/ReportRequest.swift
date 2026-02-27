import Foundation

struct ReportRequest: Codable, Sendable {
    let reason: ReportReason
}
