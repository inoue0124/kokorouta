import SwiftUI

struct TankaResultView: View {
    let category: WorryCategory
    let worryText: String
    @Binding var path: NavigationPath
    @Binding var hasReachedDailyLimit: Bool

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
            .onChange(of: viewModel?.generatedTanka != nil) {
                if viewModel?.generatedTanka != nil {
                    hasReachedDailyLimit = true
                }
            }
            .onChange(of: viewModel?.error != nil) {
                if case .rateLimited = viewModel?.error {
                    hasReachedDailyLimit = true
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel {
            if viewModel.isLoading {
                LoadingView(message: "短歌を詠んでいます...")
            } else if let error = viewModel.error {
                if case .rateLimited = error {
                    rateLimitedContent(error: error)
                } else {
                    ErrorView(error: error) {
                        Task {
                            await viewModel.generateTanka(
                                category: category,
                                worryText: worryText
                            )
                        }
                    }
                }
            } else if let tanka = viewModel.generatedTanka {
                resultContent(tanka: tanka)
            }
        } else {
            LoadingView(message: "短歌を詠んでいます...")
        }
    }

    private func rateLimitedContent(error: AppError) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Text(error.errorDescription ?? "")
                .font(.appBody())
                .foregroundStyle(Color.appText)
                .multilineTextAlignment(.center)

            Text("明日また詠めます")
                .font(.appCaption())
                .foregroundStyle(Color.appSubText)

            Spacer()

            backToFeedButton
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

            backToFeedButton
        }
    }

    private var backToFeedButton: some View {
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
