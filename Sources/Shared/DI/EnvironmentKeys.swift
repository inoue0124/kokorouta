import SwiftUI

extension EnvironmentValues {
    #if DEBUG
        @Entry var tankaRepository: any TankaRepositoryProtocol = PreviewTankaRepository()
        @Entry var dailyLimitService: any DailyLimitServiceProtocol = PreviewDailyLimitService()
    #else
        @Entry var tankaRepository: any TankaRepositoryProtocol = TankaRepository()
        @Entry var dailyLimitService: any DailyLimitServiceProtocol = DailyLimitService()
    #endif
}
