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
        .accessibilityLabel(likeAccessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var likeAccessibilityLabel: String {
        let stateText = isLiked ? "いいね済み" : "いいね"
        if count >= 1 {
            return "\(stateText) \(count)件"
        }
        return stateText
    }
}

#Preview {
    VStack(spacing: 16) {
        LikeButton(isLiked: false, count: 0) {}
        LikeButton(isLiked: true, count: 12) {}
    }
}
