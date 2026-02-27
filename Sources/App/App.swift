import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import SwiftUI

@main
struct MainApp: SwiftUI.App {
    @State private var isAuthReady = false

    static let isEmulator = ProcessInfo.processInfo.environment["USE_EMULATOR"] == "1"

    init() {
        FirebaseApp.configure()

        if Self.isEmulator {
            Auth.auth().useEmulator(withHost: "127.0.0.1", port: 9099)
            let settings = Firestore.firestore().settings
            settings.host = "127.0.0.1:8080"
            settings.isSSLEnabled = false
            settings.cacheSettings = MemoryCacheSettings()
            Firestore.firestore().settings = settings
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isAuthReady {
                    ContentView()
                } else {
                    LoadingView(message: "準備中...")
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .task {
                await signInAnonymously()
            }
        }
    }

    private func signInAnonymously() async {
        if Auth.auth().currentUser != nil {
            isAuthReady = true
            return
        }

        do {
            _ = try await Auth.auth().signInAnonymously()
            isAuthReady = true
        } catch {
            try? await Task.sleep(for: .seconds(2))
            await signInAnonymously()
        }
    }
}
