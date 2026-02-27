import SwiftUI

struct FeedView: View {
    @Environment(\.tankaRepository) private var repository
    @Binding var path: NavigationPath
    let hasReachedDailyLimit: Bool
    @State private var viewModel: FeedViewModel?
    @State private var showReportSheet = false
    @State private var showBlockAlert = false

    var body: some View {
        content
            .background(Color.appBackground)
            .navigationTitle("フィード")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if viewModel == nil {
                    viewModel = FeedViewModel(tankaRepository: repository)
                }
                await viewModel?.loadFeed()
            }
            .refreshable {
                await viewModel?.loadFeed()
            }
            .sheet(isPresented: $showReportSheet) {
                if let target = viewModel?.reportTarget {
                    ReportSheet(tanka: target) { reason in
                        try await viewModel?.report(tankaID: target.id, reason: reason)
                    }
                    .presentationDetents([.medium])
                }
            }
            .alert(
                "このユーザーをブロックしますか？",
                isPresented: $showBlockAlert
            ) {
                Button("キャンセル", role: .cancel) {}
                Button("ブロック", role: .destructive) {
                    if let target = viewModel?.blockTarget {
                        Task {
                            await viewModel?.blockUser(authorID: target.authorID)
                        }
                    }
                }
            } message: {
                Text("このユーザーの短歌がフィードに表示されなくなります")
            }
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel {
            if viewModel.isLoading, viewModel.tankaList.isEmpty {
                LoadingView()
            } else if let error = viewModel.error, viewModel.tankaList.isEmpty {
                ErrorView(error: error) {
                    Task { await viewModel.loadFeed() }
                }
            } else if viewModel.tankaList.isEmpty {
                EmptyStateView(
                    message: "まだ短歌がありません",
                    actionLabel: "最初の短歌を詠む"
                ) {
                    path.append(FeedRoute.compose)
                }
            } else {
                feedList(viewModel: viewModel)
            }
        } else {
            LoadingView()
        }
    }

    private func feedList(viewModel: FeedViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.tankaList) { tanka in
                    tankaRow(tanka: tanka, viewModel: viewModel)
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .tint(Color.appSubText)
                        .padding()
                        .accessibilityLabel("さらに読み込み中")
                }

                if let paginationError = viewModel.paginationError {
                    PaginationErrorView(error: paginationError) {
                        Task { await viewModel.loadMore() }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .overlay(alignment: .bottomTrailing) {
            composeButton
        }
    }

    private func tankaRow(tanka: Tanka, viewModel: FeedViewModel) -> some View {
        TankaCard(tanka: tanka) {
            Task { await viewModel.toggleLike(for: tanka) }
        }
        .contextMenu {
            Button("通報する") {
                viewModel.reportTarget = tanka
                showReportSheet = true
            }
            .accessibilityLabel("この短歌を通報する")
            Button("ブロックする") {
                viewModel.blockTarget = tanka
                showBlockAlert = true
            }
            .accessibilityLabel("この投稿者をブロックする")
        }
        .onAppear {
            if tanka.id == viewModel.tankaList.last?.id {
                Task { await viewModel.loadMore() }
            }
        }
    }

    private var composeButton: some View {
        VStack(spacing: 8) {
            if hasReachedDailyLimit {
                Text("明日また詠めます")
                    .font(.appCaption())
                    .foregroundStyle(Color.appSubText)
            }
            FloatingActionButton {
                path.append(FeedRoute.compose)
            }
            .disabled(hasReachedDailyLimit)
            .opacity(hasReachedDailyLimit ? 0.4 : 1.0)
        }
        .padding(24)
    }
}
