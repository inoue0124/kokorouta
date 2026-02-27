import SwiftUI

struct TankaCard: View {
    let tanka: Tanka
    var onLike: (() -> Void)?

    @State private var isFlipped = false

    var body: some View {
        ZStack {
            // 裏面: 縦書き短歌
            backFace
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )

            // 表面: 悩みテキスト
            frontFace
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.4)) {
                isFlipped.toggle()
            }
        }
    }

    // MARK: - Front Face

    private var frontFace: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(tanka.category.displayName)
                .font(.appCaption())
                .foregroundStyle(Color.appSubText)

            Text(tanka.worryText)
                .font(.appBody())
                .foregroundStyle(Color.appText)
                .lineSpacing(6)

            Spacer()

            HStack {
                Text(tanka.createdAt.shortDisplayString)
                    .font(.appCaption())
                    .foregroundStyle(Color.appSubText)

                Spacer()

                if let onLike {
                    LikeButton(
                        isLiked: tanka.isLikedByMe,
                        count: tanka.likeCount,
                        action: onLike
                    )
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Back Face

    private var backFace: some View {
        VStack {
            Spacer()
            VerticalText(text: tanka.tankaText)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(24)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

#Preview {
    TankaCard(
        tanka: Tanka(
            id: "1",
            authorID: "author1",
            category: .work,
            worryText: "仕事がうまくいかなくて、毎日が辛いです。自分に自信が持てません。",
            tankaText: "朝霧の\n晴れゆく空に\n光さし\n歩む一歩が\n道をつくらむ",
            likeCount: 5,
            isLikedByMe: false,
            createdAt: Date()
        )
    ) onLike: {
        // preview
    }
    .padding(20)
    .background(Color.appBackground)
}
