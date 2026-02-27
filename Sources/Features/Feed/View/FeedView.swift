import SwiftUI

struct FeedView: View {
    @Environment(\.tankaRepository) private var repository
    @Environment(\.dailyLimitService) private var dailyLimitService
    @Binding var path: NavigationPath
    @State private var viewModel: FeedViewModel?
    @State private var showReportSheet = false
    @State private var showBlockAlert = false
    @State private var hasCreatedToday = false

    var body: some View {
        content
            .background(Color.appBackground)
            .navigationTitle("フィード")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if viewModel == nil {
                    viewModel = FeedViewModel(tankaRepository: repository)
                }
                hasCreatedToday = dailyLimitService.hasCreatedToday()
                await viewModel?.loadFeed()
            }
            .onAppear {
                hasCreatedToday = dailyLimitService.hasCreatedToday()
            }
            .refreshable {
                await viewModel?.loadFeed()
            }
            .sheet(isPresented: $showReportSheet) {
                if let target = viewModel?.reportTarget {
                    ReportSheet(tanka: target) { reason in
                        await viewModel?.report(tankaID: target.id, reason: reason)
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
                EmptyStateView(message: "まだ短歌がありません")
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
                    TankaCard(tanka: tanka) {
                        Task { await viewModel.toggleLike(for: tanka) }
                    }
                    .contextMenu {
                        Button("通報する") {
                            viewModel.reportTarget = tanka
                            showReportSheet = true
                        }
                        Button("ブロックする") {
                            viewModel.blockTarget = tanka
                            showBlockAlert = true
                        }
                    }
                    .onAppear {
                        if tanka.id == viewModel.tankaList.last?.id {
                            Task { await viewModel.loadMore() }
                        }
                    }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .tint(Color.appSubText)
                        .padding()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .overlay(alignment: .bottomTrailing) {
            VStack(alignment: .trailing, spacing: 8) {
                if hasCreatedToday {
                    Text("明日また詠めます")
                        .font(.appCaption())
                        .foregroundStyle(Color.appSubText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.appCardBackground, in: Capsule())
                }
                FloatingActionButton {
                    path.append(FeedRoute.compose)
                }
                .opacity(hasCreatedToday ? 0.4 : 1)
                .disabled(hasCreatedToday)
            }
            .padding(24)
        }
    }
}
