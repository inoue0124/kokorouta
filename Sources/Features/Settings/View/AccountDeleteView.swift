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
            if viewModel.isDeleted {
                deletedContent
            } else {
                deleteFormContent(viewModel: viewModel)
            }
        }
    }

    private var deletedContent: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(Color.appSubText)
            Text("アカウントを削除しました")
                .font(.appBody())
                .foregroundStyle(Color.appText)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }

    private func deleteFormContent(viewModel: AccountDeleteViewModel) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            warningSection
            confirmationSection(viewModel: viewModel)
            if let error = viewModel.error {
                errorSection(error: error)
            }
            deleteButton(viewModel: viewModel)
            Spacer()
        }
        .padding(24)
    }

    private var warningSection: some View {
        Text("アカウントを削除すると、すべてのデータが完全に消去されます。この操作は取り消せません。")
            .font(.appBody())
            .foregroundStyle(Color.appText)
            .lineSpacing(6)
    }

    private func confirmationSection(viewModel: AccountDeleteViewModel) -> some View {
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
        }
    }

    private func errorSection(error: AppError) -> some View {
        Text(error.errorDescription ?? "エラーが発生しました")
            .font(.appCaption())
            .foregroundStyle(.red)
    }

    private func deleteButton(viewModel: AccountDeleteViewModel) -> some View {
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
    }
}
