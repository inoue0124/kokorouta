import SwiftUI

struct FeedNavigationView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            FeedView(path: $path)
                .navigationDestination(for: FeedRoute.self) { route in
                    switch route {
                    case .compose:
                        ComposeView(path: $path)
                    case let .tankaResult(category, worryText):
                        TankaResultView(
                            category: category,
                            worryText: worryText,
                            path: $path
                        )
                    }
                }
        }
    }
}

#Preview {
    FeedNavigationView()
}
