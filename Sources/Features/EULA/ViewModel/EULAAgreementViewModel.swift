import Foundation

@Observable
@MainActor
final class EULAAgreementViewModel {
    private(set) var isAgreed = false

    func agree() {
        UserDefaults.standard.set(true, forKey: "hasAgreedToEULA")
        isAgreed = true
    }

    static func resetAgreement() {
        UserDefaults.standard.removeObject(forKey: "hasAgreedToEULA")
    }
}
