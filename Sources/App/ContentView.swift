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
                Text("わたしの歌")
                    .font(.appTitle())
                    .foregroundStyle(Color.appText)
            }
            .tag(AppTab.myTanka)
            .tabItem {
                Label(AppTab.myTanka.rawValue, systemImage: AppTab.myTanka.systemImage)
            }

            NavigationStack {
                Text("設定")
                    .font(.appTitle())
                    .foregroundStyle(Color.appText)
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
