@testable import App
import Foundation

final class MockDailyLimitService: DailyLimitServiceProtocol, @unchecked Sendable {
    var stubbedHasCreatedToday = false
    var recordCreationCallCount = 0

    func hasCreatedToday() -> Bool {
        stubbedHasCreatedToday
    }

    func recordCreation() {
        recordCreationCallCount += 1
        stubbedHasCreatedToday = true
    }

    func nextAvailableDate() -> Date? {
        guard stubbedHasCreatedToday else { return nil }
        return Calendar.current.startOfDay(for: Date()).addingTimeInterval(24 * 60 * 60)
    }
}
