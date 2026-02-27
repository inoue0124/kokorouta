import SwiftUI

struct EmptyStateView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.appBody())
            .foregroundStyle(Color.appSubText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
    }
}

#Preview {
    EmptyStateView(message: "まだ短歌がありません")
}
