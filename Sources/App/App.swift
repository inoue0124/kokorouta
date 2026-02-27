import FirebaseAuth
import FirebaseCore
import SwiftUI

@main
struct MainApp: SwiftUI.App {
    @State private var isAuthReady = false

    init() {
        FirebaseApp.configure()

        if ProcessInfo.processInfo.environment["USE_EMULATOR"] == "1" {
            Auth.auth().useEmulator(withHost: "localhost", port: 9099)
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
            // Retry after delay — anonymous auth requires no user interaction
            try? await Task.sleep(for: .seconds(2))
            await signInAnonymously()
        }
    }
}
