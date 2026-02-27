import SwiftUI

struct ComposeView: View {
    @Binding var path: NavigationPath
    @State private var viewModel = ComposeViewModel()
    @FocusState private var isTextEditorFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("今日のお悩みを教えてください")
                    .font(.appTitle(size: 20))
                    .foregroundStyle(Color.appText)

                categorySection

                textInputSection

                Text("※ 個人情報は含めないでください。短歌は他の方にも公開されます。")
                    .font(.appCaption())
                    .foregroundStyle(Color.appSubText)

                submitButton
            }
            .padding(24)
        }
        .background(Color.appBackground)
        .navigationTitle("お悩み入力")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            isTextEditorFocused = false
        }
    }

    private var categorySection: some View {
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

    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.worryText)
                    .font(.appBody())
                    .foregroundStyle(Color.appText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 150)
                    .padding(12)
                    .focused($isTextEditorFocused)
                    .onChange(of: viewModel.worryText) {
                        if viewModel.worryText.count > 200 {
                            viewModel.worryText = String(viewModel.worryText.prefix(200))
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

                Text("\(viewModel.characterCount)/200")
                    .font(.appCaption())
                    .foregroundStyle(Color.appSubText)
            }
        }
    }

    private var submitButton: some View {
        Button {
            guard let category = viewModel.selectedCategory else { return }
            path.append(
                FeedRoute.tankaResult(
                    category: category,
                    worryText: viewModel.worryText
                )
            )
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
}
