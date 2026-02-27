import Foundation

enum NetworkError: Error, Sendable {
    case noConnection
    case timeout
    case serverError(statusCode: Int)
    case decodingError
    case unauthorized
    case rateLimited
}
