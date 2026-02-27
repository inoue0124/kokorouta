import SwiftUI

struct EmptyStateView: View {
    let message: String
    var actionLabel: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            Text(message)
                .font(.appBody())
                .foregroundStyle(Color.appSubText)
                .multilineTextAlignment(.center)

            if let actionLabel, let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.appBody())
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.appText, in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

#Preview {
    EmptyStateView(
        message: "まだ短歌がありません",
        actionLabel: "最初の短歌を詠む"
    ) {}
}
