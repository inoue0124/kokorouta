import SwiftUI

struct LikeButton: View {
    let isLiked: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 14))
                    .foregroundStyle(isLiked ? Color.appText : Color.appSubText)

                if count >= 1 {
                    Text("\(count)")
                        .font(.appCaption())
                        .foregroundStyle(Color.appSubText)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("いいね")
        .accessibilityValue(isLiked ? "いいね済み \(count)件" : "\(count)件")
        .accessibilityHint("タップしていいねを切り替える")
    }
}

#Preview {
    VStack(spacing: 16) {
        LikeButton(isLiked: false, count: 0) {}
        LikeButton(isLiked: true, count: 12) {}
    }
}
