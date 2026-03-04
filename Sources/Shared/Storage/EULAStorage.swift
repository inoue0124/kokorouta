import Foundation

enum EULAStorage {
    static let key = "hasAgreedToEULA"

    static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
