import SwiftUI

extension EnvironmentValues {
    @Entry var tankaRepository: any TankaRepositoryProtocol = TankaRepository()
}
