import Foundation

protocol DailyLimitServiceProtocol: Sendable {
    func hasCreatedToday() -> Bool
    func recordCreation()
    func nextAvailableDate() -> Date?
}

final class DailyLimitService: DailyLimitServiceProtocol, @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let key = "lastTankaCreationDate"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func hasCreatedToday() -> Bool {
        guard let lastDate = userDefaults.object(forKey: key) as? Date else {
            return false
        }
        return Calendar.current.isDateInToday(lastDate)
    }

    func recordCreation() {
        userDefaults.set(Date(), forKey: key)
    }

    func nextAvailableDate() -> Date? {
        guard hasCreatedToday() else { return nil }
        return Calendar.current.startOfDay(for: Date()).addingTimeInterval(24 * 60 * 60)
    }
}

#if DEBUG
    final class PreviewDailyLimitService: DailyLimitServiceProtocol, @unchecked Sendable {
        var stubbedHasCreatedToday = false

        func hasCreatedToday() -> Bool {
            stubbedHasCreatedToday
        }

        func recordCreation() {
            stubbedHasCreatedToday = true
        }

        func nextAvailableDate() -> Date? {
            guard stubbedHasCreatedToday else { return nil }
            return Calendar.current.startOfDay(for: Date()).addingTimeInterval(24 * 60 * 60)
        }
    }
#endif
