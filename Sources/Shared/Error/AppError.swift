import Foundation

enum AppError: Error, Sendable, LocalizedError {
    case network(NetworkError)
    case validation(String)
    case rateLimited(nextAvailableAt: Date)
    case authentication
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .network:
            "接続できませんでした"
        case let .validation(message):
            message
        case .rateLimited:
            "今日はもう短歌を詠みました"
        case .authentication:
            "認証に失敗しました"
        case .unknown:
            "エラーが発生しました"
        }
    }

    init(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .rateLimited:
                self = .rateLimited(nextAvailableAt: Calendar.current.startOfDay(
                    for: Date()
                ).addingTimeInterval(24 * 60 * 60))
            case let .invalidArgument(message):
                self = .validation(message)
            default:
                self = .network(networkError)
            }
        } else if let appError = error as? Self {
            self = appError
        } else {
            let nsError = error as NSError
            if nsError.domain == "FIRFirestoreErrorDomain" {
                switch nsError.code {
                case 7: // PERMISSION_DENIED
                    self = .network(.unauthorized)
                case 14: // UNAVAILABLE
                    self = .network(.noConnection)
                case 4: // DEADLINE_EXCEEDED
                    self = .network(.timeout)
                default:
                    self = .unknown(error.localizedDescription)
                }
            } else {
                self = .unknown(error.localizedDescription)
            }
        }
    }
}
