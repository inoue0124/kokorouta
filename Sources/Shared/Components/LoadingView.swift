import SwiftUI

struct LoadingView: View {
    var message: String = "読み込み中..."

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color.appSubText)
            Text(message)
                .font(.appCaption())
                .foregroundStyle(Color.appSubText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

#Preview {
    LoadingView()
}
