import SwiftUI

struct FeedNavigationView: View {
    @Environment(\.tankaRepository) private var repository
    @State private var path = NavigationPath()
    @State private var hasReachedDailyLimit = false

    var body: some View {
        NavigationStack(path: $path) {
            FeedView(path: $path, hasReachedDailyLimit: hasReachedDailyLimit)
                .navigationDestination(for: FeedRoute.self) { route in
                    switch route {
                    case .compose:
                        ComposeView(
                            path: $path,
                            hasReachedDailyLimit: $hasReachedDailyLimit
                        )
                    }
                }
        }
        .task {
            await checkDailyLimit()
        }
    }

    private func checkDailyLimit() async {
        do {
            let myTankaList = try await repository.fetchMyTanka()
            let calendar = Calendar.current
            let hasCreatedToday = myTankaList.contains { tanka in
                calendar.isDateInToday(tanka.createdAt)
            }
            if hasCreatedToday {
                hasReachedDailyLimit = true
            }
        } catch {
            // 取得に失敗した場合はボタンを有効のままにする（サーバー側でも制限される）
        }
    }
}

#Preview {
    FeedNavigationView()
}
