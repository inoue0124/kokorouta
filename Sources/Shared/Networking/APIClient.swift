@preconcurrency import FirebaseAuth
@preconcurrency import FirebaseFunctions
import Foundation

final class APIClient: Sendable {
    static let shared = APIClient()

    private let functions: Functions
    private let decoder: JSONDecoder

    init(functions: Functions = Functions.functions(region: "asia-northeast1")) {
        self.functions = functions

        if ProcessInfo.processInfo.environment["USE_EMULATOR"] == "1" {
            self.functions.useEmulator(withHost: "127.0.0.1", port: 5001)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func call<T: Decodable & Sendable>(
        _ functionName: String,
        data: [String: Any]? = nil
    ) async throws -> T {
        do {
            let result = try await functions.httpsCallable(functionName).call(data)

            let json = result.data
            let jsonData = try JSONSerialization.data(withJSONObject: json)
            return try decoder.decode(T.self, from: jsonData)
        } catch let error as NSError {
            throw mapError(error)
        }
    }

    func callVoid(
        _ functionName: String,
        data: [String: Any]? = nil
    ) async throws {
        do {
            _ = try await functions.httpsCallable(functionName).call(data)
        } catch let error as NSError {
            throw mapError(error)
        }
    }

    private func mapError(_ error: NSError) -> NetworkError {
        switch error.code {
        case FunctionsErrorCode.invalidArgument.rawValue:
            .invalidArgument(message: error.localizedDescription)
        case FunctionsErrorCode.unauthenticated.rawValue:
            .unauthorized
        case FunctionsErrorCode.unavailable.rawValue:
            .noConnection
        case FunctionsErrorCode.deadlineExceeded.rawValue:
            .timeout
        case FunctionsErrorCode.resourceExhausted.rawValue:
            .rateLimited
        default:
            .serverError(statusCode: error.code)
        }
    }
}
