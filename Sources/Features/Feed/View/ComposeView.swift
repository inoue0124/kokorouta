import SwiftUI

struct ComposeView: View {
    @Binding var path: NavigationPath
    @Binding var hasReachedDailyLimit: Bool
    @Environment(\.tankaRepository) private var repository
    @State private var viewModel: ComposeViewModel?
    @FocusState private var isTextEditorFocused: Bool

    var body: some View {
        Group {
            if let viewModel {
                phaseContent(viewModel: viewModel)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.phase.discriminator)
            } else {
                LoadingView()
            }
        }
        .background(Color.appBackground)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(!(viewModel?.phase.isInput ?? true))
        .task {
            if viewModel == nil {
                viewModel = ComposeViewModel(tankaRepository: repository)
            }
        }
        .onChange(of: viewModel?.generatedTanka != nil) {
            if viewModel?.generatedTanka != nil {
                hasReachedDailyLimit = true
            }
        }
        .onChange(of: viewModel?.isRateLimited) {
            if viewModel?.isRateLimited == true {
                hasReachedDailyLimit = true
            }
        }
    }

    private var navigationTitle: String {
        guard let viewModel else { return "お悩み入力" }
        switch viewModel.phase {
        case .input:
            return "お悩み入力"
        case .loading:
            return "短歌"
        case .result:
            return "短歌"
        case .error:
            return "短歌"
        }
    }

    // MARK: - Phase Content

    @ViewBuilder
    private func phaseContent(viewModel: ComposeViewModel) -> some View {
        switch viewModel.phase {
        case .input:
            inputContent(viewModel: viewModel)
                .transition(.opacity)
        case .loading:
            TankaComposingView(message: "短歌を詠んでいます...")
                .transition(.opacity)
        case let .result(tanka):
            resultContent(tanka: tanka)
                .transition(.opacity)
        case let .error(error):
            errorContent(error: error, viewModel: viewModel)
                .transition(.opacity)
        }
    }

    // MARK: - Input Phase

    private func inputContent(viewModel: ComposeViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("今日のお悩みを教えてください")
                    .font(.appTitle(size: 20))
                    .foregroundStyle(Color.appText)

                categorySection(viewModel: viewModel)

                textInputSection(viewModel: viewModel)

                Text("※ 個人情報は含めないでください。短歌は他の方にも公開されます。")
                    .font(.appCaption())
                    .foregroundStyle(Color.appSubText)

                submitButton(viewModel: viewModel)
            }
            .padding(24)
        }
        .onTapGesture {
            isTextEditorFocused = false
        }
    }

    private func categorySection(viewModel: ComposeViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カテゴリ")
                .font(.appCaption())
                .foregroundStyle(Color.appSubText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WorryCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            category: category,
                            isSelected: viewModel.selectedCategory == category
                        ) {
                            viewModel.selectCategory(category)
                        }
                    }
                }
            }
        }
    }

    private func textInputSection(viewModel: ComposeViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.worryText)
                    .font(.appBody())
                    .foregroundStyle(Color.appText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 150)
                    .padding(12)
                    .focused($isTextEditorFocused)
                    .onChange(of: viewModel.worryText) {
                        if viewModel.worryText.count > 300 {
                            viewModel.worryText = String(viewModel.worryText.prefix(300))
                        }
                    }

                if viewModel.worryText.isEmpty {
                    Text(viewModel.placeholderText)
                        .font(.appBody())
                        .foregroundStyle(Color.appSubText)
                        .padding(12)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.appDivider, lineWidth: 1)
            )

            HStack {
                if let message = viewModel.validationMessage {
                    Text(message)
                        .font(.appCaption())
                        .foregroundStyle(Color.appSubText)
                }

                Spacer()

                Text("\(viewModel.characterCount)/300")
                    .font(.appCaption())
                    .foregroundStyle(Color.appSubText)
            }
        }
    }

    private func submitButton(viewModel: ComposeViewModel) -> some View {
        Button {
            isTextEditorFocused = false
            Task {
                await viewModel.submitTanka()
            }
        } label: {
            Text("短歌を詠む")
                .font(.appBody())
                .foregroundStyle(viewModel.isValid ? Color.white : Color.appSubText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    viewModel.isValid ? Color.appText : Color.appDivider,
                    in: RoundedRectangle(cornerRadius: 8)
                )
        }
        .disabled(!viewModel.isValid)
    }

    // MARK: - Result Phase

    private func resultContent(tanka: Tanka) -> some View {
        VStack(spacing: 32) {
            Spacer()

            AnimatedVerticalText(text: tanka.tankaText)
                .padding(.horizontal, 20)

            Text("あなたのための短歌です")
                .font(.appCaption())
                .foregroundStyle(Color.appSubText)

            ShareButton(tanka: tanka)

            Spacer()

            backToFeedButton
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    // MARK: - Error Phase

    @ViewBuilder
    private func errorContent(error: AppError, viewModel: ComposeViewModel) -> some View {
        if case .rateLimited = error {
            rateLimitedContent(error: error)
        } else if case .validation = error {
            validationErrorContent(error: error)
        } else {
            ErrorView(error: error) {
                Task {
                    await viewModel.retry()
                }
            }
        }
    }

    private func validationErrorContent(error: AppError) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Text(error.errorDescription ?? "")
                .font(.appBody())
                .foregroundStyle(Color.appText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                viewModel?.resetToInput()
            } label: {
                Text("戻って修正する")
                    .font(.appBody())
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appText, in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 24)

            Spacer()
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
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    // MARK: - Shared Components

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
    }
}
