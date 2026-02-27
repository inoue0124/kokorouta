import FirebaseCore
import SwiftUI

@main
struct MainApp: SwiftUI.App {
    init() {
        #if !DEBUG
            FirebaseApp.configure()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(Color.appBackground.ignoresSafeArea())
        }
    }
}
