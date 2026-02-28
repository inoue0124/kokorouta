import SwiftUI

struct LikedTankaView: View {
    @Environment(\.tankaRepository) private var repository
    @State private var viewModel: LikedTankaViewModel?

    var body: some View {
        content
            .background(Color.appBackground)
            .navigationTitle("いいねした短歌")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if viewModel == nil {
                    viewModel = LikedTankaViewModel(tankaRepository: repository)
                }
                await viewModel?.loadLikedTanka()
            }
            .refreshable {
                await viewModel?.loadLikedTanka()
            }
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel {
            likedTankaContent(viewModel: viewModel)
        } else {
            LoadingView()
        }
    }

    @ViewBuilder
    private func likedTankaContent(viewModel: LikedTankaViewModel) -> some View {
        if viewModel.isLoading, viewModel.tankaList.isEmpty {
            LoadingView()
        } else if let error = viewModel.error, viewModel.tankaList.isEmpty {
            ErrorView(error: error) {
                Task { await viewModel.loadLikedTanka() }
            }
        } else if viewModel.tankaList.isEmpty {
            EmptyStateView(
                message: "いいねした短歌はまだありません"
            )
        } else {
            tankaList(viewModel: viewModel)
        }
    }

    private func tankaList(viewModel: LikedTankaViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.tankaList) { tanka in
                    TankaCard(tanka: tanka) {
                        Task { await viewModel.toggleLike(for: tanka) }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}
