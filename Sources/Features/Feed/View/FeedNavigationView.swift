import SwiftUI

struct FeedNavigationView: View {
    @State private var path = NavigationPath()
    @State private var hasReachedDailyLimit = false

    var body: some View {
        NavigationStack(path: $path) {
            FeedView(path: $path, hasReachedDailyLimit: hasReachedDailyLimit)
                .navigationDestination(for: FeedRoute.self) { route in
                    switch route {
                    case .compose:
                        ComposeView(path: $path)
                    case let .tankaResult(category, worryText):
                        TankaResultView(
                            category: category,
                            worryText: worryText,
                            path: $path,
                            hasReachedDailyLimit: $hasReachedDailyLimit
                        )
                    }
                }
        }
    }
}

#Preview {
    FeedNavigationView()
}
