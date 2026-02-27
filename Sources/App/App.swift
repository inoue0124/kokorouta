import FirebaseCore
import SwiftUI

@main
struct MainApp: SwiftUI.App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(Color.appBackground)
        }
    }
}
