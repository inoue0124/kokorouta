import FirebaseAuth
import FirebaseCore
import SwiftUI

@main
struct MainApp: SwiftUI.App {
    @State private var isAuthReady = false

    init() {
        FirebaseApp.configure()

        #if DEBUG
            Auth.auth().useEmulator(withHost: "localhost", port: 9099)
        #endif
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
