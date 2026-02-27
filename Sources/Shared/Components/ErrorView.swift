import SwiftUI

struct ErrorView: View {
    let error: AppError
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text(error.errorDescription ?? "エラーが発生しました")
                .font(.appBody())
                .foregroundStyle(Color.appText)
                .multilineTextAlignment(.center)

            Button(action: onRetry) {
                Text("もう一度試す")
                    .font(.appBody(size: 14))
                    .foregroundStyle(Color.appSubText)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appDivider, lineWidth: 1)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

#Preview {
    ErrorView(error: .network(.noConnection)) {}
}
