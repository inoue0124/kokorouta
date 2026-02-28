import SwiftUI

struct MyTankaView: View {
    @Environment(\.tankaRepository) private var repository
    @Binding var selectedTab: AppTab
    @State private var viewModel: MyTankaViewModel?

    var body: some View {
        content
            .background(Color.appBackground)
            .navigationTitle("わたしの歌")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if viewModel == nil {
                    viewModel = MyTankaViewModel(tankaRepository: repository)
                }
                await viewModel?.loadMyTanka()
            }
            .refreshable {
                await viewModel?.loadMyTanka()
            }
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel {
            if viewModel.isLoading, viewModel.tankaList.isEmpty {
                LoadingView()
            } else if let error = viewModel.error, viewModel.tankaList.isEmpty {
                ErrorView(error: error) {
                    Task { await viewModel.loadMyTanka() }
                }
            } else if viewModel.tankaList.isEmpty {
                VStack(spacing: 24) {
                    likedTankaLink
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    EmptyStateView(
                        message: "まだ短歌がありません。\n今日の悩みを詠んでみましょう",
                        actionLabel: "詠んでみる"
                    ) {
                        selectedTab = .feed
                    }
                }
            } else {
                tankaList(viewModel: viewModel)
            }
        } else {
            LoadingView()
        }
    }

    private func tankaList(viewModel: MyTankaViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                likedTankaLink

                ForEach(viewModel.tankaList) { tanka in
                    TankaCard(tanka: tanka)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    private var likedTankaLink: some View {
        NavigationLink(value: MyTankaRoute.likedTanka) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Color.appSubText)
                Text("いいねした短歌")
                    .font(.appBody())
                    .foregroundStyle(Color.appText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.appCaption())
                    .foregroundStyle(Color.appSubText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
