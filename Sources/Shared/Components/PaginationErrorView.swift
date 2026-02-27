import SwiftUI

struct PaginationErrorView: View {
    let error: AppError
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(error.errorDescription ?? "エラーが発生しました")
                .font(.appCaption())
                .foregroundStyle(Color.appSubText)
                .multilineTextAlignment(.center)

            Button(action: onRetry) {
                Text("もう一度試す")
                    .font(.appCaption())
                    .foregroundStyle(Color.appSubText)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appDivider, lineWidth: 1)
                    )
            }
        }
        .padding()
    }
}

#Preview {
    PaginationErrorView(error: .network(.noConnection)) {}
}
