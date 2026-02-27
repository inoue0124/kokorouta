import SwiftUI

struct AccountDeleteView: View {
    @Environment(\.tankaRepository) private var repository
    @State private var viewModel: AccountDeleteViewModel?

    var body: some View {
        content
            .background(Color.appBackground)
            .navigationTitle("アカウント削除")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if viewModel == nil {
                    viewModel = AccountDeleteViewModel(tankaRepository: repository)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel {
            VStack(alignment: .leading, spacing: 24) {
                Text("アカウントを削除すると、すべてのデータが完全に消去されます。この操作は取り消せません。")
                    .font(.appBody())
                    .foregroundStyle(Color.appText)
                    .lineSpacing(6)

                VStack(alignment: .leading, spacing: 8) {
                    Text("確認のため「削除」と入力してください")
                        .font(.appCaption())
                        .foregroundStyle(Color.appSubText)

                    TextField("削除", text: Binding(
                        get: { viewModel.confirmationText },
                        set: { viewModel.confirmationText = $0 }
                    ))
                    .font(.appBody())
                    .padding(12)
                    .background(Color.appCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appDivider, lineWidth: 1)
                    )
                    .accessibilityLabel("削除確認入力欄")
                    .accessibilityHint("確認のため「削除」と入力してください")
                }

                if let error = viewModel.error {
                    Text(error.errorDescription ?? "エラーが発生しました")
                        .font(.appCaption())
                        .foregroundStyle(.red)
                }

                Button {
                    Task { await viewModel.deleteAccount() }
                } label: {
                    if viewModel.isDeleting {
                        ProgressView()
                            .tint(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    } else {
                        Text("アカウントを削除する")
                            .font(.appBody())
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .background(
                    viewModel.canDelete ? .red : Color.appDivider,
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .disabled(!viewModel.canDelete || viewModel.isDeleting)
                .accessibilityLabel(viewModel.isDeleting ? "削除中" : "アカウントを削除する")
                .accessibilityHint(viewModel.canDelete ? "タップするとアカウントが完全に削除されます" : "確認欄に「削除」と入力すると有効になります")

                Spacer()
            }
            .padding(24)
        }
    }
}
