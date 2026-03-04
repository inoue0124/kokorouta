import SwiftUI

struct EULAAgreementView: View {
    @State private var viewModel = EULAAgreementViewModel()

    var onAgree: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("利用規約")
                .font(.appTitle(size: 24))
                .foregroundStyle(Color.appText)
                .padding(.top, 40)
                .padding(.bottom, 16)

            ScrollView {
                Text(EULAContent.fullText)
                    .font(.appBody(size: 14))
                    .foregroundStyle(Color.appText)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
            }

            VStack(spacing: 12) {
                Button {
                    viewModel.agree()
                    onAgree()
                } label: {
                    Text("同意して始める")
                        .font(.appBody())
                        .foregroundStyle(Color.appBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.appText)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text("同意しない場合はアプリをご利用いただけません")
                    .font(.appCaption())
                    .foregroundStyle(Color.appSubText)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}

#Preview {
    EULAAgreementView(onAgree: {})
}
