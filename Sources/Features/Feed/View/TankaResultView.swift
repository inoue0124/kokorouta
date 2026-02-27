import SwiftUI

struct TankaResultView: View {
    let category: WorryCategory
    let worryText: String
    @Binding var path: NavigationPath

    @Environment(\.tankaRepository) private var repository
    @State private var viewModel: TankaResultViewModel?

    var body: some View {
        content
            .background(Color.appBackground)
            .navigationTitle("短歌")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .task {
                if viewModel == nil {
                    viewModel = TankaResultViewModel(tankaRepository: repository)
                }
                await viewModel?.generateTanka(category: category, worryText: worryText)
            }
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel {
            if viewModel.isLoading {
                LoadingView(message: "短歌を詠んでいます...")
            } else if let error = viewModel.error {
                ErrorView(error: error) {
                    Task {
                        await viewModel.generateTanka(
                            category: category,
                            worryText: worryText
                        )
                    }
                }
            } else if let tanka = viewModel.generatedTanka {
                resultContent(tanka: tanka)
            }
        } else {
            LoadingView(message: "短歌を詠んでいます...")
        }
    }

    private func resultContent(tanka: Tanka) -> some View {
        VStack(spacing: 32) {
            Spacer()

            TankaCard(tanka: tanka)
                .padding(.horizontal, 20)

            Text("カードをタップすると短歌が読めます")
                .font(.appCaption())
                .foregroundStyle(Color.appSubText)

            ShareButton(tanka: tanka)

            Spacer()

            Button {
                path.removeLast(path.count)
            } label: {
                Text("フィードに戻る")
                    .font(.appBody())
                    .foregroundStyle(Color.appText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appDivider, lineWidth: 1)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}
