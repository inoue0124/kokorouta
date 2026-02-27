import SwiftUI

struct BlockListView: View {
    @Environment(\.tankaRepository) private var repository
    @State private var viewModel: BlockListViewModel?

    var body: some View {
        content
            .background(Color.appBackground)
            .navigationTitle("ブロックリスト")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if viewModel == nil {
                    viewModel = BlockListViewModel(tankaRepository: repository)
                }
                await viewModel?.loadBlockedUsers()
            }
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel {
            if viewModel.isLoading, viewModel.blockedUsers.isEmpty {
                LoadingView()
            } else if let error = viewModel.error, viewModel.blockedUsers.isEmpty {
                ErrorView(error: error) {
                    Task { await viewModel.loadBlockedUsers() }
                }
            } else if viewModel.blockedUsers.isEmpty {
                EmptyStateView(message: "ブロック中のユーザーはいません")
            } else {
                blockedUserList(viewModel: viewModel)
            }
        } else {
            LoadingView()
        }
    }

    private func blockedUserList(viewModel: BlockListViewModel) -> some View {
        List {
            ForEach(viewModel.blockedUsers) { user in
                HStack {
                    Text("ブロック中のユーザー")
                        .font(.appBody())
                        .foregroundStyle(Color.appText)

                    Spacer()

                    Button("解除") {
                        Task { await viewModel.unblock(userID: user.blockedID) }
                    }
                    .font(.appCaption())
                    .foregroundStyle(Color.appSubText)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }
}
