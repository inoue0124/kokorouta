import SwiftUI

extension EnvironmentValues {
    #if DEBUG
        @Entry var tankaRepository: any TankaRepositoryProtocol = PreviewTankaRepository()
    #else
        @Entry var tankaRepository: any TankaRepositoryProtocol = TankaRepository()
    #endif
}
