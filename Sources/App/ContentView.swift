import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .feed

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedNavigationView()
                .tag(AppTab.feed)
                .tabItem {
                    Label(AppTab.feed.rawValue, systemImage: AppTab.feed.systemImage)
                }

            NavigationStack {
                MyTankaView(selectedTab: $selectedTab)
            }
            .tag(AppTab.myTanka)
            .tabItem {
                Label(AppTab.myTanka.rawValue, systemImage: AppTab.myTanka.systemImage)
            }

            NavigationStack {
                SettingsView()
                    .navigationDestination(for: SettingsRoute.self) { route in
                        switch route {
                        case .blockList:
                            BlockListView()
                        case .accountDelete:
                            AccountDeleteView()
                        }
                    }
            }
            .tag(AppTab.settings)
            .tabItem {
                Label(AppTab.settings.rawValue, systemImage: AppTab.settings.systemImage)
            }
        }
        .tint(Color.appText)
    }
}

#Preview {
    ContentView()
}
